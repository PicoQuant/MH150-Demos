/************************************************************************

  Demo access to MultiHarp 150/160 hardware via MHLIB v.3.1
  The program performs a measurement based on hardcoded settings.
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

      Console.WriteLine("Measuring input rates...\n");



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


      if (Mode == Constants.MODE_T2)
          sw.Write("ev chn       time/ps\n\n");
      else
          sw.Write("ev chn  ttag/s   dtime/ps\n\n");

      Console.WriteLine("press RETURN to start");
      Console.ReadLine();


      retcode = mhlib.MH_StartMeas(dev[0], Tacq);
      if (retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine();
        Console.WriteLine("MH_StartMeas error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }

      #region Here this demo differs from 'classic' tttrmode-demo


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
              Console.WriteLine("MH_GetSyncPeriod error {0} ({1}). Aborted.", retcode, Errstr);
              goto ex;
          }
          Console.WriteLine("Sync period is {0} ns", Syncperiod * 1e9);
      }

      Console.WriteLine("Starting data collection...");

      Progress = 0;
      Console.Write("Progress: {0,12}", Progress);

      oflcorrection = 0;


      #endregion



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

