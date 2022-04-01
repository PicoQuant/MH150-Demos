/************************************************************************

  Demo access to MultiHarp 150/160 hardware via MHLIB v 3.1

  THIS IS AN ADVANCED DEMO. DO NOT USE FOR YOUR FIRST EXPERIMENTS.
  Look at the variable meascontrol down below to see what it does.

  The program performs a measurement based on hardcoded settings.
  The resulting histogram is stored in an ASCII output file.

  Michael Wahl, PicoQuant GmbH, March 2022

  Note: This is a console application

  Note: At the API level channel numbers are indexed 0..N-1 
    where N is the number of channels the device has.

  
  Tested with the following compilers:

  - MS Visual Studio 2013 and 2019
  - Mono 6.12.0 (Windows)
  - Mono 6.8.0 (Linux)

************************************************************************/


using System;  // for Console
using System.Text;  // for StringBuilder 
using System.IO;  // for File





class HistoMode 
{

  static void Main() 
  {

    int i,j;
    int retcode;
    string cmd = "";
    int[] dev= new int[Constants.MAXDEVNUM];
    int found = 0;
    int NumChannels = 0;

    StringBuilder LibVer = new StringBuilder (8);
    StringBuilder Serial = new StringBuilder (8);
    StringBuilder Errstr = new StringBuilder (40);
    StringBuilder Model  = new StringBuilder (32);
    StringBuilder Partno = new StringBuilder (16);
    StringBuilder Version = new StringBuilder(16);
    StringBuilder Wtext  = new StringBuilder (16384);

    int HistLen;
    int Binning = 0;  // you can change this, observe limits
    int Offset = 0;  // you can change this, observe limits
    int Tacq = 100;  // Measurement time in millisec, you can change this, observe limits

    int SyncDivider = 1;  // you can change this, observe limits

    int SyncTrigEdge = 0;  // you can change this, observe limits
    int SyncTrigLevel = -100;  // you can change this, observe limits
    int InputTrigEdge = 0;  // you can change this, observe limits
    int InputTrigLevel = -100;  // you can change this, observe limits

    double Resolution = 0;

    int Syncrate = 0;
    int Countrate = 0;
    double Integralcount;
    double elapsed;
    int ctcstatus = 0;
    int flags = 0;
    int warnings = 0;

    int meascontrol
      = Constants.MEASCTRL_SINGLESHOT_CTC;    // start by software and stop when CTC expires (default)
    // = Constants.MEASCTRL_C1_GATED;           // measure while C1 is active		1
    // = Constants.MEASCTRL_C1_START_CTC_STOP; // start with C1 and stop when CTC expires 
    // = Constants.MEASCTRL_C1_START_C2_STOP;  // start with C1 and stop with C2
    int edge1 = Constants.EDGE_RISING;  //Edge of C1 to start (if applicable in chosen mode)
    int edge2 = Constants.EDGE_FALLING; //Edge of C2 to stop (if applicable in chosen mode)


    uint[][] counts = new uint[Constants.MAXINPCHAN][];
    for (i = 0; i < Constants.MAXINPCHAN; i++)		
    counts[i] = new uint[Constants.MAXHISTLEN];

    StreamWriter SW = null;

    Console.WriteLine ("MultiHarp MHLib Demo Application                       PicoQuant GmbH, 2022");
    Console.WriteLine ("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

    try
    {
        retcode = mhlib.MH_GetLibraryVersion(LibVer);
    }
    catch(Exception e)
    {
        Console.WriteLine("Error loading MHLib as \"" + mhlib.MHLib + "\" => " + e.Message);
        Console.WriteLine("press RETURN to exit");
        Console.ReadLine();
        return;
    }

    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_GetLibraryVersion error {0} ({1}). Aborted.", retcode, Errstr);
      goto ex;
    }
    Console.WriteLine("MHLib Version is " + LibVer);

    if(LibVer.ToString() != Constants.LIB_VERSION)
    {
      Console.WriteLine("This program requires MHLib v." + Constants.LIB_VERSION);
      goto ex;
    }
   
    try
    {
      SW = File.CreateText("histomode.out");
    }
    catch ( Exception )
    {
      Console.WriteLine("Error creating file");
      goto ex;
    }

    Console.WriteLine("Searching for MultiHarp devices...");
    Console.WriteLine("Devidx     Status");

    for(i = 0; i < Constants.MAXDEVNUM; i++)
    {
      retcode = mhlib.MH_OpenDevice(i, Serial);  
      if(retcode == 0) //Grab any MultiHarp we can open
      {
        Console.WriteLine("  {0}        S/N {1}", i, Serial);
        dev[found] = i; //keep index to devices we want to use
        found++;
      }
      else
      {
        if (retcode == Errorcodes.MH_ERROR_DEVICE_OPEN_FAIL)
        {
          Console.WriteLine("  {0}        no device", i);
        }
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

    if(found < 1)
    {
      Console.WriteLine("No device available.");
      goto ex; 
    }

    Console.WriteLine("Using device {0}", dev[0]);
    Console.WriteLine("Binning           : {0}", Binning);
    Console.WriteLine("Offset            : {0}", Offset);
    Console.WriteLine("AcquisitionTime   : {0}", Tacq);
    Console.WriteLine("SyncDivider       : {0}", SyncDivider);

    Console.WriteLine("Initializing the device...");

    retcode = mhlib.MH_Initialize(dev[0], Constants.MODE_HIST, 0);  //Histo mode with internal clock
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_Initialize error {0} ({1}). Aborted.", retcode, Errstr);
      goto ex;
    }

    retcode = mhlib.MH_GetHardwareInfo(dev[0], Model, Partno, Version); //this is only for information
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_GetHardwareInfo error {0} ({1}). Aborted.", retcode, Errstr);
      goto ex;
    }
    else
    {
      Console.WriteLine("Found Model {0} Part no {1} Version {2}", Model, Partno, Version);
    }

    retcode = mhlib.MH_GetNumOfInputChannels(dev[0], ref NumChannels); 
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_GetNumOfInputChannels error {0} ({1}). Aborted.", retcode, Errstr);
      goto ex;
    }
    else
    {
      Console.WriteLine("Device has {0} input channels.",NumChannels);
    }

    retcode = mhlib.MH_SetSyncDiv(dev[0], SyncDivider);
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_SetSyncDiv error {0} ({1}). Aborted.", retcode, Errstr);
      goto ex;
    }

    retcode = mhlib.MH_SetSyncEdgeTrg(dev[0], SyncTrigLevel, SyncTrigEdge);
    if (retcode < 0)
    {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_SetSyncEdgeTrg error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
    }
        
    retcode = mhlib.MH_SetSyncChannelOffset(dev[0], 0);    //in ps, emulate a cable delay
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_SetSyncChannelOffset error {0} ({1}). Aborted.", retcode, Errstr);
      goto ex;
    }

    for(i = 0; i < NumChannels; i++) // we use the same input settings for all channels
    {
      retcode = mhlib.MH_SetInputEdgeTrg(dev[0], i, InputTrigLevel, InputTrigEdge);
      if (retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_SetInputEdgeTrg error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }

      retcode = mhlib.MH_SetInputChannelOffset(dev[0], i, 0);  //in ps, emulate a cable delay
      if(retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_SetInputChannelOffset error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }

      retcode = mhlib.MH_SetInputChannelEnable(dev[0], i, 1);
      if(retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_SetInputChannelEnable error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }
    }

    retcode = mhlib.MH_SetHistoLen(dev[0], Constants.MAXLENCODE, out HistLen);
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_SetHistoLen error {0} ({1}). Aborted.", retcode, Errstr);
      goto ex;
    }
    Console.WriteLine("Histogram length is {0}", HistLen);

    retcode = mhlib.MH_SetBinning(dev[0], Binning);
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_SetBinning error {0} ({1}). Aborted.", retcode, Errstr);
      goto ex;
    }

    retcode = mhlib.MH_SetOffset(dev[0], Offset);
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_SetOffset error {0} ({1}). Aborted.", retcode, Errstr);
      goto ex;
    }

    retcode = mhlib.MH_GetResolution(dev[0], ref Resolution);
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_GetResolution error {0} ({1}). Aborted.", retcode, Errstr);
      goto ex;
    }

    Console.WriteLine("Resolution is {0} ps", Resolution);


    // After Init allow 150 ms for valid  count rate readings
    // Subsequently you get new values after every 100ms
    System.Threading.Thread.Sleep(150);

    retcode = mhlib.MH_GetSyncRate(dev[0], ref Syncrate);
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_GetSyncRate error {0} ({1}). Aborted.", retcode, Errstr);
      goto ex;
    }
    Console.WriteLine("Syncrate = {0}/s", Syncrate);

    for(i = 0; i < NumChannels; i++) // for all channels
    {
      retcode = mhlib.MH_GetCountRate(dev[0], i, ref Countrate);
      if(retcode < 0)
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
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_GetWarnings error {0} ({1}). Aborted.", retcode, Errstr);
      goto ex;
    }

    if(warnings != 0)
    {
      mhlib.MH_GetWarningsText(dev[0], Wtext, warnings);
      Console.WriteLine("{0}", Wtext);
    }

    retcode = mhlib.MH_SetStopOverflow(dev[0], 0, 10000);  // for example only
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_SetStopOverflow error {0} ({1}). Aborted.", retcode, Errstr);
      goto ex;
    }

    retcode = mhlib.MH_SetMeasControl(dev[0], meascontrol, edge1, edge2);
    if (retcode < 0)
    {
        Console.WriteLine("MH_SetMeasControl error {0}. Aborted.", retcode);
        goto ex;
    }

    while(cmd != "q")
    { 
      mhlib.MH_ClearHistMem(dev[0]);
      if(retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_ClearHistMem error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }

      Console.WriteLine("press RETURN to start measurement");
      Console.ReadLine();

      retcode = mhlib.MH_GetSyncRate(dev[0], ref Syncrate);
      if(retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_ClearHistMem error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }
      Console.WriteLine("Syncrate = {0}/s", Syncrate);

      for(i = 0; i < NumChannels; i++) // for all channels
      {
        retcode = mhlib.MH_GetCountRate(dev[0], i, ref Countrate);
        if(retcode<0)
        {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_GetCountRate error {0} ({1}). Aborted.", retcode, Errstr);
          goto ex;
        }
        Console.WriteLine("Countrate[{0}] = {1}/s", i, Countrate);
      }

      retcode = mhlib.MH_StartMeas(dev[0], Tacq);
      if(retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_StartMeas error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }

      #region here the demo differs from 'histomode'

      if (meascontrol != Constants.MEASCTRL_SINGLESHOT_CTC)
      {
          Console.WriteLine("waiting for hardware start on C1...");
          ctcstatus = 1;
          while (ctcstatus == 1)
          {
              retcode = mhlib.MH_CTCStatus(dev[0], ref ctcstatus);
              if (retcode < 0)
              {
                  Console.WriteLine("MH_CTCStatus error {0}. Aborted.", retcode);
                  goto ex;
              }
          }
      }

      if ((meascontrol == Constants.MEASCTRL_SINGLESHOT_CTC) || meascontrol == Constants.MEASCTRL_C1_START_CTC_STOP)
          Console.WriteLine("\nMeasuring for {0} milliseconds...", Tacq);

      if (meascontrol == Constants.MEASCTRL_C1_GATED)
          Console.WriteLine("\nMeasuring, waiting for other C1 edge to stop...");

      if (meascontrol == Constants.MEASCTRL_C1_START_C2_STOP)
          Console.WriteLine("\nMeasuring, waiting for C2 to stop...");


      ctcstatus = 0;

      while (ctcstatus == 0)
      {
          retcode = mhlib.MH_CTCStatus(dev[0], ref ctcstatus);
          if (retcode < 0)
          {
              mhlib.MH_GetErrorString(Errstr, retcode);
              Console.WriteLine("\nMH_CTCStatus error {0} ({1}). Aborted.", retcode, Errstr);
              goto ex;
          }
      }

      retcode = mhlib.MH_StopMeas(dev[0]);
      if (retcode < 0)
      {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("\nMH_StopMeas error {0} ({1}). Aborted.", retcode, Errstr);
          goto ex;
      }

      retcode = mhlib.MH_GetElapsedMeasTime(dev[0], out elapsed);
      if (retcode < 0)
      {
          Console.WriteLine("\nTH260_GetElapsedMeasTime error{0}. Aborted.", retcode);
          goto ex;
      }
      Console.WriteLine("\n  Elapsed measurement time was{0} ms", elapsed);


      #endregion

      Console.WriteLine();
      for(i = 0; i < NumChannels; i++)  // for all channels
      {
        retcode = mhlib.MH_GetHistogram(dev[0], counts[i], i);
        if(retcode < 0)
        {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_GetHistogram error {0} ({1}). Aborted.", retcode, Errstr);
          goto ex;
        }

        Integralcount = 0;
        for(j = 0; j < HistLen; j++)
        {
          Integralcount+=counts[i][j];
        }

        Console.WriteLine("  Integralcount[{0}] = {1}", i, Integralcount);
      }

      Console.WriteLine();

      retcode = mhlib.MH_GetFlags(dev[0], ref flags);
      if(retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_GetFlags error {0} ({1}). Aborted.", retcode, Errstr);
        goto ex;
      }

      if ((flags & Constants.FLAG_OVERFLOW) != 0)
      {
        Console.WriteLine("  Overflow.");
      }

      Console.WriteLine("Enter c to continue or q to quit and save the count data.");
      cmd = Console.ReadLine();

    }  // while

    for(j = 0; j < HistLen; j++)
    {
      for(i = 0; i < NumChannels; i++)
      {
        SW.Write("{0,5} ", counts[i][j]);
      }
      SW.WriteLine();
    }

  ex:
    for(i = 0; i < Constants.MAXDEVNUM; i++)  // no harm to close all
    {
      mhlib.MH_CloseDevice(i);
    }

    try
    {
        SW.Flush();
        SW.Close();
        SW.Dispose();
        SW = null;
    }
    catch(Exception e)
    {
        Console.WriteLine("Error closing the file: " + e);
    }
	
    Console.WriteLine("press RETURN to exit");
    Console.ReadLine();
  }
}



