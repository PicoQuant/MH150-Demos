/************************************************************************

  Demo access to MultiHarp 150/160 hardware via MHLIB v.3.1
  The program performs a TTTR measurement based on hard-coded settings.
  Event data is filtered by the device's main event filter in the FPGA.
  Actually there are two such filters: Main Filter and Row Filter.
  The Main Filter operates on all input channels of the device and it is
  the recommended starting point for work with event filtering.
  The Row Filter operates only on one vertical row of input channels.
  It is of interest only if you need to work with very high count rates. 
  Please read the manual for details. 
  The purpose of this demo is to show the software calls for setting the
  Main Filter parameters and activating the Main Filter.
  The resulting event data is instantly processed.
  Processing consists here only of dissecting the binary event record
  data and writing it to a text file. This is only for demo purposes.
  In a real application this makes no sense as it limits throughput and
  creates very large files. In practice you would more sensibly perform 
  some meaningful processing such as counting coincidences on the fly.

  Michael Wahl, PicoQuant GmbH, March 2022

  Note: This is a console application

  Note: At the API level the input channel numbers are indexed 0..N-1
  where N is the number of input channels the device has.
  Upon processing we map this back to 1..N corresponding to the front 
  panel labelling.

  
  Tested with the following compilers:

  - MS Visual Studio 2013 and 2019
  - Mono 6.12.0 (Windows)
  - Mono 6.8.0 (Linux)

************************************************************************/

using System;  // for Console
using System.Text;  // for StringBuilder 
using System.IO;  // for File
using System.Runtime.InteropServices;  // for DllImport

namespace tttrmode
{
  class tttrmode
  {
    static ulong oflcorrection = 0;
    static double Resolution = 0; // in ps
    static double Syncperiod = 0; // in s


    static void Main(string[] args)
    {
      int[] dev = new int[Constants.MAXDEVNUM];
      int found = 0;
      int retcode;
      int ctcstatus = 0;

      StringBuilder LibVer = new StringBuilder(8);
      StringBuilder Serial = new StringBuilder(8);
      StringBuilder Errstr = new StringBuilder(40);
      StringBuilder Model = new StringBuilder(32);
      StringBuilder Partno = new StringBuilder(16);
      StringBuilder Version = new StringBuilder(16);
      StringBuilder Wtext = new StringBuilder(16384);

      int NumChannels = 0;

      int Mode = Constants.MODE_T2;  // you can change this, adjust other settings accordingly!
      int Binning = 4;  // you can change this, meaningful only in T3 mode, observe limits 
      int Offset = 0;  // you can change this, meaningful only in T3 mode, observe limits 
      int Tacq = 10000;  // Measurement time in millisec, you can change this, observe limits 
      int SyncDivider = 1;  // you can change this, usually 1 in T2 mode 

      int SyncTiggerEdge = 0; //you can change this
      int SyncTriggerLevel = -50; //you can change this
      int InputTriggerEdge = 0; //you can change this
      int InputTriggerLevel = -50; //you can change this

      int Syncrate = 0;
      int Countrate = 0;
      int flags = 0;
      int warnings = 0;
      long Progress = 0;
      int nRecords = 0;
      int stopretry = 0;

      uint[] buffer = new uint[Constants.TTREADMAX];

      int i;


      FileStream fs = null;
      StreamWriter sw = null;



      /*
      The following variables are for programming the Main Event Filter.
      For the sake of consistency at API level both filters are organized
      by rows of channels. MAXROWS is the largest number of input rows
      a MultiHarp device can have.
      Please read the manual on what the filter parameters are about.
      Here we implement a simple "Singles Filter" which is the most obvious 
      and most useful type of event filter in typical quantum optics applications.
      The idea is that photon events that are "single" in the sense that there is no 
      other event in temporal proximity (within timerange) will be filtered out.
      This reduces the bus load and the file size if you write the records to a file.
      Any further (application specific) coincidence processing will eventually be 
      done in software, either on the fly or subsequently on the stored data.
      The Row Filters are off by default and we will not touch them here.
      */
      const int MAXROWS = 8;             // largest possible number of input rows
      int inputrows;                     // actual number of rows, we determine this later 
      int mainfilter_timerange = 1000;   // in picoseconds
      int mainfilter_matchcnt = 1;       // must have at least one other event in proximity
      int mainfilter_inverse = 0;        // normal filtering mode, see manual
      int mainfilter_enable = 1;         // activate the filter
      int[] mainfilter_usechans          // bitmasks for which channels are to be used
           = {0xF,0,0,0,0,0,0,0};        // we use only the first four channels
      int[] mainfilter_passchans         // bitmasks for which channels to pass unfiltered
          = {0,0,0,0,0,0,0,0};           // we do not pass any channels unfiltered

      //the following are count rate buffers for the filter test further down
      int ftestsyncrate = 0;
      int[] ftestchanrates = new int[Constants.MAXINPCHAN];
      int ftestsumrate;





      Console.WriteLine("MultiHarp MHLib Demo Application                       PicoQuant GmbH, 2022");
      Console.WriteLine("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

      try
      {
          retcode = mhlib.MH_GetLibraryVersion(LibVer);
      }
      catch (Exception e)
      {
          Console.WriteLine("Error loading MHLib as \"" + mhlib.MHLib + "\" => " + e.Message);
          Console.WriteLine("press RETURN to exit");
          Console.ReadLine();
          return;
      }

      if (retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_GetLibraryVersion error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }
      Console.WriteLine("MHLib Version is " + LibVer);

      if (LibVer.ToString() != Constants.LIB_VERSION)
      {
        Console.WriteLine("This program requires MHLib v." + Constants.LIB_VERSION);
        goto ex;
      }

      try
      {
        fs = new FileStream("tttrmode.out", FileMode.Create,  FileAccess.Write);
        sw = new StreamWriter(fs);
      }
      catch (Exception)
      {
        Console.WriteLine("Error creating file");
        goto ex;
      }

      Console.WriteLine("Searching for MultiHarp devices...");
      Console.WriteLine("Devidx     Status");


      for (i = 0; i < Constants.MAXDEVNUM; i++)
      {
        retcode = mhlib.MH_OpenDevice(i, Serial);
        if (retcode == 0) //Grab any device we can open
        {
          Console.WriteLine("  {0}        S/N {1}", i, Serial);
          dev[found] = i; //keep index to devices we want to use
          found++;
        }
        else
        {

          if (retcode == Errorcodes.MH_ERROR_DEVICE_OPEN_FAIL)
            Console.WriteLine("  {0}        no device", i);
          else
          {
            mhlib.MH_GetErrorString(Errstr, retcode);
            Console.WriteLine("  {0}        S/N {1}", i, Errstr);
          }
        }
      }

      //In this demo we will use the first device we find, i.e. dev[0].
      //You can also use multiple devices in parallel.
      //You can also check for specific serial numbers, so that you always know 
      //which physical device you are talking to.

      if (found < 1)
      {
        Console.WriteLine("No device available.");
        goto ex;
      }

      Console.WriteLine("Using device {0}", dev[0]);
      Console.WriteLine("Initializing the device...");

      retcode = mhlib.MH_Initialize(dev[0], Mode, 0);
      if (retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_Initialize error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }

      retcode = mhlib.MH_GetHardwareInfo(dev[0], Model, Partno, Version);  // this is only for information
      if (retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_GetHardwareInfo error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }
      else
        Console.WriteLine("Found Model {0} Part no {1} Version {2}", Model, Partno, Version);


      retcode = mhlib.MH_GetNumOfInputChannels(dev[0], ref NumChannels);
      if (retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_GetNumOfInputChannels error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }
      else
        Console.WriteLine("Device has {0} input channels.", NumChannels);

      Console.WriteLine("\n\nUsing the following settings:\n");

      Console.WriteLine("Mode              : " + Mode);
      Console.WriteLine("Binning           : " + Binning);
      Console.WriteLine("Offset            : " + Offset);
      Console.WriteLine("AcquisitionTime   : " + Tacq);
      Console.WriteLine("SyncDivider       : " + SyncDivider);
      Console.WriteLine("SyncTiggerEdge    : " + SyncTiggerEdge);
      Console.WriteLine("SyncTriggerLevel  : " + SyncTriggerLevel);
      Console.WriteLine("InputTriggerEdge  : " + InputTriggerEdge);
      Console.WriteLine("InputTriggerLevel : " + InputTriggerLevel);


      retcode = mhlib.MH_SetSyncDiv(dev[0], SyncDivider);
      if (retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_SetSyncDiv error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }

      retcode = mhlib.MH_SetSyncEdgeTrg(dev[0], SyncTriggerLevel, SyncTiggerEdge);
      if (retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_SetSyncEdgeTrg error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }

      retcode = mhlib.MH_SetSyncChannelOffset(dev[0], 0);    //in ps, emulate a cable delay
      if (retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_SetSyncChannelOffset error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }

      for (i = 0; i < NumChannels; i++)  // we use the same input settings for all channels
      {
        retcode = mhlib.MH_SetInputEdgeTrg(dev[0], i, InputTriggerLevel, InputTriggerEdge);
        if (retcode < 0)
        {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_SetInputEdgeTrg error {0} ({1}). Aborted.", retcode, Errstr);
          goto ex;
        }

        retcode = mhlib.MH_SetInputChannelOffset(dev[0], i, 0);  //in ps, emulate a cable delay
        if (retcode < 0)
        {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_SetInputChannelOffset error {0} ({1}). Aborted.", retcode, Errstr);
          goto ex;
        }
        retcode = mhlib.MH_SetInputChannelEnable(dev[0], i, 1);
        if (retcode < 0)
        {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_SetInputChannelEnable error {0} ({1}). Aborted.", retcode, Errstr);
          goto ex;
        }
      }

      if (Mode != Constants.MODE_T2)
      {
        retcode = mhlib.MH_SetBinning(dev[0], Binning);
        if (retcode < 0)
        {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_SetBinning error {0} ({1}). Aborted.", retcode, Errstr);
          goto ex;
        }

        retcode = mhlib.MH_SetOffset(dev[0], Offset);
        if (retcode < 0)
        {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_SetOffset error {0} ({1}). Aborted.", retcode, Errstr);
          goto ex;
        }
      }

      retcode = mhlib.MH_GetResolution(dev[0], ref Resolution);
      if (retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_GetResolution error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }

      Console.WriteLine("Resolution is {0} ps", Resolution);


      #region Here this demo differs from classic 'tttrmode - demo'

      // here we program the Main Filter 
      inputrows = NumChannels / 8; // a MultiHarp has 8 channels per row
      if (NumChannels == 4)         // except it is a 4-channel model  
          inputrows = 1;

      for (i = 0; i < inputrows; i++)
      {
          retcode = mhlib.MH_SetMainEventFilterChannels(dev[0], i, mainfilter_usechans[i], mainfilter_passchans[i]);
          if (retcode < 0)
          {
              mhlib.MH_GetErrorString(Errstr, retcode);
              Console.WriteLine("MH_SetMainEventFilterChannels error {0} ({1}). Aborted.\n", retcode, Errstr);
              goto ex;
          }
      }

      retcode = mhlib.MH_SetMainEventFilterParams(dev[0], mainfilter_timerange, mainfilter_matchcnt, mainfilter_inverse);
      if (retcode < 0)
      {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_SetMainEventFilterParams error {0} ({1}). Aborted.\n", retcode, Errstr);
          goto ex;
      }

      retcode = mhlib.MH_EnableMainEventFilter(dev[0], mainfilter_enable);
      if (retcode < 0)
      {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("nMH_EnableMainEventFilter error {0} ({1}). Aborted.\n", retcode, Errstr);
          goto ex;
      }
      // Filter programming ends here


      Console.WriteLine("Measuring input rates...\n");

      #endregion



      // After Init allow 150 ms for valid  count rate readings
      // Subsequently you get new values after every 100ms
      System.Threading.Thread.Sleep(150); 

      retcode = mhlib.MH_GetSyncRate(dev[0], ref Syncrate);
      if (retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_GetSyncRate error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }
      Console.WriteLine("Syncrate = {0}/s", Syncrate);

      for (i = 0; i < NumChannels; i++)  // for all channels
      {
        retcode = mhlib.MH_GetCountRate(dev[0], i, ref Countrate);
        if (retcode < 0)
        {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_GetCountRate error {0} ({1}). Aborted.", retcode, Errstr);
          goto ex;
        }
        Console.WriteLine("Countrate[{0}] = {1}/s", i, Countrate);
      }

      Console.WriteLine();

      // After getting the count rates you can check for warnings
      retcode = mhlib.MH_GetWarnings(dev[0], ref warnings);
      if (retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_GetWarnings error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }
      if (warnings != 0)
      {
        mhlib.MH_GetWarningsText(dev[0], Wtext, warnings);
        Console.WriteLine("{0}", Wtext);
      }

      #region Here this demo differs from classic 'tttrdemo'


      /*
      Now we perform a filter test. This is not strictly necessary but helpful
      when the overall count rate is over the USB troughput limit and you wish to
      use the filter to alleviate this.
      The filter test consists of just a simple retrievel of input and output rates 
      of the filter(s), so that you can assess its effect in terms of rate reduction.
      You can do this a few times in a loop, so that you can also see if there are 
      significant fluctuations. However, note that for each round you will need to 
      wait for at least 100ms to get new results.
      The filter test must be performed while measurement is running. In order
      to avoid FiFo buffer overruns we can use MH_SetFilterTestMode to disable the
      transfer of meaurement data into the FiFo.
      */

      retcode = mhlib.MH_SetFilterTestMode(dev[0], 1); //disable FiFo input
      if (retcode < 0)
      {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_SetFilterTestMode error {0} ({1}). Aborted.\n", retcode, Errstr);
          goto ex;
      }

      retcode = mhlib.MH_StartMeas(dev[0], Constants.ACQTMAX); //longest possible time, we will stop manually
      if (retcode < 0)
      {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_StartMeas error{0} ({1}). Aborted.\n", retcode, Errstr);
          goto ex;
      }

      System.Threading.Thread.Sleep(150); //allow the hardware at least 100ms time for rate counting 

      /*
      To start with, we retrieve the front end count rates. This is somewhat redundant 
      here as we already retrieved them above. However, for demonstration purposes, 
      this time we use a more efficient method that fetches all rates in one go.
      */
      retcode = mhlib.MH_GetAllCountRates(dev[0], ref ftestsyncrate, ftestchanrates);
      if (retcode < 0)
      {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_GetRowFilteredRates error {0} ({1}). Aborted.\n", retcode, Errstr);
          goto ex;
      }
      //We only care about the overall rates, so we sum them up here.
      ftestsumrate = 0;
      for (i = 0; i < NumChannels; i++)
          ftestsumrate += ftestchanrates[i];
      if (Mode == Constants.MODE_T2) //in this case also add the sync rate
          ftestsumrate += ftestsyncrate;
      Console.WriteLine("Front end input rate={0}/s", ftestsumrate);

      /*
      Although we are not using the Row Filter here, it is useful to retrieve its outout 
      rates as it is the input to the Main Filter. This is not necessarily the same as
      the front end count rates as there may already have been losses due to front end 
      troughput limits. We do the same summation as above.
      */
      retcode = mhlib.MH_GetRowFilteredRates(dev[0], ref ftestsyncrate, ftestchanrates);
      if (retcode < 0)
      {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_GetRowFilteredRates error {0} ({1}). Aborted.\n", retcode, Errstr);
          goto ex;
      }
      ftestsumrate = 0;
      for (i = 0; i < NumChannels; i++)
          ftestsumrate += ftestchanrates[i];
      if (Mode == Constants.MODE_T2) //in this case also add the sync rate
          ftestsumrate += ftestsyncrate;
      Console.WriteLine("Main Filter input rate={0}/s", ftestsumrate);

      //Now we do the same rate retrieval and summation for the Main Filter output.
      retcode = mhlib.MH_GetMainFilteredRates(dev[0], ref ftestsyncrate, ftestchanrates);
      if (retcode < 0)
      {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_GetRowFilteredRates error {0} ({1}). Aborted.\n", retcode, Errstr);
          goto ex;
      }
      ftestsumrate = 0;
      for (i = 0; i < NumChannels; i++)
          ftestsumrate += ftestchanrates[i];
      if (Mode == Constants.MODE_T2) //in this case also add the sync rate
          ftestsumrate += ftestsyncrate;
      Console.WriteLine("Main Filter output rate={0}/s", ftestsumrate);


      retcode = mhlib.MH_StopMeas(dev[0]); //test finished, stop measurement
      if (retcode < 0)
      {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_StopMeas error {0} ({1}). Aborted.\n", retcode, Errstr);
          goto ex;
      }

      //Testmode must be switched off again to allow a real measurement
      retcode = mhlib.MH_SetFilterTestMode(dev[0], 0); //re-enable FiFo input
      if (retcode < 0)
      {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_SetFilterTestMode error {0} ({1}). Aborted.\n", retcode, Errstr);
          goto ex;
      }

      // here we begin the real measurement

      if (Mode == Constants.MODE_T2)
          sw.Write("ev chn       time/ps\n\n"); //column heading for T2 mode
      else
          sw.Write("ev chn  ttag/s   dtime/ps\n\n");  //column heading for T3 mode

      Console.WriteLine("press RETURN to start");
      Console.ReadLine();

      retcode = mhlib.MH_StartMeas(dev[0], Tacq);
      if (retcode < 0)
      {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_StartMeas error {0} ({1}). Aborted.\n", retcode, Errstr);
          goto ex;
      }

      if (Mode == Constants.MODE_T3)
      {
          //We need the sync period in order to calculate the true times of photon records.
          //This only makes sense in T3 mode and it assumes a stable period like from a laser.
          //Note: Two sync periods must have elapsed after MH_StartMeas to get proper results.
          //You can also use the inverse of what you read via GetSyncRate but it depends on 
          //the actual sync rate if this is accurate enough.
          //It is OK to use the sync input for a photon detector, e.g. if you want to perform
          //something like an antibunching measurement. In that case the sync rate obviously is
          //not periodic. This means that a) you should set the sync divider to 1 (none) and
          //b) that you cannot meaningfully measure the sync period here, which probaly won't
          //matter as you only care for the time difference (dtime) of the events.
          retcode = mhlib.MH_GetSyncPeriod(dev[0], ref Syncperiod);
          if (retcode < 0)
          {
              mhlib.MH_GetErrorString(Errstr, retcode);
              Console.WriteLine("MH_GetSyncPeriod error {0} ({1}). Aborted.\n", retcode, Errstr);
              goto ex;
          }
          Console.WriteLine("Sync period is {0} ns\n", Syncperiod * 1e9);
      }

      Console.WriteLine("Starting data collection...\n");

      #endregion


      Progress = 0;
      Console.Write("Progress: {0,12}", Progress);

      oflcorrection = 0;

      /*
       * In this demo we have already started the Meas earlier...
       * So this step from 'classic' tttrmode - demo is commented-out:
      retcode = mhlib.MH_StartMeas(dev[0], Tacq);
      if (retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine();
        Console.WriteLine("MH_StartMeas error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }
      /**/

      while (true)
      {
        retcode = mhlib.MH_GetFlags(dev[0], ref flags);
        if (retcode < 0)
        {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine();
          Console.WriteLine("MH_GetFlags error {0} ({1}). Aborted.", retcode, Errstr);
          goto ex;
        }

        if ((flags & Constants.FLAG_FIFOFULL) != 0)
        {
          Console.WriteLine();
          Console.WriteLine("FiFo Overrun!");
          goto stoptttr;
        }

        retcode = mhlib.MH_ReadFiFo(dev[0], buffer, ref nRecords);  // may return less!
        if (retcode < 0)
        {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine();
          Console.WriteLine("MH_GetFlags error {0} ({1}). Aborted.", retcode, Errstr);
          goto stoptttr;
        }

        if (nRecords > 0)
        {

            // Here we process the data. Note that the time this consumes prevents us
            // from getting around the loop quickly for the next Fifo read.
            // In a serious performance critical scenario you would write the data to
            // a software queue and do the processing in another thread reading from 
            // that queue.

            if (Mode == Constants.MODE_T2)
                for (i = 0; i < nRecords; i++)
                    ProcessT2(sw, buffer[i]);
            else
                for (i = 0; i < nRecords; i++)
                    ProcessT3(sw, buffer[i]);


          Progress += nRecords;
          Console.Write("\b\b\b\b\b\b\b\b\b\b\b\b{0,12}", Progress);
        }
        else
        {
          retcode = mhlib.MH_CTCStatus(dev[0], ref ctcstatus);
          if (retcode < 0)
          {
            mhlib.MH_GetErrorString(Errstr, retcode);
            Console.WriteLine();
            Console.WriteLine("MH_CTCStatus error {0} ({1}). Aborted.", retcode, Errstr);
            goto ex;
          }
          if (ctcstatus > 0)
          {
              stopretry++; //do a few more rounds as there might be some more in the FiFo
              if (stopretry > 5)
              {
                  Console.WriteLine("\nDone\n");
                  goto stoptttr;
              }

          }
        }

        // within this loop you can also read the count rates if needed.
      }

      stoptttr:
      Console.WriteLine();

      retcode = mhlib.MH_StopMeas(dev[0]);
      if (retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_StopMeas error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }

      ex:

      for (i = 0; i < Constants.MAXDEVNUM; i++)  // no harm to close all
      {
        mhlib.MH_CloseDevice(i);
      }

      try
      {
          sw.Flush();
          sw.Close();
          sw.Dispose();
          sw = null;
      }
      catch(Exception e)
      {
          Console.WriteLine("Error closing the file: " + e);
      }

      Console.WriteLine("press RETURN to exit");
      Console.ReadLine();
    }






    //Got PhotonT2
    //  TimeTag: Overflow-corrected arrival time in units of the device's base resolution 
    //  Channel: Channel the photon arrived (0 = Sync channel, 1..N = regular timing channel)
    static void GotPhotonT2(StreamWriter fpout, ulong TimeTag, int Channel)
    {
      fpout.Write("CH {0,2:D2} {1,14:F1}\n", Channel, TimeTag * Resolution); 
    }


    //Got MarkerT2
    //  TimeTag: Overflow-corrected arrival time in units of the device's base resolution 
    //  Markers: Bitfield of arrived markers, different markers can arrive at same time (same record)
    static void GotMarkerT2(StreamWriter fpout, ulong TimeTag, int Markers)
    {
      fpout.Write("MK {0,2:D2} {1,14:F1}\n", Markers, TimeTag * Resolution);
    }


    //Got PhotonT3
    //  TimeTag: Overflow-corrected arrival time in units of the sync period 
    //  DTime: Arrival time of photon after last Sync event in units of the chosen resolution (set by binning)
    //  Channel: 1..N where N is the numer of channels the device has
    static void GotPhotonT3(StreamWriter fpout, ulong TimeTag, int Channel, int DTime)
    {
      //Syncperiod is in seconds
      fpout.Write("CH {0,2:D2} {1,10:F8} {2,8:F1}\n", Channel, TimeTag * Syncperiod, DTime * Resolution);
    }


    //Got MarkerT3
    //  TimeTag: Overflow-corrected arrival time in units of the sync period 
    //  Markers: Bitfield of arrived Markers, different markers can arrive at same time (same record)
    static void GotMarkerT3(StreamWriter fpout, ulong TimeTag, int Markers)
    {
      //Syncperiod is in seconds
      fpout.Write("MK {0,2:D2} {1,10:F8}\n", Markers, TimeTag * Syncperiod);
    }


    // HydraHarpV2 or TimeHarp260 or MultiHarp T2 record data
    static void ProcessT2(StreamWriter fpout, uint TTTRRecord)
    {
      int ch;
      ulong truetime;
      const int T2WRAPAROUND_V2 = 33554432;

      // shift and mask out the elements of TTTRRecord
      uint timetag = (TTTRRecord >> 00) & (0xFFFFFFFF >> (32 - 25)); //the lowest 25 bits
      uint channel = (TTTRRecord >> 25) & (0xFFFFFFFF >> (32 - 06)); //the next    6 bits
      uint special = (TTTRRecord >> 31) & (0xFFFFFFFF >> (32 - 01)); //the next    1 bit

  
      if(special==1)
      {
        if(channel==0x3F) //an overflow record
        {
          //number of overflows is stored in timetag
          oflcorrection += (ulong)T2WRAPAROUND_V2 * timetag;
        }
        if((channel>=1)&&(channel<=15)) //markers
        {
          truetime = oflcorrection + timetag;
          //Note that actual marker tagging accuracy is only some ns.
          ch = (int)channel;
          GotMarkerT2(fpout, truetime, ch);
        }
        if(channel==0) //sync
        {
          truetime = oflcorrection + timetag;
          ch = 0; //we encode the Sync channel as 0
          GotPhotonT2(fpout, truetime, ch); 
        }
      }
      else //regular input channel
      {
        truetime = oflcorrection + timetag;
        ch = (int)(channel + 1); //we encode the regular channels as 1..N
        GotPhotonT2(fpout, truetime, ch); 
      }
    }

    // HydraHarpV2 or TimeHarp260 or MultiHarp T3 record data
    static void ProcessT3(StreamWriter fpout, uint TTTRRecord)
    {
      int ch, dt;
      ulong truensync;
      const int T3WRAPAROUND = 1024;


      uint nsync =   (TTTRRecord >> 00) & (0xFFFFFFFF >> (32 - 10)); //the lowest 10 bits
      uint dtime =   (TTTRRecord >> 10) & (0xFFFFFFFF >> (32 - 15)); //the next   15 bits
      uint channel = (TTTRRecord >> 25) & (0xFFFFFFFF >> (32 - 06)); //the next   6  bits
      uint special = (TTTRRecord >> 31) & (0xFFFFFFFF >> (32 - 01)); //the next   1  bit


  
      if(special==1)
      {
        if(channel==0x3F) //overflow
        {
          //number of overflows is stored in nsync
          oflcorrection += (ulong)T3WRAPAROUND * nsync;
        }
        if((channel>=1)&&(channel<=15)) //markers
        {
          truensync = oflcorrection + nsync;
          //the time unit depends on sync period
          GotMarkerT3(fpout, truensync, (int)channel);
        }
      }
      else //regular input channel
        {
          truensync = oflcorrection + nsync;
          ch = (int)(channel + 1); //we encode the input channels as 1..N
          dt = (int)dtime;
          //truensync indicates the number of the sync period this event was in
          //the dtime unit depends on the chosen resolution (binning)
          GotPhotonT3(fpout, truensync, ch, dt);
        }
    }




  }
}

