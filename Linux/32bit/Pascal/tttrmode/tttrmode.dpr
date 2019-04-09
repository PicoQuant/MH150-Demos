{
  MultiHarp 150  HHLIB v1.0  Usage Demo with Delphi or Lazarus
  
  Tested with
   - Delphi 10.1 on Windows 10
   - Lazarus 1.8.4 / fpc 3.0.4 on Windows 8
   - Lazarus 1.4.4 / fpc 2.6.4 on Linux

  The program performs a TTTR measurement based on hardcoded settings.
  The resulting event data is stored in a binary output file.

  Axel Hagen, Michael Wahl, PicoQuant GmbH, October 2018

  Note: This is a console application (i.e. run in Windows cmd box)

  Note: At the API level channel numbers are indexed 0..N-1
        where N is the number of channels the device has.

  Note: This demo writes only raw event data to the output file.
        It does not write a file header as regular .ht* files have it.
}

program tttrmode;

{$IFDEF WINDOWS}
  {$APPTYPE CONSOLE}  //windows needs this, Linux does not want it
{$ENDIF}

uses
  {$ifdef fpc}
  SysUtils,
  {$else}
  System.SysUtils,
  System.Ansistrings,
  {$endif}
  mhlib in 'mhlib.pas';

var
  iRetCode           : longint;
  outf               : File;
  i                  : integer;
  iWritten           : longint;
  iFound             : integer =       0;
  iProgress          : longint =       0;
  bFiFoFull          : boolean =   false;
  bTimeOut           : boolean =   false;
  bFileError         : boolean =   false;


  iMode              : longint =      MODE_T2; // set T2 or T3 here, observe suitable Syncdivider and Range!
  iBinning           : longint =            0; // you can change this (meaningless in T2 mode)
  iOffset            : longint =            0; // normally no need to change this
  iTAcq              : longint =        10000; // you can change this, unit is millisec
  iSyncDivider       : longint =            1; // you can change this
  iSyncTrgEdge       : longint = EDGE_FALLING; // you can change this
  iSyncTrgLevel      : longint =          -50; // you can change this (mV)
  iSyncChannelOffset : longint =            0; // you can change this (like a cable delay)
  iInputTrgEdge      : longint = EDGE_FALLING; // you can change this
  iInputTrgLevel     : longint =          -50; // you can change this (mV)
  iInputChannelOffset: longint =            0; // you can change this (like a cable delay)

  iNumChannels       : longint;
  iChanIdx           : longint;
  dResolution        : double;
  iSyncRate          : longint;
  iCountRate         : longint;
  iCTCStatus         : longint;
  iFlags             : longint;
  iRecords           : longint;
  iWarnings          : longint;

  lwBuffer           : array [0..TTREADMAX -1 ] of LongWord;

  procedure ex (iRetCode : integer);
  begin
    if iRetCode <> MH_ERROR_NONE
    then begin
      MH_GetErrorString (pcErrText, iRetCode);
      writeln ('Error ', iRetCode:3, ' = "', Trim (strErrText), '"');
    end;
    writeln;
    {$I-}
      closefile (outf);
      IOResult();
    {$I+}
    writeln('press RETURN to exit');
    readln;
    halt (iRetCode);
  end;

begin
  writeln;
  writeln ('MultiHarp 150 MHLib  Usage Demo                     PicoQuant GmbH, 2018');
  writeln ('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
  iRetCode := MH_GetLibraryVersion (pcLibVers);
  if iRetCode <> MH_ERROR_NONE
  then begin
    writeln ('MH_GetLibraryVersion error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;
  writeln ('MHLIB version is ' + strLibVers);
  if trim (strLibVers) <> trim (AnsiString (LIB_VERSION))
  then
    writeln ('Warning: The application was built for version ' + LIB_VERSION);

  assignfile (outf, 'tttrmode.out');
  {$I-}
    rewrite (outf, 4);
  {$I+}
  if IOResult <> 0 then
  begin
    writeln ('cannot open output file');
    ex (MH_ERROR_NONE);
  end;

  writeln;
  writeln ('Mode               : ', iMode);
  writeln ('Binning            : ', iBinning);
  writeln ('Offset             : ', iOffset);
  writeln ('AcquisitionTime    : ', iTacq);
  writeln ('SyncDivider        : ', iSyncDivider);
  writeln ('SyncTrgEdge        : ', iSyncTrgEdge);
  writeln ('SyncTrgLevel       : ', iSyncTrgLevel);
  writeln ('SyncChannelOffset  : ', iSyncChannelOffset);
  writeln ('InputTrgEdge       : ', iInputTrgEdge);
  writeln ('InputTrgLevel      : ', iInputTrgLevel);
  writeln ('InputChannelOffset : ', iInputChannelOffset);

  writeln;
  writeln ('Searching for MultiHarp devices...');
  writeln ('Devidx     Status');

  for i:=0 to MAXDEVNUM - 1 do
  begin
    iRetCode := MH_OpenDevice (i, pcHWSerNr);
    //
    if iRetCode = MH_ERROR_NONE
    then begin
      // Grab any MultiHarp we can open
      iDevIdx [iFound] := i; // keep index to devices we want to use
      inc (iFound);
      writeln ('   ', i, '      S/N ', strHWSerNr);
    end
    else
    begin
      if iRetCode = MH_ERROR_DEVICE_OPEN_FAIL
      then
        writeln ('   ', i, '       no device')
      else begin
        MH_GetErrorString (pcErrText, iRetCode);
        writeln ('   ', i, '       ', Trim (strErrText));
      end;
    end;
  end;

  // in this demo we will use the first MultiHarp device we found,
  // i.e. iDevIdx[0].  You can also use multiple devices in parallel.
  // you could also check for a specific serial number, so that you
  // always know which physical device you are talking to.

  if iFound < 1 then
  begin
    writeln ('No device available.');
    ex (MH_ERROR_NONE);
  end;

  writeln ('Using device ', iDevIdx[0]);
  writeln ('Initializing the device...');

  iRetCode := MH_Initialize (iDevIdx[0], iMode, 0); //with internal clock
  if iRetCode <> MH_ERROR_NONE
  then begin
    writeln ('MH_Initialize error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;

  iRetCode := MH_GetHardwareInfo (iDevIdx[0], pcHWModel, pcHWPartNo, pcHWVersion); // this is only for information
  if iRetCode <> MH_ERROR_NONE
  then begin
    writeln ('MH_GetHardwareInfo error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end
  else
    writeln ('Found Model ', strHWModel,'  Part no ', strHWPartNo,'  Version ', strHWVersion);

  iRetCode := MH_GetNumOfInputChannels (iDevIdx[0], iNumChannels);
  if iRetCode <> MH_ERROR_NONE
  then begin
    writeln ('MH_GetNumOfInputChannels error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end
  else
    writeln ('Device has ', iNumChannels, ' input channels.');

  writeln;

  iRetCode := MH_SetSyncDiv (iDevIdx[0], iSyncDivider);
  if iRetCode <> MH_ERROR_NONE
  then begin
    writeln ('MH_SetSyncDiv error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;

  iRetCode := MH_SetSyncEdgeTrg (iDevIdx[0], iSyncTrgLevel, iSyncTrgEdge);
  if iRetCode <> MH_ERROR_NONE
  then begin
    writeln ('MH_SetSyncEdgeTrg error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;

  iRetCode := MH_SetSyncChannelOffset (iDevIdx[0], iSyncChannelOffset);
  if iRetCode <> MH_ERROR_NONE
  then begin
    writeln ('MH_SetSyncChannelOffset error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;

  for iChanIdx := 0 to iNumChannels - 1 do // we use the same input settings for all channels
  begin
    iRetCode := MH_SetInputEdgeTrg (iDevIdx[0], iChanIdx, iInputTrgLevel, iInputTrgEdge);
    if iRetCode <> MH_ERROR_NONE
    then begin
      writeln ('MH_SetInputEdgeTrg channel ', iChanIdx:2, ' error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;

    iRetCode := MH_SetInputChannelOffset (iDevIdx[0], iChanIdx, iInputChannelOffset);
    if iRetCode <> MH_ERROR_NONE
    then begin
      writeln ('MH_SetInputChannelOffset channel ', iChanIdx:2, ' error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;

    iRetCode := MH_SetInputChannelEnable (iDevIdx[0], iChanIdx, 1);
    if iRetCode <> MH_ERROR_NONE
    then begin
      writeln ('MH_SetInputChannelEnable channel ', iChanIdx:2, ' error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;
  end;

  if (iMode <> MODE_T2)                      // These are meaningless in T2 mode
  then begin
    iRetCode := MH_SetBinning (iDevIdx[0], iBinning);
    if iRetCode <> MH_ERROR_NONE
    then begin
      writeln ('MH_SetBinning error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;

    iRetCode := MH_SetOffset(iDevIdx[0], iOffset);
    if iRetCode <> MH_ERROR_NONE
    then begin
      writeln ('MH_SetOffset error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;

    iRetCode := MH_GetResolution (iDevIdx[0], dResolution);
    if iRetCode <> MH_ERROR_NONE
    then begin
      writeln ('MH_GetResolution error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;
    writeln ('Resolution is ', dResolution:7:3, 'ps');
  end;

  // Note: After Init or SetSyncDiv you must allow > 400 ms for valid new count rate readings
  // otherwise you get new values after every 100 ms
  Sleep (400);

  writeln;

  iRetCode := MH_GetSyncRate (iDevIdx[0], iSyncRate);
  if iRetCode <> MH_ERROR_NONE
  then begin
    writeln ('MH_GetSyncRate error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;
  writeln ('SyncRate = ', iSyncRate, '/s');

  writeln;

  for iChanIdx := 0 to iNumChannels - 1 do // for all channels
  begin
    iRetCode := MH_GetCountRate (iDevIdx[0], iChanIdx, iCountRate);
    if iRetCode <> MH_ERROR_NONE
    then begin
      writeln ('MH_GetCountRate error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;
    writeln ('Countrate [', iChanIdx:2, '] = ', iCountRate:8, '/s');
  end;

  writeln;

  iRetCode := MH_GetWarnings(iDevIdx[0], iWarnings);
  if iRetCode <> MH_ERROR_NONE
  then begin
    writeln ('MH_GetWarnings error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;
  if iWarnings <> 0 then
  begin
    MH_GetWarningsText(iDevIdx[0], pcWtext, iWarnings);
    writeln (strWtext);
  end;

  iRetCode := MH_StartMeas (iDevIdx[0], iTacq);
  if iRetCode <> MH_ERROR_NONE then
  begin
    writeln ('MH_StartMeas error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;
  writeln ('Measuring for ', iTacq, ' milliseconds...');

  iProgress := 0;
  write (#8#8#8#8#8#8#8#8#8, iProgress:9);

  repeat
    iRetCode := MH_GetFlags (iDevIdx[0], iFlags);
    if iRetCode <> MH_ERROR_NONE then
    begin
      writeln ('MH_GetFlags error ', iRetCode:3, '. Aborted.');
      ex (iRetCode);
    end;
    bFiFoFull := (iFlags and FLAG_FIFOFULL) > 0;

    if bFiFoFull then
      writeln ('  FiFo Overrun!')
    else
    begin
      iRetCode := MH_ReadFiFo (iDevIdx[0], lwBuffer[0], iRecords); // may return less!
      if iRetCode <> MH_ERROR_NONE then
      begin
        writeln ('MH_TTReadData error ', iRetCode:3, '. Aborted.');
        ex (iRetCode);
      end;

      if (iRecords > 0)then
      begin
        blockwrite (outf, lwBuffer[0], iRecords, iWritten);
        if iRecords <> iWritten then
        begin
          writeln;
          writeln ('file write error');
          bFileError := true;
        end;

        iProgress := iProgress + iWritten;
        write (#8#8#8#8#8#8#8#8#8, iProgress:9);
      end
      else
      begin
        iRetCode := MH_CTCStatus (iDevIdx[0], iCTCStatus);
        if iRetCode <> MH_ERROR_NONE then
        begin
          writeln;
          writeln ('MH_CTCStatus error ', iRetCode:3, '. Aborted.');
          ex (iRetCode);
        end;
        bTimeOut := (iCTCStatus <> 0);
        if bTimeOut then
        begin
          writeln;
          writeln('Done');
        end;
      end;
    end;

  until  bFiFoFull or bTimeOut or bFileError;

  writeln;

  iRetCode := MH_StopMeas (iDevIdx[0]);
  if iRetCode <> MH_ERROR_NONE then
  begin
    writeln ('MH_StopMeas error ', iRetCode:3, '. Aborted.');
    ex (iRetCode);
  end;

  writeln;

  MH_CloseAllDevices;

  ex (MH_ERROR_NONE);
end.

