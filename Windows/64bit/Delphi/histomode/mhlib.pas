Unit MHLib;
{                                                               }
{ Functions exported by the MultiHarp programming library MHLib }
{                                                               }
{ Ver. 3.0    March 2021                                        }
{                                                               }

interface

const
  LIB_VERSION    =      '3.0';
{$UNDEF PLATFORM_OK}
{$IFDEF WIN32}
  LIB_NAME       =      'mhlib.dll';  // Windows 32 bit
  {$DEFINE PLATFORM_OK}
{$ENDIF}
{$IFDEF WIN64}
  LIB_NAME       =      'mhlib64.dll';    // Windows 64 bit
  {$DEFINE PLATFORM_OK}
{$ENDIF}
{$IFDEF LINUX}
  LIB_NAME       =      'libmh150.so';  // Linux 32 or 64 bit
  {$DEFINE PLATFORM_OK}
{$ENDIF}
{$IFNDEF PLATFORM_OK}
  {$FATAL OS platform not supported}
{$ENDIF}

  MAXDEVNUM      =          8;   // max num of USB devices

  MHMAXINPCHAN   =         64;   // max num of input channels

  MAXBINSTEPS    =         24;   // get actual number via HH_GetBaseResolution() !

  MAXHISTLEN     =      65536;   // max number of histogram bins

  TTREADMAX      =     1048576;   // 1M event records can be read in one chunk

  //symbolic constants for MH_Initialize
  REFSRC_INTERNAL          = 0; // use internal clock
  REFSRC_EXTERNAL_10MHZ    = 1; // use 10MHz external clock
  REFSRC_WR_MASTER_GENERIC = 2; // White Rabbit master with generic partner
  REFSRC_WR_SLAVE_GENERIC  = 3; // White Rabbit slave with generic partner
  REFSRC_WR_GRANDM_GENERIC = 4; // White Rabbit grand master with generic partner
  REFSRC_EXTN_GPS_PPS      = 5; // use 10 MHz + PPS from GPS
  REFSRC_EXTN_GPS_PPS_UART = 6; // use 10 MHz + PPS + time via UART from GPS
  REFSRC_WR_MASTER_MHARP   = 7; // White Rabbit master with MultiHarp as partner
  REFSRC_WR_SLAVE_MHARP    = 8; // White Rabbit slave with MultiHarp as partner
  REFSRC_WR_GRANDM_MHARP   = 9; // White Rabbit grand master with MultiHarp as partner

  //symbolic constants for MH_Initialize
  MODE_HIST = 0;
  MODE_T2   = 2;
  MODE_T3   = 3;

  //symbolic constants for MH_SetMeasControl
  MEASCTRL_SINGLESHOT_CTC     = 0;   //default
  MEASCTRL_C1_GATE            = 1;
  MEASCTRL_C1_START_CTC_STOP  = 2;
  MEASCTRL_C1_START_C2_STOP   = 3;
  MEASCTRL_WR_M2S             = 4;
  MEASCTRL_WR_S2M             = 5;

  //symb. const. for MH_SetMeasControl, MH_SetSyncEdgeTrg and MH_SetInputEdgeTrg
  EDGE_RISING    = 1;
  EDGE_FALLING   = 0;

  //bitmasks for results from MH_GetFeatures
  FEATURE_DLL       = $0001; // DLL License available
  FEATURE_TTTR      = $0002; // TTTR mode available
  FEATURE_MARKERS   = $0004; // Markers available
  FEATURE_LOWRES    = $0008; // Long range mode available
  FEATURE_TRIGOUT   = $0010; // Trigger output available
  FEATURE_PROG_TD   = $0020; // Programmable deadtime available
  FEATURE_EXT_FPGA  = $0040; // Interface for External FPGA available
  FEATURE_PROG_HYST = $0080; // Programmable input hysteresis available

  //bitmasks for results from MH_GetFlags
  FLAG_OVERFLOW     =      $0001;   // histo mode only
  FLAG_FIFOFULL     =      $0002;   // TTTR mode only
  FLAG_SYNC_LOST    =      $0004;
  FLAG_REF_LOST     =      $0008;
  FLAG_SYSERROR     =      $0010;   // hardware error, must contact support
  FLAG_ACTIVE       =      $0020;   // measurement is running
  FLAG_CNTS_DROPPED =      $0040;   // events dropped

  //limits for MH_SetHistoLen
  //note: length codes 0 and 1 will not work with MH_GetHistogram
  //if you need these short lengths then use MH_GetAllHistograms
  MINLENCODE  = 0;
  MAXLENCODE  = 6; //default

  //limits for MH_SetSyncDiv
  SYNCDIVMIN =           1;
  SYNCDIVMAX =          16;

  //limits for MH_SetSyncEdgeTrg and MH_SetInputEdgeTrg
  TRGLVLMIN	      =      -1200;	 // mV  MH150 Nano only
  TRGLVLMAX	      =       1200;   // mV  MH150 Nano only

  //limits for MH_SetSyncChannelOffset and MH_SetInputChannelOffset
  CHANOFFSMIN =     -99999; // ps
  CHANOFFSMAX =      99999; // ps

  //limits for MH_SetSyncDeadTime and MH_SetInputDeadTime
  EXTDEADMIN  =        800; // ps
  EXTDEADMAX  =     160000; // ps

  //limits for MH_SetOffset
  OFFSETMIN =            0; // ns
  OFFSETMAX =    100000000; // ns

  //limits for MH_StartMeas
  ACQTMIN =              1; // ms
  ACQTMAX =      360000000; // ms  (100*60*60*1000ms = 100h)

  //limits for MH_SetStopOverflow
  STOPCNTMIN =            1;
  STOPCNTMAX =   4294967295; // 32 bit is mem max

  //limits for MH_SetTriggerOutput
  TRIGOUTMIN =            0; // 0 = off
  TRIGOUTMAX =     16777215; // in units of 100ns

  //limits for MH_SetMarkerHoldoffTime
  HOLDOFFMIN =            0;  // ns
  HOLDOFFMAX =        25500;  // ns

  //limits for MH_SetInputHysteresis
  HYSTCODEMIN =           0;  // approx. 3mV
  HYSTCODEMAX =           1;  // approx. 35mV

var
  pcLibVers      : pAnsiChar;
  strLibVers     : array [0.. 7] of AnsiChar;
  pcErrText      : pAnsiChar;
  strErrText     : array [0..40] of AnsiChar;
  pcHWSerNr      : pAnsiChar;
  strHWSerNr     : array [0.. 7] of AnsiChar;
  pcHWModel      : pAnsiChar;
  strHWModel     : array [0..23] of AnsiChar;
  pcHWPartNo     : pAnsiChar;
  strHWPartNo    : array [0.. 8] of AnsiChar;
  pcHWVersion    : pAnsiChar;
  strHWVersion   : array [0.. 8] of AnsiChar;
  pcWtext        : pAnsiChar;
  strWtext       : array [0.. 16384] of AnsiChar;
  pcDebugInfo    : pAnsiChar;
  strDebugInfo   : array [0.. 16384] of AnsiChar;

  iDevIdx        : array [0..MAXDEVNUM - 1] of LongInt;


function MH_GetLibraryVersion(Vers: PAnsiChar): LongInt; stdcall; external LIB_NAME;
function MH_GetErrorString(ErrString: PAnsiChar; ErrCode: LongInt): LongInt; stdcall; external LIB_NAME;

function MH_OpenDevice(DevIdx: LongInt; Serial: PAnsiChar): LongInt; stdcall; external LIB_NAME;
function MH_CloseDevice(Devidx: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_Initialize(Devidx: LongInt; Mode: LongInt; RefSource: LongInt): LongInt; stdcall; external LIB_NAME;

// all functions below can only be used after HH_Initialize

function MH_GetHardwareInfo(DevIdx: LongInt; Model: PAnsiChar; PartNo: PAnsiChar; Version: PAnsiChar): LongInt; stdcall; external LIB_NAME;
function MH_GetSerialNumber(DevIdx: LongInt; Serial: PAnsiChar): LongInt; stdcall; external LIB_NAME;
function MH_GetFeatures(DevIdx: LongInt; var Features: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_GetBaseResolution(DevIdx: LongInt; var Resolution: Double; var BinSteps: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_GetNumOfInputChannels(DevIdx: LongInt; var NChannels: LongInt): LongInt; stdcall; external LIB_NAME;

function MH_SetSyncDiv(DevIdx: LongInt; SyncDiv: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_SetSyncEdgeTrg(DevIdx: LongInt; Level: LongInt; Edge: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_SetSyncChannelOffset(DevIdx: LongInt; Value: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_SetSyncDeadTime(Devidx: LongInt; IsOn: LongInt; DeadTime: LongInt): LongInt; stdcall; external LIB_NAME; //new in v1.1

function MH_SetInputEdgeTrg(DevIdx: LongInt; channel: LongInt; level: LongInt; edge: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_SetInputChannelOffset(DevIdx: LongInt; channel: LongInt; value: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_SetInputDeadTime(DevIdx: LongInt; Channel: LongInt; IsOn: LongInt; DeadTime: LongInt): LongInt; stdcall; external LIB_NAME; //new in v1.1
function MH_SetInputHysteresis(DevIdx: LongInt; HystCode: LongInt): LongInt; stdcall; external LIB_NAME;   //new since v3.0
function MH_SetInputChannelEnable(DevIdx: LongInt; channel: LongInt; enable: LongInt): LongInt; stdcall; external LIB_NAME;

function MH_SetStopOverflow(DevIdx: LongInt; stop_ovfl: LongInt; stopcount: LongWord): LongInt; stdcall; external LIB_NAME;
function MH_SetBinning(DevIdx: LongInt; binning: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_SetOffset(DevIdx: LongInt; offset: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_SetHistoLen(DevIdx: LongInt; lencode: LongInt; var actuallen: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_SetMeasControl(DevIdx: LongInt; control: LongInt; startedge: LongInt; stopedge: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_SetTriggerOutput(DevIdx: LongInt; period: LongInt): LongInt; stdcall; external LIB_NAME;

function MH_ClearHistMem(DevIdx: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_StartMeas(DevIdx: LongInt; tacq: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_StopMeas(DevIdx: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_CTCStatus(DevIdx: LongInt; var ctcstatus: LongInt): LongInt; stdcall; external LIB_NAME;

function MH_GetHistogram(DevIdx: LongInt; var chcount: LongWord; channel: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_GetAllHistograms(DevIdx: LongInt; var chcount: LongWord): LongInt; stdcall; external LIB_NAME;
function MH_GetResolution(DevIdx: LongInt; var Resolution: Double): LongInt; stdcall; external LIB_NAME;
function MH_GetSyncPeriod(DevIdx: LongInt; var period: Double): LongInt; stdcall; external LIB_NAME;
function MH_GetSyncRate(DevIdx: LongInt; var syncrate: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_GetCountRate(DevIdx: LongInt; channel: LongInt; var cntrate: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_GetAllCountRates(DevIdx: LongInt; var syncrate: LongInt; var cntrates: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_GetFlags(DevIdx: LongInt; var flags: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_GetElapsedMeasTime(DevIdx: LongInt; var elapsed: Double): LongInt; stdcall; external LIB_NAME;
function MH_GetStartTime(DevIdx: LongInt; var timedw2: LongWord; var timedw1: LongWord; var timedw0: LongWord): LongInt; stdcall; external LIB_NAME;

function MH_GetWarnings(DevIdx: LongInt; var warnings: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_GetWarningsText(DevIdx: LongInt; text: PAnsiChar; warnings: LongInt): LongInt; stdcall; external LIB_NAME;

// for the time tagging modes only
function MH_SetMarkerHoldoffTime(DevIdx: LongInt; holdofftime: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_SetMarkerEdges(DevIdx: LongInt; me1: LongInt; me2: LongInt; me3: LongInt; me4: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_SetMarkerEnable(DevIdx: LongInt; en1: LongInt; en2: LongInt; en3: LongInt; en4: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_ReadFiFo(DevIdx: LongInt; var buffer: LongWord; var nactual: LongInt): LongInt; stdcall; external LIB_NAME;

//for debugging only
function MH_GetDebugInfo(DevIdx: LongInt; debuginfo: PAnsiChar): LongInt; stdcall; external LIB_NAME;
function MH_GetNumOfModules(DevIdx: LongInt; var nummod: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_GetModuleInfo(DevIdx: LongInt; modidx: LongInt; var modelcode: LongInt; var versioncode: LongInt): LongInt; stdcall; external LIB_NAME;

//for White Rabbit only
function MH_WRabbitGetMAC(DevIdx: LongInt; mac_addr: PAnsiChar): LongInt; stdcall; external LIB_NAME;
function MH_WRabbitSetMAC(DevIdx: LongInt; mac_addr: PAnsiChar): LongInt; stdcall; external LIB_NAME;
function MH_WRabbitGetInitScript(DevIdx: LongInt; initscript: PAnsiChar): LongInt; stdcall; external LIB_NAME;
function MH_WRabbitSetInitScript(DevIdx: LongInt; initscript: PAnsiChar): LongInt; stdcall; external LIB_NAME;
function MH_WRabbitGetSFPData(DevIdx: LongInt; sfpnames: PAnsiChar; var dTxs: LongInt; var dRxs: LongInt; var alphas: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_WRabbitSetSFPData(DevIdx: LongInt; sfpnames: PAnsiChar; var dTxs: LongInt; var dRxs: LongInt; var alphas: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_WRabbitInitLink(DevIdx: LongInt; link_on: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_WRabbitSetMode(DevIdx: LongInt; bootfromscript: LongInt; reinit_with_mode: LongInt; mode: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_WRabbitSetTime(DevIdx: LongInt; timehidw: LongWord; timelodw: LongWord): LongInt; stdcall; external LIB_NAME;
function MH_WRabbitGetTime(DevIdx: LongInt; var timehidw: LongWord; var timelodw: LongWord; var subsec16ns: LongWord): LongInt; stdcall; external LIB_NAME;
function MH_WRabbitGetStatus(DevIdx: LongInt; var wrstatus: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_WRabbitGetTermOutput(DevIdx: LongInt; buffer: PAnsiChar; var nchar: LongInt): LongInt; stdcall; external LIB_NAME;

//for MultiHarp 160 with external FPGA only
function MH_ExtFPGAInitLink(DevIdx: LongInt; linknumber: LongInt; on: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_ExtFPGAGetLinkStatus(DevIdx: LongInt; linknumber: LongInt; var status: LongWord): LongInt; stdcall; external LIB_NAME;
function MH_ExtFPGASetMode(DevIdx: LongInt; mode: LongInt; loopback: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_ExtFPGAResetStreamFifos(DevIdx: LongInt): LongInt; stdcall; external LIB_NAME;
function MH_ExtFPGAUserCommand(DevIdx: LongInt; write: LongInt; addr: LongWord; var data: LongWord): LongInt; stdcall; external LIB_NAME;

//for final cleanup
procedure MH_CloseAllDevices;

const
  MH_ERROR_NONE                      =   0;

  MH_ERROR_DEVICE_OPEN_FAIL          =  -1;
  MH_ERROR_DEVICE_BUSY               =  -2;
  MH_ERROR_DEVICE_HEVENT_FAIL        =  -3;
  MH_ERROR_DEVICE_CALLBSET_FAIL      =  -4;
  MH_ERROR_DEVICE_BARMAP_FAIL        =  -5;
  MH_ERROR_DEVICE_CLOSE_FAIL         =  -6;
  MH_ERROR_DEVICE_RESET_FAIL         =  -7;
  MH_ERROR_DEVICE_GETVERSION_FAIL    =  -8;
  MH_ERROR_DEVICE_VERSION_MISMATCH   =  -9;
  MH_ERROR_DEVICE_NOT_OPEN           = -10;
  MH_ERROR_DEVICE_LOCKED             = -11;
  MH_ERROR_DEVICE_DRIVERVER_MISMATCH = -12;

  MH_ERROR_INSTANCE_RUNNING          = -16;
  MH_ERROR_INVALID_ARGUMENT          = -17;
  MH_ERROR_INVALID_MODE              = -18;
  MH_ERROR_INVALID_OPTION            = -19;
  MH_ERROR_INVALID_MEMORY            = -20;
  MH_ERROR_INVALID_RDATA             = -21;
  MH_ERROR_NOT_INITIALIZED           = -22;
  MH_ERROR_NOT_CALIBRATED            = -23;
  MH_ERROR_DMA_FAIL                  = -24;
  MH_ERROR_XTDEVICE_FAIL             = -25;
  MH_ERROR_FPGACONF_FAIL             = -26;
  MH_ERROR_IFCONF_FAIL               = -27;
  MH_ERROR_FIFORESET_FAIL            = -28;
  MH_ERROR_THREADSTATE_FAIL          = -29;
  MH_ERROR_THREADLOCK_FAIL           = -30;

  MH_ERROR_USB_GETDRIVERVER_FAIL     = -32;
  MH_ERROR_USB_DRIVERVER_MISMATCH    = -33;
  MH_ERROR_USB_GETIFINFO_FAIL        = -34;
  MH_ERROR_USB_HISPEED_FAIL          = -35;
  MH_ERROR_USB_VCMD_FAIL             = -36;
  MH_ERROR_USB_BULKRD_FAIL           = -37;
  MH_ERROR_USB_RESET_FAIL            = -38;

  MH_ERROR_LANEUP_TIMEOUT            = -40;
  MH_ERROR_DONEALL_TIMEOUT           = -41;
  MH_ERROR_MB_ACK_TIMEOUT            = -42;
  MH_ERROR_MACTIVE_TIMEOUT           = -43;
  MH_ERROR_MEMCLEAR_FAIL             = -44;
  MH_ERROR_MEMTEST_FAIL              = -45;
  MH_ERROR_CALIB_FAIL                = -46;
  MH_ERROR_REFSEL_FAIL               = -47;
  MH_ERROR_STATUS_FAIL               = -48;
  MH_ERROR_MODNUM_FAIL               = -49;
  MH_ERROR_DIGMUX_FAIL               = -50;
  MH_ERROR_MODMUX_FAIL               = -51;
  MH_ERROR_MODFWPCB_MISMATCH         = -52;
  MH_ERROR_MODFWVER_MISMATCH         = -53;
  MH_ERROR_MODPROPERTY_MISMATCH      = -54;
  MH_ERROR_INVALID_MAGIC             = -55;
  MH_ERROR_INVALID_LENGTH            = -56;
  MH_ERROR_RATE_FAIL                 = -57;
  MH_ERROR_MODFWVER_TOO_LOW          = -58;
  MH_ERROR_MODFWVER_TOO_HIGH         = -59;
  MH_ERROR_MB_ACK_FAIL               = -60;

  MH_ERROR_EEPROM_F01                = -64;
  MH_ERROR_EEPROM_F02                = -65;
  MH_ERROR_EEPROM_F03                = -66;
  MH_ERROR_EEPROM_F04                = -67;
  MH_ERROR_EEPROM_F05                = -68;
  MH_ERROR_EEPROM_F06                = -69;
  MH_ERROR_EEPROM_F07                = -70;
  MH_ERROR_EEPROM_F08                = -71;
  MH_ERROR_EEPROM_F09                = -72;
  MH_ERROR_EEPROM_F10                = -73;
  MH_ERROR_EEPROM_F11                = -74;
  MH_ERROR_EEPROM_F12                = -75;
  MH_ERROR_EEPROM_F13                = -76;
  MH_ERROR_EEPROM_F14                = -77;
  MH_ERROR_EEPROM_F15                = -78;


//The following are bitmasks for return values from MH_GetWarnings
  WARNING_SYNC_RATE_ZERO            = $0001;
  WARNING_SYNC_RATE_VERY_LOW        = $0002;
  WARNING_SYNC_RATE_TOO_HIGH        = $0004;

  WARNING_INPT_RATE_ZERO            = $0010;
  WARNING_INPT_RATE_TOO_HIGH        = $0040;

  WARNING_INPT_RATE_RATIO           = $0100;
  WARNING_DIVIDER_GREATER_ONE       = $0200;
  WARNING_TIME_SPAN_TOO_SMALL       = $0400;
  WARNING_OFFSET_UNNECESSARY        = $0800;

  WARNING_DIVIDER_TOO_SMALL         = $1000;
  WARNING_COUNTS_DROPPED            = $2000;

//The following is only for use with White Rabbit
  WR_STATUS_LINK_ON             = $00000001;  // WR link is switched on
  WR_STATUS_LINK_UP             = $00000002;  // WR link is established

  WR_STATUS_MODE_BITMASK        = $0000000C;  // mask for the mode bits
  WR_STATUS_MODE_OFF            = $00000000;  // mode is "off"
  WR_STATUS_MODE_SLAVE          = $00000004;  // mode is "slave"
  WR_STATUS_MODE_MASTER         = $00000008;  // mode is "master"
  WR_STATUS_MODE_GMASTER        = $0000000C;  // mode is "grandmaster"

  WR_STATUS_LOCKED_CALIBD       = $00000010;  // locked and calibrated

  WR_STATUS_PTP_BITMASK         = $000000E0;  // mask for the PTP bits
  WR_STATUS_PTP_LISTENING       = $00000020;
  WR_STATUS_PTP_UNCLWRSLCK      = $00000040;
  WR_STATUS_PTP_SLAVE           = $00000060;
  WR_STATUS_PTP_MSTRWRMLCK      = $00000080;
  WR_STATUS_PTP_MASTER          = $000000A0;

  WR_STATUS_SERVO_BITMASK       = $00000700;  // mask for the servo bits
  WR_STATUS_SERVO_UNINITLZD     = $00000100;  //
  WR_STATUS_SERVO_SYNC_SEC      = $00000200;  //
  WR_STATUS_SERVO_SYNC_NSEC     = $00000300;  //
  WR_STATUS_SERVO_SYNC_PHASE    = $00000400;  //
  WR_STATUS_SERVO_WAIT_OFFST    = $00000500;  //
  WR_STATUS_SERVO_TRCK_PHASE    = $00000600;  //

  WR_STATUS_MAC_SET             = $00000800;  // user defined mac address is set
  WR_STATUS_IS_NEW              = $80000000;  // status updated since last check

  //The following is only for use with an external FPGA connected to a MultiHarp 160
  EXTFPGA_MODE_OFF              = 0;
  EXTFPGA_MODE_T2RAW            = 1;
  EXTFPGA_MODE_T2               = 2;
  EXTFPGA_MODE_T3               = 3;

  EXTFPGA_LOOPBACK_OFF          = 0;
  EXTFPGA_LOOPBACK_CUSTOM       = 1;
  EXTFPGA_LOOPBACK_T2           = 2;
  EXTFPGA_LOOPBACK_T3           = 3;


implementation

  procedure MH_CloseAllDevices;
  var
    iDev : integer;
  begin
    for iDev := 0 to MAXDEVNUM - 1 do // no harm closing all
      MH_CloseDevice (iDev);
  end;

initialization
  pcLibVers   := pAnsiChar(@strLibVers[0]);
  pcErrText   := pAnsiChar(@strErrText[0]);
  pcHWSerNr   := pAnsiChar(@strHWSerNr[0]);
  pcHWModel   := pAnsiChar(@strHWModel[0]);
  pcHWPartNo  := pAnsiChar(@strHWPartNo[0]);
  pcHWVersion := pAnsiChar(@strHWVersion[0]);
  pcWtext     := pAnsiChar(@strWtext[0]);
  pcDebugInfo := pAnsiChar(@strDebugInfo[0]);
finalization
  MH_CloseAllDevices;
end.
