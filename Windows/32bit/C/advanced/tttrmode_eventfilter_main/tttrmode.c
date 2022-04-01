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

  - MinGW 2.0.0 (Windows 32 bit)
  - MinGW-W64 4.3.5 (Windows 64 bit)
  - MS Visual C++ 6.0 (Windows 32 bit)
  - MS Visual C++ 2015 and 2019 (Windows 32 and 64 bit)
  - gcc 7.5.0 and 9.3.0 (Linux 64 bit)

************************************************************************/

#ifndef _WIN32
#include <unistd.h>
#define Sleep(msec) usleep(msec*1000)
#define uint64_t unsigned long long
#else
#include <windows.h>
#include <dos.h>
#include <conio.h>
#define uint64_t  unsigned __int64
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mhdefin.h"
#include "mhlib.h"
#include "errorcodes.h"


FILE *fpout;
uint64_t oflcorrection = 0;
double Resolution = 0; // in ps
double Syncperiod = 0; // in s

unsigned int buffer[TTREADMAX];




//Got PhotonT2
//  TimeTag: Overflow-corrected arrival time in units of the device's base resolution 
//  Channel: Channel the photon arrived (0 = Sync channel, 1..N = regular timing channel)
void GotPhotonT2(uint64_t TimeTag, int Channel)
{
  fprintf(fpout,"CH %2d %14.0lf\n", Channel, TimeTag * Resolution); 
}


//Got MarkerT2
//  TimeTag: Overflow-corrected arrival time in units of the device's base resolution 
//  Markers: Bitfield of arrived markers, different markers can arrive at same time (same record)
void GotMarkerT2(uint64_t TimeTag, int Markers)
{
  fprintf(fpout,"MK %2d %14.0lf\n", Markers, TimeTag * Resolution);
}


//Got PhotonT3
//  NSync: Overflow-corrected arrival time in units of the sync period 
//  DTime: Arrival time of photon after last Sync event in units of the chosen resolution (set by binning)
//  Channel: 1..N where N is the numer of channels the device has
void GotPhotonT3(uint64_t NSync, int Channel, int DTime)
{
  //Syncperiod is in seconds
  fprintf(fpout,"CH %2d %10.8lf %8.0lf\n", Channel, NSync * Syncperiod, DTime * Resolution);
}


//Got MarkerT3
//  NSync: Overflow-corrected arrival time in units of the sync period 
//  Markers: Bitfield of arrived Markers, different markers can arrive at same time (same record)
void GotMarkerT3(uint64_t NSync, int Markers)
{
  //Syncperiod is in seconds
  fprintf(fpout,"MK %2d %10.8lf\n", Markers, NSync * Syncperiod);
}


// HydraHarpV2 or TimeHarp260 or MultiHarp T2 record data
void ProcessT2(unsigned int TTTRRecord)
{
  int ch;
  uint64_t truetime;
  const int T2WRAPAROUND_V2 = 33554432;
  
  union
  {
    unsigned allbits;
    struct{ 
        unsigned timetag  :25;
        unsigned channel  :6;
        unsigned special  :1; // or sync, if channel==0
        } bits;
  } T2Rec;
  
  T2Rec.allbits = TTTRRecord;
  
  if(T2Rec.bits.special==1)
  {
    if(T2Rec.bits.channel==0x3F) //an overflow record
    {
       //number of overflows is stored in timetag
       oflcorrection += (uint64_t)T2WRAPAROUND_V2 * T2Rec.bits.timetag;    
    }
    if((T2Rec.bits.channel>=1)&&(T2Rec.bits.channel<=15)) //markers
    {
      truetime = oflcorrection + T2Rec.bits.timetag;
      //Note that actual marker tagging accuracy is only some ns.
      ch = T2Rec.bits.channel;
      GotMarkerT2(truetime, ch);
    }
    if(T2Rec.bits.channel==0) //sync
    {
      truetime = oflcorrection + T2Rec.bits.timetag;
      ch = 0; //we encode the Sync channel as 0
      GotPhotonT2(truetime, ch); 
    }
  }
  else //regular input channel
  {
    truetime = oflcorrection + T2Rec.bits.timetag;
    ch = T2Rec.bits.channel + 1; //we encode the regular channels as 1..N
    GotPhotonT2(truetime, ch); 
  }
}

// HydraHarpV2 or TimeHarp260 or MultiHarp T3 record data
void ProcessT3(unsigned int TTTRRecord)
{
  int ch, dt;
  uint64_t truensync;
  const int T3WRAPAROUND = 1024;

  union {
    unsigned allbits;
    struct {
      unsigned nsync    :10;  // numer of sync period
      unsigned dtime    :15;  // delay from last sync in units of chosen resolution
      unsigned channel  :6;
      unsigned special  :1;
    } bits;
  } T3Rec;
  
  T3Rec.allbits = TTTRRecord;
  
  if(T3Rec.bits.special==1)
  {
    if(T3Rec.bits.channel==0x3F) //overflow
    {
       //number of overflows is stored in nsync
       oflcorrection += (uint64_t)T3WRAPAROUND * T3Rec.bits.nsync;
    }
    if((T3Rec.bits.channel>=1)&&(T3Rec.bits.channel<=15)) //markers
    {
      truensync = oflcorrection + T3Rec.bits.nsync;
      //the time unit depends on sync period
      GotMarkerT3(truensync, T3Rec.bits.channel);
    }
  }
  else //regular input channel
    {
      truensync = oflcorrection + T3Rec.bits.nsync;
      ch = T3Rec.bits.channel + 1; //we encode the input channels as 1..N
      dt = T3Rec.bits.dtime;
      //truensync indicates the number of the sync period this event was in
      //the dtime unit depends on the chosen resolution (binning)
      GotPhotonT3(truensync, ch, dt);
    }
}




int main(int argc, char* argv[])
{

  int dev[MAXDEVNUM];
  int found = 0;
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
  int Binning = 4; //you can change this, meaningful only in T3 mode
  int Offset = 0;  //you can change this, meaningful only in T3 mode
  int Tacq = 1000; //Measurement time in millisec, you can change this
  int SyncDivider = 1; //you can change this, observe Mode! READ MANUAL!

  int SyncTiggerEdge = 0; //you can change this
  int SyncTriggerLevel = -50; //you can change this
  int InputTriggerEdge = 0; //you can change this
  int InputTriggerLevel = -50; //you can change this

  int Syncrate;
  int Countrate;
  int i;
  int flags;
  int warnings;
  char warningstext[16384]; //must have 16384 bytest text buffer
  int nRecords;
  unsigned int Progress;
  int stopretry = 0;

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
  #define MAXROWS 8                  // largest possible number of input rows
  int inputrows;                     // actual number of rows, we determine this later 
  int mainfilter_timerange = 1000;   // in picoseconds
  int mainfilter_matchcnt = 1;       // must have at least one other event in proximity
  int mainfilter_inverse = 0;        // normal filtering mode, see manual
  int mainfilter_enable = 1;         // activate the filter
  int mainfilter_usechans[MAXROWS]   // bitmasks for which channels are to be used
      = {0xF,0,0,0,0,0,0,0};         // we use only the first four channels
  int mainfilter_passchans[MAXROWS]  // bitmasks for which channels to pass unfiltered
      = {0,0,0,0,0,0,0,0};           // we do not pass any channels unfiltered
  //the following are count rate buffers for the filter test further down
  int ftestsyncrate;
  int ftestchanrates[MAXINPCHAN];
  int ftestsumrate;


  printf("\nMultiHarp MHLib Demo Application                      PicoQuant GmbH, 2022");
  printf("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
  MH_GetLibraryVersion(LIB_Version);
  printf("\nLibrary version is %s\n", LIB_Version);
  if (strncmp(LIB_Version, LIB_VERSION, sizeof(LIB_VERSION)) != 0)
  {
    printf("\nWarning: The application was built for version %s.", LIB_VERSION);
  }

  if ((fpout = fopen("tttrmodeout.txt", "w")) == NULL)
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

  retcode = MH_SetSyncChannelOffset(dev[0], 0); //in ps, emulate a cable delay
  if (retcode<0)
  {
   MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_SetSyncChannelOffset error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  for (i = 0; i < NumChannels; i++) // we use the same input settings for all channels
  {
    retcode = MH_SetInputEdgeTrg(dev[0], i, InputTriggerLevel, InputTriggerEdge);
    if (retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_SetInputEdgeTrg error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }

    retcode =MH_SetInputChannelOffset(dev[0], i, 0);  //in ps, emulate a cable delay
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


  // here we program the Main Filter 
  inputrows = NumChannels/8; // a MultiHarp has 8 channels per row
  if(NumChannels==4)         // except it is a 4-channel model  
      inputrows = 1;

  for (i = 0; i < inputrows; i++)
  {
    retcode = MH_SetMainEventFilterChannels(dev[0], i, mainfilter_usechans[i], mainfilter_passchans[i]);
    if (retcode<0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_SetMainEventFilterChannels error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }
  }

  retcode = MH_SetMainEventFilterParams(dev[0], mainfilter_timerange, mainfilter_matchcnt, mainfilter_inverse);
  if (retcode<0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_SetMainEventFilterParams error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  retcode = MH_EnableMainEventFilter(dev[0], mainfilter_enable);
  if (retcode<0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_EnableMainEventFilter error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }
  // Filter programming ends here


  printf("\nMeasuring input rates...\n");

  // After Init allow 150 ms for valid  count rate readings
  // Subsequently you get new values after every 100ms
  // The same applies to the filter test below.
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

  retcode = MH_SetFilterTestMode(dev[0], 1); //disable FiFo input
  if (retcode<0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_SetFilterTestMode error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  retcode = MH_StartMeas(dev[0], ACQTMAX); //longest possible time, we will stop manually
  if (retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_StartMeas error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  Sleep(150); //allow the hardware at least 100ms time for rate counting 

  /*
  To start with, we retrieve the front end count rates. This is somewhat redundant 
  here as we already retrieved them above. However, for demonstration purposes, 
  this time we use a more efficient method that fetches all rates in one go.
  */
  retcode = MH_GetAllCountRates(dev[0], &ftestsyncrate, ftestchanrates);
  if (retcode<0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_GetRowFilteredRates error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }
  //We only care about the overall rates, so we sum them up here.
  ftestsumrate = 0;
  for (i = 0; i < NumChannels; i++)
	ftestsumrate += ftestchanrates[i];
  if (Mode == MODE_T2) //in this case also add the sync rate
    ftestsumrate += ftestsyncrate;
  printf("\nFront end input rate=%1d/s", ftestsumrate);

  /*
  Although we are not using the Row Filter here, it is useful to retrieve its outout 
  rates as it is the input to the Main Filter. This is not necessarily the same as
  the front end count rates as there may already have been losses due to front end 
  troughput limits. We do the same summation as above.
  */
  retcode = MH_GetRowFilteredRates(dev[0], &ftestsyncrate, ftestchanrates);
  if (retcode<0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_GetRowFilteredRates error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }
  ftestsumrate = 0;
  for (i = 0; i < NumChannels; i++)
	ftestsumrate += ftestchanrates[i];
  if (Mode == MODE_T2) //in this case also add the sync rate
    ftestsumrate += ftestsyncrate;
  printf("\nMain Filter input rate=%1d/s", ftestsumrate);
  
  //Now we do the same rate retrieval and summation for the Main Filter output.
  retcode = MH_GetMainFilteredRates(dev[0], &ftestsyncrate, ftestchanrates);
  if (retcode<0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_GetRowFilteredRates error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }
  ftestsumrate = 0;
  for (i = 0; i < NumChannels; i++)
	ftestsumrate += ftestchanrates[i];
  if (Mode == MODE_T2) //in this case also add the sync rate
    ftestsumrate += ftestsyncrate;
  printf("\nMain Filter output rate=%1d/s", ftestsumrate);

  
  retcode = MH_StopMeas(dev[0]); //test finished, stop measurement
  if (retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_StopMeas error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  //Testmode must be switched off again to allow a real measurement
  retcode = MH_SetFilterTestMode(dev[0], 0); //re-enable FiFo input
  if (retcode<0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_SetFilterTestMode error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  // here we begin the real measurement
  
  if (Mode == MODE_T2)
    fprintf(fpout,"ev chn       time/ps\n\n"); //column heading for T2 mode
  else
    fprintf(fpout,"ev chn  ttag/s   dtime/ps\n\n");  //column heading for T3 mode

  printf("\npress RETURN to start");
  getchar();

  retcode = MH_StartMeas(dev[0], Tacq);
  if (retcode < 0)
  {
    MH_GetErrorString(Errorstring, retcode);
    printf("\nMH_StartMeas error %d (%s). Aborted.\n", retcode, Errorstring);
    goto ex;
  }

  if (Mode == MODE_T3)
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
    retcode = MH_GetSyncPeriod(dev[0], &Syncperiod);
    if (retcode<0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_GetSyncPeriod error %d (%s). Aborted.\n", retcode, Errorstring);
      goto ex;
    }
    printf("\nSync period is %lf ns\n", Syncperiod * 1e9);
  }

  printf("\nStarting data collection...\n");

  Progress = 0;
  printf("\nProgress:%12u", Progress);

  oflcorrection = 0;

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

    retcode = MH_ReadFiFo(dev[0], buffer, &nRecords);   //may return less!  
    if (retcode < 0)
    {
      MH_GetErrorString(Errorstring, retcode);
      printf("\nMH_ReadFiFo error %d (%s). Aborted.\n", retcode, Errorstring);
      goto stoptttr;
    }

    if (nRecords)
    {
      // Here we process the data. Note that the time this consumes prevents us
      // from getting around the loop quickly for the next Fifo read.
      // In a serious performance critical scenario you would write the data to
      // a software queue and do the processing in another thread reading from 
      // that queue.

      if (Mode == MODE_T2)
        for (i = 0; i < nRecords; i++)
          ProcessT2(buffer[i]);
      else
        for (i = 0; i < nRecords; i++)
          ProcessT3(buffer[i]);

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
        stopretry++; //do a few more rounds as there might be some more in the FiFo
        if(stopretry>5) 
        {
          printf("\nDone\n");
          goto stoptttr;
        }
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


