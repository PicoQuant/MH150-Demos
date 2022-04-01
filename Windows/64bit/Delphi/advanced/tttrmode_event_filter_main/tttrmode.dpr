{
  MultiHarp 150/160  MHLIB v3.1  Usage Demo with Delphi or Lazarus

  The program performs a TTTR measurement based on hardcoded settings.
  The resulting event data is stored in a ASCII output file.

  Axel Hagen, PicoQuant GmbH, May 2018
  Marcus Sackrow, PicoQuant GmbH, July 2019
  Michael Wahl, PicoQuant GmbH, May 2020, March 2021
  Stefan Eilers, PicoQuant GmbH, March 2022; Review PAT, March 2022

  Tested with
   - Delphi 11.0 on Windows 10
   - Lazarus 2.0.12 / fpc 3.2.0 on Windows 10

  Note: This is a console application (i.e. run in Windows cmd box)
  Note: At the API level channel numbers are indexed 0..N-1
        where N is the number of channels the device has.
  Note: This demo writes only raw event data to the output file.
        It does not write a file header as regular .ptu files have it.
}

program tttrmode;

{$IF defined(MSWINDOWS)}
  {$APPTYPE CONSOLE}  //windows needs this, Linux does not want it
{$ENDIF}

uses
  {$ifdef fpc}
  SysUtils,
  {$else}
  System.SysUtils,
  System.Ansistrings,
  {$endif}
  MHLib in 'mhlib.pas';


const
  // for proper columns choose this
  //{
  COLWIDTH_I64            =        21;
  COLWIDTH_WORD           =         6;
  //}
  // for lesser amount of data choose this
  {
  COLWIDTH_I64            =         0;
  COLWIDTH_WORD           =         0;
  //}

  //main eventfilter constant
  MAXROWS                 =         8;    // largest possible number of input rows

var
  RetCode           : LongInt;
  OutputFile        : TextFile;
  i                 : Integer;
  Found             : Integer =       0;
  Progress          : LongInt =       0;
  FiFoFull          : Boolean =   False;
  TimeOut           : Boolean =   False;
  FileError         : Boolean =   False;


  Mode              : LongInt =      MODE_T3; // set T2 or T3 here, observe suitable Syncdivider and Range!
  Binning           : LongInt =            4; // you can change this (meaningless in T2 mode)
  Offset            : LongInt =            0; // normally no need to change this
  TAcq              : LongInt =         250;   // you can change this, unit is millisec
  SyncDivider       : LongInt =            1; // you can change this
  SyncTrgEdge       : LongInt = EDGE_FALLING; // you can change this
  SyncTrgLevel      : LongInt =          -50; // you can change this (mV)
  SyncChannelOffset : LongInt =            0; // in ps, you can change this (like a cable delay)
  InputTrgEdge      : LongInt = EDGE_FALLING; // you can change this
  InputTrgLevel     : LongInt =          -50; // you can change this (mV)
  InputChannelOffset: LongInt =        50000; // in ps, you can change this (like a cable delay)

  NumChannels       : LongInt;
  ChanIdx           : LongInt;
  Resolution        : Double;
  SyncRate          : LongInt;
  CountRate         : LongInt;
  CTCStatus         : LongInt;
  Flags             : LongInt;
  Records           : LongInt;
  Warnings          : LongInt;

  Buffer            : array[0..TTREADMAX - 1] of LongWord;
  OflCorrection     : Int64 = 0;
  SyncPeriod        : Double = 0;

  {
  Main Event Filter variables
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
  }
  InputRows            : LongInt;  // actual number of rows, we determine this later
  mainfilter_timerange : LongInt = 10000;      // in picoseconds
  mainfilter_matchcnt  : LongInt = 1;         // if 1: there must be 2 or more events to pass
  mainfilter_inverse   : LongInt = 0;         // normal filtering mode, see manual
  mainfilter_enable    : LongInt = 1;         // activate the filter with 1

  mainfilter_usechans  : array[0..MAXROWS - 1] of LongInt = ($F, 0, 0, 0, 0, 0, 0, 0);   // [0..MAXROWS-1]bitmasks for which channels are to be used
                                                                                // we use only the first four channels
  mainfilter_passchans : array[0..MAXROWS - 1] of LongInt = (0, 0, 0, 0, 0, 0, 0, 0);   // bitmasks for which channels to pass unfiltered
                                                                               // we do not pass any channels unfiltered
  //the following are count rate buffers for the filter test further down
  FTestSyncRate        : LongInt;
  FTestChanRates       : array[0..MAXINPCHAN - 1] of LongInt;
  FTestSumRate         : LongInt;

// procedures for Photon, Marker

//GotPhotonT2 procedure
//  TimeTag: Raw TimeTag from Record * Resolution = Real Time arrival of Photon
procedure GotPhotonT2(TimeTag: Int64; Channel: Integer);
begin
  Writeln(OutputFile, 'CH ', Channel, ' ', Round(TimeTag * Resolution));
end;

//GotPhotonT3 procedure
//  DTime: Arrival time of Photon after last Sync event (T3 only) DTime * Resolution = Real time arrival of Photon after last Sync event
//  Channel: Channel the Photon arrived (0 = Sync channel for T2 measurements)
procedure GotPhotonT3(NSync: Int64; DTime: Integer; Channel: Integer);
begin
  Writeln(OutputFile, 'CH ', Channel, ' ', (NSync * SyncPeriod):3:9, ' ', Round(DTime * Resolution)); //NSync * SyncPeriod/s
end;

//GotMarker
//  TimeTag: Raw TimeTag from Record * Global resolution = Real Time arrival of Marker
//  Markers: Bitfield of arrived Markers, different markers can arrive at same time (same record)
procedure GotMarker(TimeTag: Int64; Markers: Integer);
begin
  Writeln(OutputFile, ' MAR ', TimeTag, ' ', Markers);
end;

//ProcessT2 procedure
//HydraHarpV2 (Version 2) or TimeHarp260 or MultiHarp record data
procedure ProcessT2(TTTR_RawData: Cardinal);
const
  T2WRAPAROUND_V2 = 33554432;
type
  TT2DataRecords = record
    Special: Boolean;
    Channel: Byte;
    TimeTag: Cardinal;
  end;
var
  TTTR_Data: TT2DataRecords;
  TrueTime: Cardinal;
begin
  {split "RawData" into its parts}
  TTTR_Data.TimeTag := Cardinal(TTTR_RawData and $01FFFFFF); // 25 bit of 32 bit for TimeTag
  TTTR_Data.Channel := Byte((TTTR_RawData shr 25) and $0000003F); // 6 bit of 32 bit for Channel
  TTTR_Data.Special := Boolean((TTTR_RawData shr 31) and $00000001); // 1 bit of 32 bit for Special
  if TTTR_Data.Special then                  // this means we have a Special record
    case TTTR_Data.Channel of
      $3F:        // overflow
        begin
          // number of overflows is stored in timetag
          OflCorrection := OflCorrection + T2WRAPAROUND_V2 * TTTR_Data.TimeTag;
        end;
      1..15:   // markers
        begin
          TrueTime := OflCorrection + TTTR_Data.TimeTag;
          // Note that actual marker tagging accuracy is only some ns.
          GotMarker(TrueTime, TTTR_Data.Channel);
        end;
      0: //sync
        begin
          TrueTime := OflCorrection + TTTR_Data.TimeTag;
          GotPhotonT2(TrueTime,
            0 //we encode the sync channel as 0
            );
        end;
    end
  else
  begin // it is a regular photon record
    TrueTime := OflCorrection + TTTR_Data.TimeTag;
    GotPhotonT2(TrueTime,
      TTTR_Data.Channel + 1 //we encode the regular channels as 1..N
      );
  end;
end;

//ProcessT3 procedure
//HydraHarp or TimeHarp260 or MultiHarp record data
procedure ProcessT3(TTTR_RawData: Cardinal);
const
  T3WRAPAROUND = 1024;
type
  TT3DataRecords = record
    Special: Boolean;
    Channel: Byte;
    DTime: Word;
    NSync: Word;
  end;
var
  TTTR_Data: TT3DataRecords;
  TrueSync: Integer;
begin
  {split "RawData" into its parts}
  TTTR_Data.NSync := Word(TTTR_RawData and $000003FF); // 10 bit of 32 bit for NSync
  TTTR_Data.DTime := Word((TTTR_RawData shr 10) and $00007FFF); // 15 bit of 32 bit for DTime
  TTTR_Data.Channel := Byte((TTTR_RawData shr 25) and $0000003F); // 6 bit of 32 bit for Channel
  TTTR_Data.Special := Boolean((TTTR_RawData shr 31) and $00000001); // 1 bit of 32 bit for Special
  if TTTR_Data.Special then                  // this means we have a Special record
    case TTTR_Data.Channel of
      $3F:        // overflow
        begin
          // number of overflows is stored in timetag
          // if it is zero, it is an old style single overflow {should never happen with new Firmware}
          if TTTR_Data.NSync = 0 then
            OflCorrection := OflCorrection + T3WRAPAROUND
          else
            OflCorrection := OflCorrection + T3WRAPAROUND * TTTR_Data.NSync;
        end;
      1..15:   // markers
        begin
          TrueSync := OflCorrection + TTTR_Data.NSync; //the time unit depends on sync period
          // Note that actual marker tagging accuracy is only some ns.
          GotMarker(TrueSync, TTTR_Data.Channel);
        end;
    end
  else
  begin // it is a regular photon record
    TrueSync := OflCorrection + TTTR_Data.NSync;
    //truensync indicates the number of the sync period this event was in

    GotPhotonT3(TrueSync,
      TTTR_Data.DTime, //the dtime unit depends on the chosen resolution (binning)
      TTTR_Data.Channel + 1 //we encode the regular channels as 1..N
      );
  end;
end;

procedure Ex(RetCode: Integer);
begin
  if RetCode <> MH_ERROR_NONE then
  begin
    MH_GetErrorString(pcErrText, RetCode);
    Writeln('Error ', RetCode:3, ' = "', Trim(string(strErrText)), '"');
  end;
  Writeln;
  {$I-}
    CloseFile(OutputFile);
    IOResult();
  {$I+}
  Writeln('press RETURN to exit');
  Readln;
  Halt(RetCode);
end;

//main procedure
begin
  Writeln;
  Writeln('MultiHarp  MHLib  Usage Demo                        PicoQuant GmbH, 2022');
  Writeln('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
  RetCode := MH_GetLibraryVersion(pcLibVers);
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_GetLibraryVersion error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;
  Writeln('MHLIB version is ' + strLibVers);
  if Trim(AnsiString(strLibVers)) <> Trim(AnsiString (LIB_VERSION)) then
    Writeln('Warning: The application was built for version ' + LIB_VERSION);

  AssignFile(OutputFile, 'tttrmodeout.txt');
  {$I-}
    Rewrite(OutputFile);
  {$I+}
  if IOResult <> 0 then
  begin
    Writeln('cannot open output file');
    Ex(MH_ERROR_NONE);
  end;

  Writeln;
  Writeln('Searching for MultiHarp devices...');
  Writeln('Devidx     Serial     Status');

  for i := 0 to MAXDEVNUM - 1 do
  begin
    RetCode := MH_OpenDevice(i, pcHWSerNr);
    //
    case RetCode of
      MH_ERROR_NONE:
        begin
          // Grab any MultiHarp we can open
          DevIdx[Found] := i; // keep index to devices we want to use
          Inc(Found);
          Writeln('   ', i, '      S/N ', strHWSerNr);
        end;
      MH_ERROR_DEVICE_OPEN_FAIL:
        Writeln('   ', i, '       no device');
      else
        begin
          MH_GetErrorString(pcErrText, RetCode);
          Writeln('   ', i, '       ', Trim(string(strErrText)));
        end;
    end;
  end;

  // in this demo we will use the first MultiHarp device we found,
  // i.e. iDevIdx[0].  You can also use multiple devices in parallel.
  // you could also check for a specific serial number, so that you
  // always know which physical device you are talking to.

  if Found < 1 then
  begin
    Writeln('No device available.');
    Ex(MH_ERROR_NONE);
  end;

  Writeln('Using device ', DevIdx[0]);
  Writeln('Initializing the device...');

  RetCode := MH_Initialize(DevIdx[0], Mode, 0); //with internal clock
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_Initialize error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;

  RetCode := MH_GetHardwareInfo(DevIdx[0], pcHWModel, pcHWPartNo, pcHWVersion); // this is only for information
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_GetHardwareInfo error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end
  else
    Writeln('Found Model ', strHWModel,'  Part no ', strHWPartNo,'  Version ', strHWVersion);

  RetCode := MH_GetNumOfInputChannels(DevIdx[0], NumChannels);
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_GetNumOfInputChannels error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end
  else
    Writeln('Device has ', NumChannels, ' input channels.');

  Writeln;
  Writeln;
  Writeln('Using the following settings:');
  Writeln;
  Writeln('Mode               : ', Mode);
  Writeln('Binning            : ', Binning);
  Writeln('Offset             : ', Offset);
  Writeln('AcquisitionTime    : ', TAcq);
  Writeln('SyncDivider        : ', SyncDivider);
  Writeln('SyncTrgEdge        : ', SyncTrgEdge);
  Writeln('SyncTrgLevel       : ', SyncTrgLevel);
  Writeln('SyncChannelOffset  : ', SyncChannelOffset);
  Writeln('InputTrgEdge       : ', InputTrgEdge);
  Writeln('InputTrgLevel      : ', InputTrgLevel);
  Writeln('InputChannelOffset : ', InputChannelOffset);

  Writeln;

  RetCode := MH_SetSyncDiv(DevIdx[0], SyncDivider);
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_SetSyncDiv error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;

  RetCode := MH_SetSyncEdgeTrg(DevIdx[0], SyncTrgLevel, SyncTrgEdge);
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_SetSyncEdgeTrg error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;

  RetCode := MH_SetSyncChannelOffset(DevIdx[0], SyncChannelOffset);
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_SetSyncChannelOffset error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;

  for ChanIdx := 0 to NumChannels - 1 do // we use the same input settings for all channels
  begin
    RetCode := MH_SetInputEdgeTrg(DevIdx[0], ChanIdx, InputTrgLevel, InputTrgEdge);
    if RetCode <> MH_ERROR_NONE then
    begin
      Writeln('MH_SetInputEdgeTrg channel ', ChanIdx:2, ' error ', RetCode:3, '. Aborted.');
      Ex(RetCode);
    end;

    RetCode := MH_SetInputChannelOffset (DevIdx[0], ChanIdx, InputChannelOffset); //in ps, emulate a cable delay
    if RetCode <> MH_ERROR_NONE then
    begin
      Writeln('MH_SetInputChannelOffset channel ', ChanIdx:2, ' error ', RetCode:3, '. Aborted.');
      Ex(RetCode);
    end;

    RetCode := MH_SetInputChannelEnable(DevIdx[0], ChanIdx, 1);
    if RetCode <> MH_ERROR_NONE then
    begin
      Writeln('MH_SetInputChannelEnable channel ', ChanIdx:2, ' error ', RetCode:3, '. Aborted.');
      Ex(RetCode);
    end;
  end;

  if Mode <> MODE_T2 then                  // These are meaningless in T2 mode
  begin
    RetCode := MH_SetBinning(DevIdx[0], Binning);
    if RetCode <> MH_ERROR_NONE then
    begin
      Writeln('MH_SetBinning error ', RetCode:3, '. Aborted.');
      Ex(RetCode);
    end;

    RetCode := MH_SetOffset(DevIdx[0], Offset);
    if RetCode <> MH_ERROR_NONE then
    begin
      Writeln('MH_SetOffset error ', RetCode:3, '. Aborted.');
      Ex(RetCode);
    end;
  end;

  RetCode := MH_GetResolution (DevIdx[0], Resolution);
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_GetResolution error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;
  Writeln('Resolution is ', Resolution:7:3, 'ps');

  // Main Event Filter
  // here we program the Main Filter
  InputRows := NumChannels div 8; // a MultiHarp has 8 channels per row
  if NumChannels = 4 then     // except it is a 4-channel model
    InputRows := 1;

  for i := 0 to InputRows - 1 do
  begin
    RetCode := MH_SetMainEventFilterChannels(DevIdx[0], i, mainfilter_usechans[i],
      mainfilter_passchans[i]);
    if RetCode <> MH_ERROR_NONE then
    begin
      Writeln('MH_SetMainEventFilterChannels error ', RetCode:3, '. Aborted.');
      Ex(RetCode);
    end;
  end;
  RetCode := MH_SetMainEventFilterParams(DevIdx[0], mainfilter_timerange,
    mainfilter_matchcnt, mainfilter_inverse);
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_SetMainEventFilterParams error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;
  RetCode := MH_EnableMainEventFilter(DevIdx[0], mainfilter_enable);
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_EnableMainEventFilter error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;
  // Filter programming ends here

  Writeln('Measuring input rates...');
  Writeln;

  // After Init or SetSyncDiv you must allow > 150 ms for valid new count rate readings
  // otherwise you get new values after every 100 ms
  // The same applies to the main event filter test below.
  Sleep(150);

  RetCode := MH_GetSyncRate(DevIdx[0], SyncRate);
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_GetSyncRate error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;
  Writeln('SyncRate = ', SyncRate, '/s');

  Writeln;

  for ChanIdx := 0 to NumChannels - 1 do // for all channels
  begin
    RetCode := MH_GetCountRate(DevIdx[0], ChanIdx, CountRate);
    if RetCode <> MH_ERROR_NONE then
    begin
      Writeln('MH_GetCountRate error ', RetCode:3, '. Aborted.');
      Ex(RetCode);
    end;
    Writeln('Countrate [', ChanIdx:2, '] = ', CountRate:8, '/s');
  end;

  Writeln;

  RetCode := MH_GetWarnings(DevIdx[0], Warnings);   //after getting the count rates you can check for warnings
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_GetWarnings error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;

  if Warnings <> 0 then
  begin
    MH_GetWarningsText(DevIdx[0], pcWtext, Warnings);
    Writeln(strWtext);
  end;

  {
  Main Event Filter test
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
  }
  RetCode := MH_SetFilterTestMode(DevIdx[0], 1); //disable FiFo input
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_SetFilterTestMode error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;
  RetCode := MH_StartMeas(DevIdx[0], ACQTMAX); //longest possible time, we will stop manually
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_StartMeas error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;

  Sleep(150); //allow the hardware at least 100ms time for rate counting
  Writeln('');
  {
  To start with, we retrieve the front end count rates. This is somewhat redundant
  here as we already retrieved them above. However, for demonstration purposes,
  this time we use a more efficient method that fetches all rates in one go.
  }
  //We only care about the overall rates, so we sum them up here.
  RetCode := MH_GetAllCountRates(DevIdx[0], FTestSyncRate, FTestChanRates[0]);
    // here fTestChanRates[index] for GetAllCountRates is pointer to first position
    // of the defined array (1 Pointer function input but e.g. 8 values can get read out)
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_GetAllCountRates error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;

  FTestSumRate := 0;
  for i := 0 to NumChannels - 1 do
    FTestSumRate := FTestSumRate + FTestChanRates[i];
  if Mode = MODE_T2 then //in this case also add the sync rate be course it's used as a additional channel
    FTestSumRate := FTestSumRate + FTestSyncRate;

  Writeln('Front end input rate = ', FTestSumRate);
  Writeln('');
  {
  Although we are not using the Row Filter here, it is useful to retrieve its outout
  rates as it is the input to the Main Filter. This is not necessarily the same as
  the front end count rates as there may already have been losses due to front end
  troughput limits. We do the same summation as above.
  }
  RetCode := MH_GetRowFilteredRates(DevIdx[0], FTestSyncRate, FTestChanRates[0]);
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_GetRowFilteredRates error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;

  FTestSumRate := 0;
  for i := 0 to NumChannels - 1 do
    FTestSumRate := FTestSumRate + FTestChanRates[i];
  if Mode = MODE_T2 then //in this case also add the sync rate
    FTestSumRate := FTestSumRate + FTestSyncRate;

  Writeln('Main filter input rate = ', FTestSumRate);
  Writeln('');

  //Now we do the same rate retrieval and summation for the Main Filter output.
  RetCode := MH_GetMainFilteredRates(DevIdx[0], FTestSyncRate, FTestChanRates[0]);
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_GetRowFilteredRates error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;

  FTestSumRate := 0;
  for i := 0 to NumChannels - 1 do
    FTestSumRate := FTestSumRate + FTestChanRates[i];
  if Mode = MODE_T2 then //in this case also add the sync rate
    FTestSumRate := FTestSumRate + FTestSyncRate;

  Writeln('Main filter output rate = ', FTestSumRate);
  Writeln('');

  RetCode := MH_StopMeas(DevIdx[0]); //test finished, stop measurement
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_StopMeas error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;
  //Testmode must be switched off again to allow a real measurement
  RetCode := MH_SetFilterTestMode(DevIdx[0], 0); //re-enable FiFo input
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_SetFilterTestMode ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;
  // End of main filter test
  // here we begin the real measurement

  if Mode = Mode_T2 then
    Writeln(OutputFile, 'ev chn time/ps') //column heading for T2 mode
  else
    Writeln(OutputFile, 'ev chn ttag/s dtime/ps'); //column heading for T3 mode

  Writeln('press RETURN to start measurement');
  Readln;

  RetCode := MH_StartMeas(DevIdx[0], TAcq);
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_StartMeas error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;
  Writeln('Measuring for ', TAcq, ' milliseconds...');

  if (Mode = MODE_T3) then
  begin
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
    RetCode := MH_GetSyncPeriod(DevIdx[0], SyncPeriod);
    if RetCode <> MH_ERROR_NONE then
    begin
      Writeln('MH_GetSyncPeriod error ', RetCode:3, '. Aborted.');
      Ex(RetCode);
    end;
    Writeln('Sync period is ', round(SyncPeriod * 1e9),' ns');
  end;

  Writeln;
  Writeln('Starting data collection...');

  Progress := 0;
  OflCorrection := 0;

  repeat
    RetCode := MH_GetFlags(DevIdx[0], Flags);
    if RetCode <> MH_ERROR_NONE then
    begin
      Writeln('MH_GetFlags error ', RetCode:3, '. Aborted.');
      Ex(RetCode);
    end;
    FiFoFull := (Flags and FLAG_FIFOFULL) > 0;

    if FiFoFull then
      Writeln('  FiFo Overrun!')
    else
    begin
      RetCode := MH_ReadFiFo(DevIdx[0], Buffer[0], Records); // may return less!
      if RetCode <> MH_ERROR_NONE then
      begin
        Writeln('MH_TTReadData error ', RetCode:3, '. Aborted.');
        Ex(RetCode);
      end;

      // Here we process the data. Note that the time this consumes prevents us
      // from getting around the loop quickly for the next Fifo read.
      // In a serious performance critical scenario you would write the data to
      // a software queue and do the processing in another thread reading from
      // that queue.
      if Records > 0 then
      begin
        if Mode = Mode_T2 then
          for i := 0 to Records do
            ProcessT2(Buffer[i])
        else
          for i := 0 to Records do
            ProcessT3(Buffer[i]);
        Progress := Progress + Records;
        Write(#8#8#8#8#8#8#8#8#8, Progress:9);
      end
      else
      begin
        RetCode := MH_CTCStatus(DevIdx[0], CTCStatus);
        if RetCode <> MH_ERROR_NONE then
        begin
          Writeln;
          Writeln('MH_CTCStatus error ', RetCode:3, '. Aborted.');
          Ex(RetCode);
        end;
        TimeOut := (CTCStatus <> 0);
        if TimeOut then
        begin
          Writeln;
          Writeln('Done');
        end;
      end;
    end;
  until FiFoFull or TimeOut or FileError;

  Writeln;

  RetCode := MH_StopMeas(DevIdx[0]);
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_StopMeas error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;

  Writeln;

  MH_CloseAllDevices;
  CloseFile(OutputFile);
  Ex(MH_ERROR_NONE);
end.

