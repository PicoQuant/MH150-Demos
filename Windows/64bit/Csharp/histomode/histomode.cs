
/************************************************************************

  C# demo access to MultiHarp 150 Hardware via MHLIB v 2.0.
  The program performs a measurement based on hardcoded settings.
  The resulting histogram is stored in an ASCII output file.

  PicoQuant GmbH, May 2020

  Note: This is a console application (i.e. run in Windows cmd box)

  Note: At the API level channel numbers are indexed 0..N-1 
    where N is the number of channels the device has.

  
  Tested with the following compilers:

  - Mono 5.14.0 and 6.8.0
  - MS Visual Studio 2013, 2015, and 2019

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

    int HistLen = 0;  // you can change this, observe limits
    int Binning = 0;  // you can change this, observe limits
    int Offset = 0;  // you can change this, observe limits
    int Tacq = 1000;  // Measurement time in millisec, you can change this, observe limits

    int SyncDivider = 1;  // you can change this, observe limits

    int SyncTrigEdge = 0;  // you can change this, observe limits
    int SyncTrigLevel = -50;  // you can change this, observe limits
    int InputTrigEdge = 0;  // you can change this, observe limits
    int InputTrigLevel = -50;  // you can change this, observe limits

    double Resolution = 0;

    int Syncrate = 0;
    int Countrate = 0;
    int ctcstatus = 0;
    int flags = 0;
    int warnings = 0;


    uint[][] counts = new uint[Constants.MAXINPCHAN][];
    for (i = 0; i < Constants.MAXINPCHAN; i++)		
    counts[i] = new uint[Constants.MAXHISTLEN];

    StreamWriter SW = null;

    Console.WriteLine ("MultiHarp 150     MHLib Demo Application               PicoQuant GmbH, 2020");
    Console.WriteLine ("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

    retcode = mhlib.MH_GetLibraryVersion(LibVer);
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_GetLibraryVersion error {0}. Aborted.", Errstr);
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
    Console.WriteLine("Initializing the device...");

    retcode = mhlib.MH_Initialize(dev[0], Constants.MODE_HIST, 0);  // Histo mode
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_Initialize error {0}. Aborted.", Errstr);
      goto ex;
    }

    retcode = mhlib.MH_GetHardwareInfo(dev[0], Model, Partno, Version); //this is only for information
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_GetHardwareInfo error {0}. Aborted.", Errstr);
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
      Console.WriteLine("MH_GetNumOfInputChannels error {0}. Aborted.", Errstr);
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
      Console.WriteLine("MH_SetSyncDiv Error {0}. Aborted.", Errstr);
      goto ex;
    }

    retcode = mhlib.MH_SetSyncEdgeTrg(dev[0], SyncTrigLevel, SyncTrigEdge);
    if (retcode < 0)
    {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_SetSyncEdgeTrg Error {0}. Aborted.", Errstr);
        goto ex;
    }
        
    retcode = mhlib.MH_SetSyncChannelOffset(dev[0], 0);
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_SetSyncChannelOffset Error {0}. Aborted.", Errstr);
      goto ex;
    }

    for(i = 0; i < NumChannels; i++) // we use the same input settings for all channels
    {
      retcode = mhlib.MH_SetInputEdgeTrg(dev[0], i, InputTrigLevel, InputTrigEdge);
      if (retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_SetInputEdgeTrg Error {0}. Aborted.", Errstr);
        goto ex;
      }

      retcode = mhlib.MH_SetInputChannelOffset(dev[0], i, 0);
      if(retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_SetInputChannelOffset Error {0}. Aborted.", Errstr);
        goto ex;
      }

      retcode = mhlib.MH_SetInputChannelEnable(dev[0], i, 1);
      if(retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_SetInputChannelEnable Error {0}. Aborted.", Errstr);
        goto ex;
      }
    }

    retcode = mhlib.MH_SetHistoLen(dev[0], Constants.MAXLENCODE, ref HistLen);
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_SetHistoLen Error {0}. Aborted.", Errstr);
      goto ex;
    }
    Console.WriteLine("Histogram length is {0}", HistLen);

    retcode = mhlib.MH_SetBinning(dev[0], Binning);
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_SetBinning Error {0}. Aborted.", Errstr);
      goto ex;
    }

    retcode = mhlib.MH_SetOffset(dev[0], Offset);
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_SetOffset Error {0}. Aborted.", Errstr);
      goto ex;
    }

    retcode = mhlib.MH_GetResolution(dev[0], ref Resolution);
    if(retcode < 0)
    {
      mhlib.MH_GetErrorString(Errstr, retcode);
      Console.WriteLine("MH_GetResolution Error {0}. Aborted.", Errstr);
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
      Console.WriteLine("MH_GetSyncRate Error {0}. Aborted.", Errstr);
      goto ex;
    }
    Console.WriteLine("Syncrate = {0}/s", Syncrate);

    for(i = 0; i < NumChannels; i++) // for all channels
    {
      retcode = mhlib.MH_GetCountRate(dev[0], i, ref Countrate);
      if(retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_GetCountRate Error {0}. Aborted.", Errstr);
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
      Console.WriteLine("MH_GetWarnings Error {0}. Aborted.", Errstr);
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
      Console.WriteLine("MH_SetStopOverflow Error {0}. Aborted.", Errstr);
      goto ex;
    }

    while(cmd != "q")
    { 
      mhlib.MH_ClearHistMem(dev[0]);
      if(retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_ClearHistMem Error {0}. Aborted.", Errstr);
        goto ex;
      }

      Console.WriteLine("press RETURN to start measurement");
      Console.ReadLine();

      retcode = mhlib.MH_GetSyncRate(dev[0], ref Syncrate);
      if(retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_ClearHistMem Error {0}. Aborted.", Errstr);
        goto ex;
      }
      Console.WriteLine("Syncrate = {0}/s", Syncrate);

      for(i = 0; i < NumChannels; i++) // for all channels
      {
        retcode = mhlib.MH_GetCountRate(dev[0], i, ref Countrate);
        if(retcode<0)
        {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_GetCountRate Error {0}. Aborted.", Errstr);
          goto ex;
        }
        Console.WriteLine("Countrate[{0}] = {1}/s", i, Countrate);
      }

      retcode = mhlib.MH_StartMeas(dev[0], Tacq); 
      if(retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_StartMeas Error {0}. Aborted.", Errstr);
        goto ex;
      }
      Console.WriteLine("Measuring for {0} milliseconds...", Tacq);

      ctcstatus = 0;
      while(ctcstatus == 0)  // wait until measurement is completed
      {
        retcode = mhlib.MH_CTCStatus(dev[0], ref ctcstatus);
        if(retcode < 0)
        {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_CTCStatus Error {0}. Aborted.", Errstr);
          goto ex;
        }
      }

      retcode = mhlib.MH_StopMeas(dev[0]);
      if(retcode < 0)
      {
        mhlib.MH_GetErrorString(Errstr, retcode);
        Console.WriteLine("MH_StopMeas Error {0}. Aborted.", Errstr);
        goto ex;
      }

      Console.WriteLine();
      for(i = 0; i < NumChannels; i++)  // for all channels
      {
        retcode = mhlib.MH_GetHistogram(dev[0], counts[i], i);
        if(retcode < 0)
        {
          mhlib.MH_GetErrorString(Errstr, retcode);
          Console.WriteLine("MH_GetHistogram Error {0}. Aborted.", Errstr);
          goto ex;
        }

        double Integralcount = 0;
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
        Console.WriteLine("MH_GetFlags Error {0}. Aborted.", Errstr);
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

    SW.Close();

  ex:
    for(i = 0; i < Constants.MAXDEVNUM; i++)  // no harm to close all
    {
      mhlib.MH_CloseDevice(i);
    }

    Console.WriteLine("press RETURN to exit");
    Console.ReadLine();
  }
}



