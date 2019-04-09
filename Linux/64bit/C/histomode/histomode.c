/************************************************************************

  Demo access to MultiHarp 150 Hardware via MHLIB v 1.0
  The program performs a measurement based on hardcoded settings.
  The resulting histogram is stored in an ASCII output file.

  PicoQuant GmbH, Sept. 2018

  Note: This is a console application (i.e. run in Windows cmd box)

  Note: At the API level channel numbers are indexed 0..N-1 
    where N is the number of channels the device has.

  Tested with the following compilers:

  - MinGW 2.0.0 (Windows 32 bit)
  - MinGW-W64 4.3.5 (Windows 64 bit)
  - MS Visual C++ 6.0 (Windows 32 bit)
  - MS Visual C++ 2013 and 2015 (Windows 32 and 64 bit)
  - gcc 4.8.3 (Linux 32 and 64 bit)

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


unsigned int counts[MAXINPCHAN][MAXHISTLEN];


int main(int argc, char* argv[])
{
  int dev[MAXDEVNUM];
  int found=0;
  FILE *fpout;
  int retcode;
  int ctcstatus;
  char LIB_Version[8];
  char HW_Model[32];
  char HW_Partno[8];
  char HW_Version[16];
  char HW_Serial[32];
  char Errorstring[40];
  int NumChannels;
  int HistLen;
  int Binning=0; //you can change this
  int Offset=0; 
  int Tacq=1000; //Measurement time in millisec, you can change this
  int SyncDivider = 1; //you can change this

  int SyncTiggerEdge = 0; //you can change this
  int SyncTriggerLevel = -50; //you can change this
  int InputTriggerEdge = 0; //you can change this
  int InputTriggerLevel = -50; //you can change this
 
  double Resolution; 
  int Syncrate;
  int Countrate;
  double Integralcount; 
  int i,j;
  int flags;
  int warnings;
  char warningstext[16384]; //must have 16384 bytest text buffer
  char cmd=0;

  memset(Errorstring, 0x00, sizeof(Errorstring));
  memset(warningstext, 0x00, sizeof(warningstext));

  printf("\nMultiHarp 150 MHLib Demo Application               PicoQuant GmbH, 2018");
  printf("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
  MH_GetLibraryVersion(LIB_Version);
  printf("\nLibrary version is %s", LIB_Version);
  if(strncmp(LIB_Version, LIB_VERSION, sizeof(LIB_VERSION)) != 0)
  {
    printf("\nWarning: The application was built for version %s.", LIB_VERSION);
  }

  if((fpout = fopen("histomode.out", "w")) == NULL)
  {
    printf("\ncannot open output file\n"); 
    goto ex;
  }

  printf("\nSearching for MultiHarp devices...");
  printf("\nDevidx     Serial     Status");


  for(i = 0; i < MAXDEVNUM; i++)
  {
    memset(HW_Serial, 0x00, sizeof(HW_Serial));
    retcode = MH_OpenDevice(i, HW_Serial); 
    if(retcode == 0) //Grab any device we can open
    {
      printf("\n  %1d        %7s    open ok", i, HW_Serial);
      dev[found] = i; //keep index to devices we want to use
      found++;
    }
    else
    {
      if(retcode == MH_ERROR_DEVICE_OPEN_FAIL)
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

  if(found < 1)
  {
    printf("\nNo device available.");
    goto ex; 
  }

  printf("\nUsing device #%1d", dev[0]);

  fprintf(fpout, "Binning           : %ld\n", Binning);
  fprintf(fpout, "Offset            : %ld\n", Offset);
  fprintf(fpout, "AcquisitionTime   : %ld\n", Tacq);
  fprintf(fpout, "SyncDivider       : %ld\n", SyncDivider);

  printf("\nInitializing the device...");

  retcode = MH_Initialize(dev[0], MODE_HIST, 0);  //Histo mode with internal clock
  if(retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_Initialize error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  retcode = MH_GetHardwareInfo(dev[0], HW_Model, HW_Partno, HW_Version); 
  if(retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_GetHardwareInfo error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }
  else
  {
    printf("\nFound Model %s Part no %s Version %s",HW_Model, HW_Partno, HW_Version);
  }

  if (strstr(HW_Model, "MultiHarp 150") != NULL)
  {
    fprintf(fpout, "Hardware model %s \n", HW_Model);
  }
  else
  {
    printf("\nUnknown hardware model %s. Aborted.\n", HW_Model);
    goto ex;
  }
  
  retcode = MH_GetNumOfInputChannels(dev[0], &NumChannels);
  if(retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_GetNumOfInputChannels error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }
  else
  {
    printf("\nDevice has %i input channels.", NumChannels);
  }

  retcode = MH_SetSyncDiv(dev[0], SyncDivider);
  if(retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_SetSyncDiv error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  retcode = MH_SetSyncEdgeTrg(dev[0], SyncTriggerLevel, SyncTiggerEdge);
  if (retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_SetSyncEdgeTrg error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  retcode = MH_SetSyncChannelOffset(dev[0], 0);
  if(retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_SetSyncChannelOffset error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  for(i = 0; i < NumChannels; i++) // we use the same input offset for all channels
  {
    retcode = MH_SetInputEdgeTrg(dev[0], i, InputTriggerLevel, InputTriggerEdge);
    if (retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_SetInputEdgeTrg error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }

    retcode = MH_SetInputChannelOffset(dev[0], i, 0);
    if(retcode < 0)
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

  retcode = MH_SetHistoLen(dev[0], MAXLENCODE, &HistLen);
  if(retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_SetHistoLen error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }
  printf("\nHistogram length is %d", HistLen);

  retcode = MH_SetBinning(dev[0], Binning);
  if(retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_SetBinning error %d (%s). Aborted.\n",retcode,Errorstring);
    goto ex;
  }

  retcode = MH_SetOffset(dev[0], Offset);
  if(retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_SetOffset error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }
 
  retcode = MH_GetResolution(dev[0], &Resolution);
  if(retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_GetResolution error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  printf("\nResolution is %1.0lfps\n", Resolution);


  // After Init allow 150 ms for valid  count rate readings
  // Subsequently you get new values after every 100ms
  Sleep(150);


  retcode = MH_GetSyncRate(dev[0], &Syncrate);
  if(retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_GetSyncRate error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }
  printf("\nSyncrate=%1d/s", Syncrate);

  for(i = 0; i < NumChannels; i++) // for all channels
  {
    retcode = MH_GetCountRate(dev[0], i, &Countrate);
    if(retcode < 0)
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
  if(retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_GetWarnings error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  if(warnings)
  {
    MH_GetWarningsText(dev[0], warningstext, warnings);
    printf("\n\n%s", warningstext);
  }

  retcode = MH_SetStopOverflow(dev[0], 0, 10000); //for example only
  if(retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_SetStopOverflow error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  while(cmd != 'q')
  {
    MH_ClearHistMem(dev[0]);
    if(retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_ClearHistMem error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }

    printf("\npress RETURN to start measurement");
    getchar();

    retcode = MH_GetSyncRate(dev[0], &Syncrate);
    if(retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_GetSyncRate error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }
    printf("\nSyncrate=%1d/s", Syncrate);

    for(i = 0; i < NumChannels; i++) // for all channels
    {
      retcode = MH_GetCountRate(dev[0], i, &Countrate);
      if(retcode < 0)
      {
        MH_GetErrorString(Errorstring, retcode);
        printf("\nMH_GetCountRate error %d (%s). Aborted.\n", retcode, Errorstring);
        goto ex;
      }
      printf("\nCountrate[%1d]=%1d/s", i, Countrate);
    }

    //here you could check for warnings again
        
    retcode = MH_StartMeas(dev[0], Tacq); 
    if(retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_StartMeas error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }
         
    printf("\n\nMeasuring for %1d milliseconds...", Tacq);
        
    ctcstatus = 0;
    while(ctcstatus == 0)
    {
      retcode = MH_CTCStatus(dev[0], &ctcstatus);
      if(retcode < 0)
      {
        MH_GetErrorString(Errorstring, retcode);
        printf("\nMH_CTCStatus error %d (%s). Aborted.\n", retcode, Errorstring);
        goto ex;
      }
    }

    retcode = MH_StopMeas(dev[0]);
    if(retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_StopMeas error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }

    printf("\n");
    for(i = 0; i< NumChannels; i++) // for all channels
    {
      retcode = MH_GetHistogram(dev[0], counts[i], i);
      if(retcode < 0)
      {
        MH_GetErrorString(Errorstring, retcode);
        printf("\nMH_GetHistogram error %d (%s). Aborted.\n", retcode, Errorstring);
        goto ex;
      }

      Integralcount = 0;
      for(j = 0; j < HistLen; j++)
      {
        Integralcount += counts[i][j];
      }


      printf("\n  Integralcount[%1d]=%1.0lf", i, Integralcount);

    }
    printf("\n");

    retcode = MH_GetFlags(dev[0], &flags);
    if(retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_GetFlags error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }

    if(flags & FLAG_OVERFLOW)
    {
      printf("\n  Overflow.");
    }

    printf("\nEnter c to continue or q to quit and save the count data.");
    cmd = getchar();
    getchar();
  }

  for(j = 0; j < HistLen; j++)
  {
    for(i = 0; i < NumChannels; i++)
    {
      fprintf(fpout, "%5d ", counts[i][j]);
    }
    fprintf(fpout, "\n");
  }

  ex:
  for(i = 0; i < MAXDEVNUM; i++) //no harm to close all
  {
    MH_CloseDevice(i);
  }
  if(fpout)
  {
    fclose(fpout);
  }
  printf("\npress RETURN to exit");
  getchar();

  return 0;
}


