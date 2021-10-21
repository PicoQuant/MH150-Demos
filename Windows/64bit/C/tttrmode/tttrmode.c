/************************************************************************

Demo access to MultiHarp 150/160 hardware via MHLIB v.3.0
The program performs a measurement based on hardcoded settings.
The resulting event data is stored in a binary output file.

Michael Wahl, PicoQuant GmbH, March 2021

Note: This is a console application

Note: At the API level the input channel numbers are indexed 0..N-1
where N is the number of input channels the device has.

Note: This demo writes only raw event data to the output file.
It does not write a file header as regular .ht* files have it.


Tested with the following compilers:

  - MinGW 2.0.0 (Windows 32 bit)
  - MinGW-W64 4.3.5 (Windows 64 bit)
  - MS Visual C++ 6.0 (Windows 32 bit)
  - MS Visual C++ 2015 and 2019 (Windows 32 and 64 bit)
  - gcc 7.5.0 and 9.3.0 (Linux 64 bit)

************************************************************************/

#ifndef _WIN32
#include <unistd.h>
#define Sleep(msec) usleep(msec*1000)
#define __int64 long long
#else
#include <windows.h>
#include <dos.h>
#include <conio.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mhdefin.h"
#include "mhlib.h"
#include "errorcodes.h"


unsigned int buffer[TTREADMAX];


int main(int argc, char* argv[])
{

  int dev[MAXDEVNUM];
  int found = 0;
  FILE *fpout;
  int retcode;
  int ctcstatus;
  char LIB_Version[8];
  char HW_Model[32];
  char HW_Partno[8];
  char HW_Serial[9];
  char HW_Version[16];
  char Errorstring[40];
  int NumChannels;
  int Mode = MODE_T2; //set T2 or T3 here, observe suitable Sync divider and Range!
  int Binning = 0; //you can change this, meaningful only in T3 mode
  int Offset = 0;  //you can change this, meaningful only in T3 mode
  int Tacq = 10000; //Measurement time in millisec, you can change this
  int SyncDivider = 1; //you can change this, observe Mode! READ MANUAL!

  int SyncTiggerEdge = 0; //you can change this
  int SyncTriggerLevel = -50; //you can change this
  int InputTriggerEdge = 0; //you can change this
  int InputTriggerLevel = -50; //you can change this

  double Resolution;
  int Syncrate;
  int Countrate;
  int i;
  int flags;
  int warnings;
  char warningstext[16384]; //must have 16384 bytest text buffer
  int nRecords;
  unsigned int Progress;


  printf("\nMultiHarp MHLib Demo Application                      PicoQuant GmbH, 2021");
  printf("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
  MH_GetLibraryVersion(LIB_Version);
  printf("\nLibrary version is %s\n", LIB_Version);
  if (strncmp(LIB_Version, LIB_VERSION, sizeof(LIB_VERSION)) != 0)
  {
    printf("\nWarning: The application was built for version %s.", LIB_VERSION);
  }

  if ((fpout = fopen("tttrmode.out", "wb")) == NULL)
  {
    printf("\ncannot open output file\n");
    goto ex;
  }


  printf("\nSearching for MultiHarp devices...");
  printf("\nDevidx     Serial     Status");


  for (i = 0; i < MAXDEVNUM; i++)
  {
    retcode = MH_OpenDevice(i, HW_Serial);
    if (retcode == 0) //Grab any device we can open
    {
      printf("\n  %1d        %7s    open ok", i, HW_Serial);
      dev[found] = i; //keep index to devices we want to use
      found++;
    }
    else
    {
      if (retcode == MH_ERROR_DEVICE_OPEN_FAIL)
      {
        printf("\n  %1d        %7s    no device", i, HW_Serial);
      }
      else
      {
        MH_GetErrorString(Errorstring, retcode);
        printf("\n  %1d        %7s    %s", i, HW_Serial, Errorstring);
      }
    }
  }

  //In this demo we will use the first device we find, i.e. dev[0].
  //You can also use multiple devices in parallel.
  //You can also check for specific serial numbers, so that you always know 
  //which physical device you are talking to.

  if (found < 1)
  {
    printf("\nNo device available.");
    goto ex;
  }
  printf("\nUsing device #%1d", dev[0]);
  printf("\nInitializing the device...");


  retcode = MH_Initialize(dev[0], Mode, 0);
  if (retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_Initialize error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  retcode = MH_GetHardwareInfo(dev[0], HW_Model, HW_Partno, HW_Version);
  if (retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_GetHardwareInfo error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }
  else
  {
    printf("\nFound Model %s Part no %s Version %s", HW_Model, HW_Partno, HW_Version);
  }


  retcode = MH_GetNumOfInputChannels(dev[0], &NumChannels);
  if (retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_GetNumOfInputChannels error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }
  else
  {
    printf("\nDevice has %i input channels.", NumChannels);
  }

  printf("\n\nUsing the following settings:\n");

  printf("Mode              : %d\n", Mode);
  printf("Binning           : %d\n", Binning);
  printf("Offset            : %d\n", Offset);
  printf("AcquisitionTime   : %d\n", Tacq);
  printf("SyncDivider       : %d\n", SyncDivider);
  printf("SyncTiggerEdge    : %d\n", SyncTiggerEdge);
  printf("SyncTriggerLevel  : %d\n", SyncTriggerLevel);
  printf("InputTriggerEdge  : %d\n", InputTriggerEdge);
  printf("InputTriggerLevel : %d\n", InputTriggerLevel);


  retcode = MH_SetSyncDiv(dev[0], SyncDivider);
  if (retcode < 0)
  {
   MH_GetErrorString(Errorstring, retcode);
    printf("\nPH_SetSyncDiv error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  retcode =MH_SetSyncEdgeTrg(dev[0], SyncTriggerLevel, SyncTiggerEdge);
  if (retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_SetSyncEdgeTrg error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  retcode = MH_SetSyncChannelOffset(dev[0], 0);
  if (retcode<0)
  {
   MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_SetSyncChannelOffset error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  for (i = 0; i < NumChannels; i++) // we use the same input offset for all channels
  {
    retcode = MH_SetInputEdgeTrg(dev[0], i, InputTriggerLevel, InputTriggerEdge);
    if (retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_SetInputEdgeTrg error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }

    retcode =MH_SetInputChannelOffset(dev[0], i, 0);
    if (retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_SetInputChannelOffset error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }

    retcode = MH_SetInputChannelEnable(dev[0], i, 1);
    if (retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_SetInputChannelEnable error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }
  }

  if (Mode != MODE_T2)
  {
    retcode = MH_SetBinning(dev[0], Binning);
    if (retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_SetBinning error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }

    retcode = MH_SetOffset(dev[0], Offset);
    if (retcode<0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_SetOffset error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }
  }

  retcode = MH_GetResolution(dev[0], &Resolution);
  if (retcode<0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_GetResolution error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }
  printf("\nResolution is %1.0lfps\n", Resolution);


  printf("\nMeasuring input rates...\n");


  // After Init allow 150 ms for valid  count rate readings
  // Subsequently you get new values after every 100ms
  Sleep(150);

  retcode = MH_GetSyncRate(dev[0], &Syncrate);
  if (retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_GetSyncRate error%d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }
  printf("\nSyncrate=%1d/s", Syncrate);


  for (i = 0; i < NumChannels; i++) // for all channels
  {
    retcode = MH_GetCountRate(dev[0], i, &Countrate);
    if (retcode<0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_GetCountRate error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }
    printf("\nCountrate[%1d]=%1d/s", i, Countrate);
  }

  printf("\n");

  //after getting the count rates you can check for warnings
  retcode = MH_GetWarnings(dev[0], &warnings);
  if (retcode<0)
  {
   MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_GetWarnings error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }
  if (warnings)
  {
    MH_GetWarningsText(dev[0], warningstext, warnings);
    printf("\n\n%s", warningstext);
  }


  printf("\npress RETURN to start");
  getchar();

  printf("\nStarting data collection...\n");

  Progress = 0;
  printf("\nProgress:%12u", Progress);

  retcode = MH_StartMeas(dev[0], Tacq);
  if (retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_StartMeas error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  while (1)
  {
    retcode = MH_GetFlags(dev[0], &flags);
    if (retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_GetFlags error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }

    if (flags & FLAG_FIFOFULL)
    {
      printf("\nFiFo Overrun!\n");
      goto stoptttr;
    }

    retcode = MH_ReadFiFo(dev[0], buffer, &nRecords);	//may return less!  
    if (retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_ReadFiFo error %d (%s). Aborted.\n", retcode, Errorstring);
      goto stoptttr;
    }

    if (nRecords)
    {
      if (fwrite(buffer, 4, nRecords, fpout) != (unsigned)nRecords)
      {
        printf("\nfile write error\n");
        goto stoptttr;
      }
      Progress += nRecords;
      printf("\b\b\b\b\b\b\b\b\b\b\b\b%12u", Progress);
      fflush(stdout);
    }
    else
    {
      retcode = MH_CTCStatus(dev[0], &ctcstatus);
      if (retcode < 0)
      {
        MH_GetErrorString(Errorstring, retcode);
        printf("\nMH_CTCStatus error %d (%s). Aborted.\n", retcode, Errorstring);
        goto ex;
      }
      if (ctcstatus)
      {
        printf("\nDone\n");
        goto stoptttr;
      }
    }

    //within this loop you can also read the count rates if needed.
  }

stoptttr:

  retcode = MH_StopMeas(dev[0]);
  if (retcode < 0)
  {
   MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_StopMeas error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

ex:

  for (i = 0; i < MAXDEVNUM; i++) //no harm to close all
  {
    MH_CloseDevice(i);
  }
  if (fpout)
  {
    fclose(fpout);
  }

  printf("\npress RETURN to exit");
  getchar();

  return 0;
}


