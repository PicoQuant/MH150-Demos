/************************************************************************

  Demo access to MultiHarp 150/160 hardware via MHLIB v.3.1
  The program performs a TTTR mode measurement simultaneously on mutiple 
  devices, using hardcoded settings. The resulting event data is stored in 
  multiple binary output files.

  Michael Wahl, PicoQuant GmbH, March 2022

  Note: This is a console application

  Note: At the API level the input channel numbers are indexed 0..N-1
  where N is the number of input channels the device has.

  Note: This demo writes only raw event data to the output files.
  It does not write a file header as regular .ptu files have it.

  
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
    static void Main(string[] args)
    {
      const int NDEVICES = 2;  //this specifies how many devices we want to use in parallel

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
      int Binning = 0;  // you can change this, meaningful only in T3 mode, observe limits 
      int Offset = 0;  // you can change this, meaningful only in T3 mode, observe limits 
      int Tacq = 10000;  // Measurement time in millisec, you can change this, observe limits 

      int SyncDivider = 1;  // you can change this, usually 1 in T2 mode 

      int SyncTrigEdge = 0;  // you can change this, observe limits
      int SyncTrigLevel = -50;  // you can change this, observe limits
      int InputTrigEdge = 0;  // you can change this, observe limits
      int InputTrigLevel = -50;  // you can change this, observe limits

      double Resolution = 0;

      int Syncrate = 0;
      int Countrate = 0;
      int flags = 0;
      long Progress = 0;
      int nRecords = 0;
      int warnings = 0;

      int i, j, n;

      int[] done = new int[NDEVICES];
      int alldone;
      string filename = null;


      uint[] buffer = new uint[Constants.TTREADMAX];

      FileStream fs = null;
      BinaryWriter[] bw = new BinaryWriter[NDEVICES];


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
          for (i = 0; i < NDEVICES; i++)
          {
              filename = String.Format("tttrmode_{0}.out", i);
              fs = File.Create(filename);
              bw[i] = new BinaryWriter(fs);
          }
      }
      catch (Exception)
      {
        Console.WriteLine("Error creating file " + filename);
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

      //In this demo we will use the first NDEVICES devices we find.
      //You can also check for specific serial numbers, so that you always know 
      //which physical device you are talking to.


      if (found < NDEVICES)
      {
        Console.WriteLine("Not enough devices available.");
        goto ex;
      }

      Console.WriteLine("\n");
      for (n = 0; n < NDEVICES; n++)
          Console.WriteLine("Using device #{0}", dev[n]);


      for (n = 0; n < NDEVICES; n++)
      {
          Console.WriteLine("Initializing device #{0}", dev[n]);
          retcode = mhlib.MH_Initialize(dev[n], Mode, 0);
          if (retcode < 0)
          {
              mhlib.MH_GetErrorString(Errstr, retcode);
              Console.WriteLine("MH_Initialize error {0} ({1}). Aborted.", retcode, Errstr);
              goto ex;
          }

          retcode = mhlib.MH_GetHardwareInfo(dev[n], Model, Partno, Version);  // this is only for information
          if (retcode < 0)
          {
              mhlib.MH_GetErrorString(Errstr, retcode);
              Console.WriteLine("MH_GetHardwareInfo error {0} ({1}). Aborted.", retcode, Errstr);
              goto ex;
          }
          else
              Console.WriteLine("Found Model {0} Part no {1} Version {2}", Model, Partno, Version);


          retcode = mhlib.MH_GetNumOfInputChannels(dev[n], ref NumChannels);
          if (retcode < 0)
          {
              mhlib.MH_GetErrorString(Errstr, retcode);
              Console.WriteLine("MH_GetNumOfInputChannels error {0} ({1}). Aborted.", retcode, Errstr);
              goto ex;
          }
          else
              Console.WriteLine("Device has {0} input channels.", NumChannels);


          retcode = mhlib.MH_SetSyncDiv(dev[n], SyncDivider);
          if (retcode < 0)
          {
              mhlib.MH_GetErrorString(Errstr, retcode);
              Console.WriteLine("MH_SetSyncDiv error {0} ({1}). Aborted.", retcode, Errstr);
              goto ex;
          }

          retcode = mhlib.MH_SetSyncEdgeTrg(dev[n], SyncTrigLevel, SyncTrigEdge);
          if (retcode < 0)
          {
              mhlib.MH_GetErrorString(Errstr, retcode);
              Console.WriteLine("MH_SetSyncEdgeTrg error {0} ({1}). Aborted.", retcode, Errstr);
              goto ex;
          }

          retcode = mhlib.MH_SetSyncChannelOffset(dev[n], 0);    //in ps, emulate a cable delay
          if (retcode < 0)
          {
              mhlib.MH_GetErrorString(Errstr, retcode);
              Console.WriteLine("MH_SetSyncChannelOffset error {0} ({1}). Aborted.", retcode, Errstr);
              goto ex;
          }

          for (i = 0; i < NumChannels; i++)  // we use the same input settings for all channels
          {
              retcode = mhlib.MH_SetInputEdgeTrg(dev[n], i, InputTrigLevel, InputTrigEdge);
              if (retcode < 0)
              {
                  mhlib.MH_GetErrorString(Errstr, retcode);
                  Console.WriteLine("MH_SetInputEdgeTrg error {0} ({1}). Aborted.", retcode, Errstr);
                  goto ex;
              }

              retcode = mhlib.MH_SetInputChannelOffset(dev[n], i, 0);  //in ps, emulate a cable delay
              if (retcode < 0)
              {
                  mhlib.MH_GetErrorString(Errstr, retcode);
                  Console.WriteLine("MH_SetInputChannelOffset error {0} ({1}). Aborted.", retcode, Errstr);
                  goto ex;
              }
              retcode = mhlib.MH_SetInputChannelEnable(dev[n], i, 1);
              if (retcode < 0)
              {
                  mhlib.MH_GetErrorString(Errstr, retcode);
                  Console.WriteLine("MH_SetInputChannelEnable error {0} ({1}). Aborted.", retcode, Errstr);
                  goto ex;
              }
          }

          if (Mode != Constants.MODE_T2)
          {
              retcode = mhlib.MH_SetBinning(dev[n], Binning);
              if (retcode < 0)
              {
                  mhlib.MH_GetErrorString(Errstr, retcode);
                  Console.WriteLine("MH_SetBinning error {0} ({1}). Aborted.", retcode, Errstr);
                  goto ex;
              }

              retcode = mhlib.MH_SetOffset(dev[n], Offset);
              if (retcode < 0)
              {
                  mhlib.MH_GetErrorString(Errstr, retcode);
                  Console.WriteLine("MH_SetOffset error {0} ({1}). Aborted.", retcode, Errstr);
                  goto ex;
              }
          }

          retcode = mhlib.MH_GetResolution(dev[n], ref Resolution);
          if (retcode < 0)
          {
              mhlib.MH_GetErrorString(Errstr, retcode);
              Console.WriteLine("MH_GetResolution error {0} ({1}). Aborted.", retcode, Errstr);
              goto ex;
          }

          Console.WriteLine("Resolution is {0} ps", Resolution);
      } //for (n = 0; n < NDEVICES; n++)


      // After Init allow 150 ms for valid  count rate readings
      // Subsequently you get new values after every 100ms
      System.Threading.Thread.Sleep(150);

      for (n = 0; n < NDEVICES; n++)
      {
          Console.WriteLine("Measuring input rates...");

          retcode = mhlib.MH_GetSyncRate(dev[n], ref Syncrate);
          if (retcode < 0)
          {
              mhlib.MH_GetErrorString(Errstr, retcode);
              Console.WriteLine("MH_GetSyncRate error {0} ({1}). Aborted.", retcode, Errstr);
              goto ex;
          }
          Console.WriteLine("Syncrate[{0}] = {1}/s", n, Syncrate);

          for (i = 0; i < NumChannels; i++)  // for all channels
          {
              retcode = mhlib.MH_GetCountRate(dev[n], i, ref Countrate);
              if (retcode < 0)
              {
                  mhlib.MH_GetErrorString(Errstr, retcode);
                  Console.WriteLine("MH_GetCountRate error {0} ({1}). Aborted.", retcode, Errstr);
                  goto ex;
              }
              Console.WriteLine("Countrate[{0}, {1}] = {2}/s", n, i, Countrate);
          }

          Console.WriteLine();
      } //for (n = 0; n < NDEVICES; n++)


      // After getting the count rates you can check for warnings
      for (n = 0; n < NDEVICES; n++)
      {
          retcode = mhlib.MH_GetWarnings(dev[n], ref warnings);
          if (retcode < 0)
          {
              mhlib.MH_GetErrorString(Errstr, retcode);
              Console.WriteLine("MH_GetWarnings error {0} ({1}). Aborted.", retcode, Errstr);
              goto ex;
          }
          if (warnings != 0)
          {
              mhlib.MH_GetWarningsText(dev[n], Wtext, warnings);
              Console.WriteLine("\nDevice {0}: {1}", n, Wtext);
          }
      } //for (n = 0; n < NDEVICES; n++)


      Console.Write("press RETURN to start");
      Console.ReadLine();

      Console.Write("Starting data collection...");

      Progress = 0;
      Console.Write("Progress: {0,12}", Progress);

      //Starting the measurement on multiple devices via software will inevitably
      //introduce some ms of delay, so you cannot rely on an exact agreement
      //of the starting points of the TTTR streams. If you need this, you will 
      //have to use hardware synchronization.
      for (n = 0; n < NDEVICES; n++)
      {
          retcode = mhlib.MH_StartMeas(dev[n], Tacq);
          if (retcode < 0)
          {
              mhlib.MH_GetErrorString(Errstr, retcode);
              Console.WriteLine();
              Console.WriteLine("MH_StartMeas error {0} ({1}). Aborted.", retcode, Errstr);
              goto ex;
          }
          
          done[n] = 0;
      } //for (n = 0; n < NDEVICES; n++)


      while (true) //the overall measurement loop
      {
          // In this demo we loop over NDEVICES to fetch the data.
          // For efficiency this should be done in parallel
          for (n = 0; n < NDEVICES; n++)
          {
              retcode = mhlib.MH_GetFlags(dev[n], ref flags);
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

              retcode = mhlib.MH_ReadFiFo(dev[n], buffer, ref nRecords);  // may return less!
              if (retcode < 0)
              {
                  mhlib.MH_GetErrorString(Errstr, retcode);
                  Console.WriteLine();
                  Console.WriteLine("MH_GetFlags error {0} ({1}). Aborted.", retcode, Errstr);
                  goto ex;
              }

              if (nRecords > 0)
              {
                  for (j = 0; j < nRecords; j++)
                      bw[n].Write(buffer[j]);

                  Progress += nRecords;
                  if (n == NDEVICES - 1)
                  {
                      Console.Write("\b\b\b\b\b\b\b\b\b\b\b\b{0,12}", Progress);
                  }
              }
              else
              {
                  retcode = mhlib.MH_CTCStatus(dev[n], ref ctcstatus);
                  if (retcode < 0)
                  {
                      mhlib.MH_GetErrorString(Errstr, retcode);
                      Console.WriteLine();
                      Console.WriteLine("MH_CTCStatus error {0} ({1}). Aborted.", retcode, Errstr);
                      goto ex;
                  }
                  if (ctcstatus > 0)
                  {
                      done[n] = 1;
                      alldone = 0;
                      for (j = 0; j < NDEVICES; j++)
                          alldone += done[j];
                      if (alldone == NDEVICES)
                      {
                          Console.WriteLine();
                          Console.WriteLine("Done");
                          goto stoptttr;
                      }
                  }
              }

              // within this loop you can also read the count rates if needed.

          } //for (n = 0; n < NDEVICES; n++)
      } //while (true)

      stoptttr:
      Console.WriteLine();

      for (n = 0; n < NDEVICES; n++)
      {
          retcode = mhlib.MH_StopMeas(dev[n]);
          if (retcode < 0)
          {
              mhlib.MH_GetErrorString(Errstr, retcode);
              Console.WriteLine("MH_StopMeas error {0} ({1}). Aborted.", retcode, Errstr);
              goto ex;
          }
      } //for (n = 0; n < NDEVICES; n++)


      ex:

      for (i = 0; i < Constants.MAXDEVNUM; i++)  // no harm to close all
      {
        mhlib.MH_CloseDevice(i);
      }

      for (n = 0; n < NDEVICES; n++)
      {
          try
          {
              bw[n].Flush();
              bw[n].Close();
              bw[n].Dispose();
          }
          catch (Exception e)
          {
              Console.WriteLine("Error closing the file: " + e);
          }
      }

      Console.WriteLine("press RETURN to exit");
      Console.ReadLine();
    }
  }
}

