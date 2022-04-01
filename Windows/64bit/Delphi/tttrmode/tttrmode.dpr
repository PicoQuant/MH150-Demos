{
  MultiHarp 150/160  MHLIB v3.1  Usage Demo with Delphi or Lazarus
  
  Tested with
   - Delphi 11.0 on Windows 10
   - Lazarus 2.0.12 / fpc 3.2.0 on Windows 10

  The program performs a TTTR measurement based on hardcoded settings.
  The resulting event data is stored in a binary output file.

  Axel Hagen, PicoQuant GmbH, May 2018
  Marcus Sackrow, PicoQuant GmbH, July 2019
  Michael Wahl, PicoQuant GmbH, May 2020, March 2021
  Revised Matthias Patting, Stefan Eilers, PicoQuant GmbH, March 2022

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

var
  RetCode            : LongInt;
  OutFile            : file;
  i                  : Integer;
  Written            : LongInt;
  Found              : Integer =       0;
  Progress           : LongInt =       0;
  FiFoFull           : Boolean =   False;
  MeasDone           : Boolean =   False;
  FileError          : Boolean =   False;


  Mode               : LongInt =      MODE_T3; // set T2 or T3 here, observe suitable Syncdivider and Range!
  Binning            : LongInt =            0; // you can change this (meaningless in T2 mode)
  Offset             : LongInt =            0; // normally no need to change this
  TAcq               : LongInt =        1000; // you can change this, unit is millisec
  SyncDivider        : LongInt =            1; // you can change this
  SyncTrgEdge        : LongInt = EDGE_FALLING; // you can change this
  SyncTrgLevel       : LongInt =          -50; // you can change this (mV)
  SyncChannelOffset  : LongInt =            0; // you can change this (like a cable delay)
  InputTrgEdge       : LongInt = EDGE_FALLING; // you can change this
  InputTrgLevel      : LongInt =          -50; // you can change this (mV)
  InputChannelOffset : LongInt =            0; // you can change this (like a cable delay)

  NumChannels        : LongInt;
  ChanIdx            : LongInt;
  Resolution         : Double;
  SyncRate           : LongInt;
  CountRate          : LongInt;
  CTCStatus          : LongInt;
  Flags              : LongInt;
  Records            : LongInt;
  Warnings           : LongInt;

  Buffer             : array[0..TTREADMAX - 1] of LongWord;

procedure Ex(RetCode: Integer);
begin
  if RetCode <> MH_ERROR_NONE then
  begin
    MH_GetErrorString(pcErrText, RetCode);
    Writeln('Error ', RetCode:3, ' = "', Trim (string(strErrText)), '"');
  end;
  Writeln;
  {$I-}
    CloseFile(OutFile);
    IOResult();
  {$I+}
  Writeln('press RETURN to exit');
  Readln;
  Halt(RetCode);
end;

begin
  Writeln;
  Writeln('MultiHarp  MHLib  Usage Demo                        PicoQuant GmbH, 2022');
  Writeln('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
  RetCode := MH_GetLibraryVersion (pcLibVers);
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_GetLibraryVersion error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;
  Writeln('MHLIB version is ' + strLibVers);
  if Trim(string(strLibVers)) <> Trim(AnsiString(LIB_VERSION)) then
    Writeln('Warning: The application was built for version ' + LIB_VERSION);

  AssignFile(OutFile, 'tttrmode.out');
  {$I-}
    Rewrite(OutFile, 4);
  {$I+}
  if IOResult <> 0 then
  begin
    Writeln('cannot open output file');
    Ex(MH_ERROR_NONE);
  end;

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
  Writeln('Searching for MultiHarp devices...');
  Writeln('Devidx     Status');

  for i := 0 to MAXDEVNUM - 1 do
  begin
    RetCode := MH_OpenDevice(i, pcHWSerNr);
    //
    if RetCode = MH_ERROR_NONE then
    begin
      // Grab any MultiHarp we can open
      DevIdx[Found] := i; // keep index to devices we want to use
      Inc(Found);
      Writeln('   ', i, '      S/N ', strHWSerNr);
    end
    else
    begin
      if RetCode = MH_ERROR_DEVICE_OPEN_FAIL then
        Writeln('   ', i, '       no device')
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
    RetCode := MH_SetInputEdgeTrg (DevIdx[0], ChanIdx, InputTrgLevel, InputTrgEdge);
    if RetCode <> MH_ERROR_NONE then
    begin
      Writeln('MH_SetInputEdgeTrg channel ', ChanIdx:2, ' error ', RetCode:3, '. Aborted.');
      Ex(RetCode);
    end;

    RetCode := MH_SetInputChannelOffset(DevIdx[0], ChanIdx, InputChannelOffset);
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

  if (Mode <> MODE_T2) then                  // These are meaningless in T2 mode
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

    RetCode := MH_GetResolution(DevIdx[0], Resolution);
    if RetCode <> MH_ERROR_NONE then
    begin
      Writeln('MH_GetResolution error ', RetCode:3, '. Aborted.');
      Ex(RetCode);
    end;
    Writeln('Resolution is ', Resolution:7:3, 'ps');
  end;

  // Note: After Init or SetSyncDiv you must allow > 400 ms for valid new count rate readings
  // otherwise you get new values after every 100 ms
  Sleep(400);

  Writeln;

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

  RetCode := MH_GetWarnings(DevIdx[0], Warnings);
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

  RetCode := MH_StartMeas(DevIdx[0], TAcq);
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_StartMeas error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;
  Writeln('Measuring for ', TAcq, ' milliseconds...');

  Progress := 0;
  Write(#8#8#8#8#8#8#8#8#8, Progress:9);

  repeat
    RetCode := MH_GetFlags(DevIdx[0], Flags);
    if RetCode <> MH_ERROR_NONE then
    begin
      Writeln('MH_GetFlags error ', RetCode:3, '. Aborted.');
      Ex(RetCode);
    end;
    FiFoFull := (Flags and FLAG_FIFOFULL) > 0;

    if FiFoFull then
      writeln ('  FiFo Overrun!')
    else
    begin
      RetCode := MH_ReadFiFo(DevIdx[0], Buffer[0], Records); // may return less!
      if RetCode <> MH_ERROR_NONE then
      begin
        Writeln('MH_TTReadData error ', RetCode:3, '. Aborted.');
        Ex(RetCode);
      end;

      if Records > 0 then
      begin
        BlockWrite(OutFile, Buffer[0], Records, Written);
        if Records <> Written then
        begin
          Writeln;
          Writeln('file write error');
          FileError := True;
        end;

        Progress := Progress + Written;
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
        MeasDone := (CTCStatus <> 0);
        if MeasDone then
        begin
          Writeln;
          Writeln('Done');
        end;
      end;
    end;

  until FiFoFull or MeasDone or FileError;

  Writeln;

  RetCode := MH_StopMeas(DevIdx[0]);
  if RetCode <> MH_ERROR_NONE then
  begin
    Writeln('MH_StopMeas error ', RetCode:3, '. Aborted.');
    Ex(RetCode);
  end;

  Writeln;

  MH_CloseAllDevices;

  Ex(MH_ERROR_NONE);
end.

