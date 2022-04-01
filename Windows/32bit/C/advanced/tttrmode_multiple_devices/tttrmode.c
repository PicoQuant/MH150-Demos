/************************************************************************

Demo access to MultiHarp 150/160 hardware via MHLIB v.3.1
The program performs a TTTR mode measurement simultaneously on mutiple 
devices, using hardcoded settings. The resulting event data is stored in 
multiple binary output files.

Michael Wahl, PicoQuant GmbH, March 2022

Note: This is a console application

Note: At the API level the input channel numbers are indexed 0..N-1
where N is the number of input channels the device has.

Note: This demo writes only raw event data to the output file.
It does not write a file header as regular .ptu files have it.

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

#define NDEVICES 2  //this specifies how many devices we want to use in parallel


unsigned int buffer[NDEVICES][TTREADMAX];


int main(int argc, char* argv[])
{

  int dev[MAXDEVNUM];
  int found = 0;
  FILE *fpout[NDEVICES];
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
  int i,j,n;
  int flags;
  int warnings;
  char warningstext[16384]; //must have 16384 bytest text buffer
  int nRecords;
  unsigned int Progress;
  char filename[40];
  int done[NDEVICES];
  int alldone;


  printf("\nMultiHarp MHLib Demo Application                      PicoQuant GmbH, 2022");
  printf("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
  MH_GetLibraryVersion(LIB_Version);
  printf("\nLibrary version is %s\n", LIB_Version);
  if (strncmp(LIB_Version, LIB_VERSION, sizeof(LIB_VERSION)) != 0)
  {
    printf("\nWarning: The application was built for version %s.", LIB_VERSION);
  }

  for(n = 0; n < NDEVICES; n++)
  {
    sprintf(filename,"tttrmode_%1d.out",n);
    if((fpout[n]=fopen(filename,"wb"))==NULL)
    {
      printf("\ncannot open output file %s\n",filename); 
      goto ex;
    }
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

  //In this demo we will use the first NDEVICES devices we find.
  //You can also check for specific serial numbers, so that you always know 
  //which physical device you are talking to.

  if (found < NDEVICES)
  {
    printf("\nNot enough devices available.");
    goto ex;
  }

  printf("\n");
  for(n = 0; n < NDEVICES; n++)
	printf("\nUsing device #%1d",dev[n]);
  printf("\n");

  for(n = 0; n < NDEVICES; n++)
  {
    printf("\nInitializing device #%1d",dev[n]);

    retcode = MH_Initialize(dev[n], Mode, 0);
    if (retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_Initialize error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }

    retcode = MH_GetHardwareInfo(dev[n], HW_Model, HW_Partno, HW_Version);
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

    retcode = MH_GetNumOfInputChannels(dev[n], &NumChannels);
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

    retcode = MH_SetSyncDiv(dev[n], SyncDivider);
    if (retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nPH_SetSyncDiv error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }

    retcode =MH_SetSyncEdgeTrg(dev[n], SyncTriggerLevel, SyncTiggerEdge);
    if (retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_SetSyncEdgeTrg error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }

    retcode = MH_SetSyncChannelOffset(dev[n], 0); //in ps, emulates a cable delay
    if (retcode<0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_SetSyncChannelOffset error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }

    for (i = 0; i < NumChannels; i++) // we use the same input settings for all channels
    {
      retcode = MH_SetInputEdgeTrg(dev[n], i, InputTriggerLevel, InputTriggerEdge);
      if (retcode < 0)
      {
        MH_GetErrorString(Errorstring, retcode);
        printf("\nMH_SetInputEdgeTrg error %d (%s). Aborted.\n", retcode, Errorstring);
        goto ex;
      }

      retcode =MH_SetInputChannelOffset(dev[n], i, 0); //in ps, emulates a cable delay
      if (retcode < 0)
      {
        MH_GetErrorString(Errorstring, retcode);
        printf("\nMH_SetInputChannelOffset error %d (%s). Aborted.\n", retcode, Errorstring);
        goto ex;
      }

      retcode = MH_SetInputChannelEnable(dev[n], i, 1);
      if (retcode < 0)
      {
        MH_GetErrorString(Errorstring, retcode);
        printf("\nMH_SetInputChannelEnable error %d (%s). Aborted.\n", retcode, Errorstring);
        goto ex;
      }
    }

    if (Mode != MODE_T2)
    {
      retcode = MH_SetBinning(dev[n], Binning);
      if (retcode < 0)
      {
        MH_GetErrorString(Errorstring, retcode);
        printf("\nMH_SetBinning error %d (%s). Aborted.\n", retcode, Errorstring);
        goto ex;
      }

      retcode = MH_SetOffset(dev[n], Offset);
      if (retcode<0)
      {
        MH_GetErrorString(Errorstring, retcode);
        printf("\nMH_SetOffset error %d (%s). Aborted.\n", retcode, Errorstring);
        goto ex;
      }
    }

    retcode = MH_GetResolution(dev[n], &Resolution);
    if (retcode<0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_GetResolution error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }
    printf("\nResolution is %1.0lfps\n", Resolution);

  }

  // After Init allow 150 ms for valid count rate readings
  // Subsequently you get new values after every 100ms
  Sleep(150);

  for(n = 0; n < NDEVICES; n++)
  {
    printf("\nMeasuring input rates...\n");

    retcode = MH_GetSyncRate(dev[n], &Syncrate);
    if (retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_GetSyncRate error%d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }
    printf("\nSyncrate[%1d]=%1d/s", n, Syncrate);

    for (i = 0; i < NumChannels; i++) // for all channels
    {
      retcode = MH_GetCountRate(dev[n], i, &Countrate);
      if (retcode<0)
      {
        MH_GetErrorString(Errorstring, retcode);
        printf("\nMH_GetCountRate error %d (%s). Aborted.\n", retcode, Errorstring);
        goto ex;
      }
      printf("\nCountrate[%1d][%1d]=%1d/s", n, i, Countrate);
    }
	printf("\n");
  }  

  //after getting the count rates you can check for warnings
  for(n = 0; n < NDEVICES; n++)
  {
    retcode = MH_GetWarnings(dev[n], &warnings);
    if (retcode<0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_GetWarnings error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }
    if (warnings)
    {
      MH_GetWarningsText(dev[n], warningstext, warnings);
	  printf("\n\nDevice %1d:",n);
      printf("\n\n%s", warningstext);
    }
  }

  printf("\npress RETURN to start");
  getchar();

  printf("\nStarting data collection...\n");

  Progress = 0;
  printf("\nProgress:%12u", Progress);

  //Starting the measurement on multiple devices via software will inevitably
  //introduce some ms of delay, so you cannot rely on an exact agreement
  //of the starting points of the TTTR streams. If you need this, you will 
  //have to use hardware synchronization.
  for(n = 0; n < NDEVICES; n++)
  {
    retcode = MH_StartMeas(dev[n], Tacq);
    if (retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_StartMeas error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }
    done[n]=0;
  }

  while (1) //the overall measurement loop
  {
    // In this demo we loop over NDEVICES to fetch the data.
	// For efficiency this should be done in parallel
    for(n = 0; n < NDEVICES; n++) 
    {
      retcode = MH_GetFlags(dev[n], &flags);
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

      retcode = MH_ReadFiFo(dev[n], buffer[n], &nRecords);	//may return less!  
      if (retcode < 0)
      {
        MH_GetErrorString(Errorstring, retcode);
        printf("\nMH_ReadFiFo error %d (%s). Aborted.\n", retcode, Errorstring);
        goto stoptttr;
      }

      if (nRecords)
      {
        if(fwrite(buffer[n], 4, nRecords, fpout[n]) != (unsigned)nRecords)
        {
          printf("\nfile write error\n");
          goto stoptttr;
        }
        Progress += nRecords;
        if(n == NDEVICES-1)
        {
           printf("\b\b\b\b\b\b\b\b\b\b\b\b%12u", Progress);
           fflush(stdout);
        }
      }
      else
      {
        retcode = MH_CTCStatus(dev[n], &ctcstatus);
        if (retcode < 0)
        {
          MH_GetErrorString(Errorstring, retcode);
          printf("\nMH_CTCStatus error %d (%s). Aborted.\n", retcode, Errorstring);
          goto ex;
        }
        if (ctcstatus)
        {
          done[n] = 1;
          alldone = 0;
          for( j = 0; j < NDEVICES; j++)
            alldone += done[j];
          if(alldone == NDEVICES)
          {
            printf("\nDone\n"); 
            goto stoptttr; 
          }
        }
		//here you can also read the count rates if needed.
      }
    }
  }

stoptttr:

  for(n = 0; n < NDEVICES; n++)
  {
    retcode = MH_StopMeas(dev[n]);
    if (retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_StopMeas error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }
  }

ex:

  for (i = 0; i < MAXDEVNUM; i++) //no harm to close all
  {
    MH_CloseDevice(i);
  }

  for(n = 0; n < NDEVICES; n++)
  {
    if (fpout[n])
      fclose(fpout[n]);
  }

  printf("\npress RETURN to exit");
  getchar();

  return 0;
}


