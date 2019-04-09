Unit MHLib;
{                                                               }
{ Functions exported by the MultiHarp programming library MHLib }
{                                                               }
{ Ver. 1.0      August 2018                                     }
{                                                               }

interface

const
  LIB_VERSION    =      '1.0';
{$IFDEF WIN64}
  LIB_NAME       =      'mhlib64.dll';  //Windows 32 bit
{$ELSE}
  LIB_NAME       =      'mhlib.dll';    //Windows 64 bit
{$ENDIF}

  MAXDEVNUM      =          8;   // max num of USB devices

  MHMAXINPCHAN   =          8;   // max num of physicl input channels

  MAXBINSTEPS    =         26;   // get actual number via HH_GetBaseResolution() !

  MAXHISTLEN     =      65536;   // max number of histogram bins
  MAXLENCODE     =          6;   // max length code histo mode

  TTREADMAX      =     1048576;   // 1M event records can be read in one chunk

  MODE_HIST      =          0;
  MODE_T2        =          2;
  MODE_T3        =          3;

  MEASCTRL_SINGLESHOT_CTC     = 0;   //default
  MEASCTRL_C1_GATE		        = 1;
  MEASCTRL_C1_START_CTC_STOP  = 2;
  MEASCTRL_C1_START_C2_STOP	  = 3;
  MEASCTRL_WR_M2S             = 4;
  MEASCTRL_WR_S2M             = 5;

  EDGE_RISING    = 1;
  EDGE_FALLING   = 0;

  FLAG_OVERFLOW     =      $0001;   // histo mode only
  FLAG_FIFOFULL     =      $0002;   // TTTR mode only
  FLAG_SYNC_LOST    =      $0004;
  FLAG_REF_LOST     =      $0008;
  FLAG_SYSERROR     =      $0010;   // hardware error, must contact support
  FLAG_ACTIVE       =      $0020;   // measurement is running
  FLAG_CNTS_DROPPED =      $0040;   // events dropped

  SYNCDIVMIN      =          1;
  SYNCDIVMAX      =         16;

  TRGLVLMIN	      =      -1200;	 // mV  MH150 Nano only
  TRGLVLMAX	      =       1200;   // mV  MH150 Nano only

  CHANOFFSMIN     =     -99999;   // ps
  CHANOFFSMAX     =      99999;   // ps

  OFFSETMIN       =          0;   // ns
  OFFSETMAX       =  100000000;   // ns

  ACQTMIN         =          1;   // ms
  ACQTMAX         =  360000000;   // ms  (100*60*60*1000ms = 100h)

  STOPCNTMIN      =          1;
  STOPCNTMAX      = 4294967295;   // 32 bit is mem max

  TRIGOUTMIN      =          0;	 // 0 = off
  TRIGOUTMAX      =   16777215;	 // in units of 100ns

  HOLDOFFMIN      =          0;  // ns
  HOLDOFFMAX      =      25500;	 // ns

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


function  MH_GetLibraryVersion     (vers : pAnsiChar) : LongInt;
  stdcall; external LIB_NAME;
function  MH_GetErrorString        (errstring : pAnsiChar; errcode : LongInt) : LongInt;
  stdcall; external LIB_NAME;

function  MH_OpenDevice            (devidx : LongInt; serial : pAnsiChar) : LongInt;
  stdcall; external LIB_NAME;
function  MH_CloseDevice           (devidx : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_Initialize            (devidx : LongInt; mode : LongInt; refsource : LongInt) : LongInt;
  stdcall; external LIB_NAME;

// all functions below can only be used after HH_Initialize

function  MH_GetHardwareInfo       (devidx : LongInt; model : pAnsiChar; partno : pAnsiChar; version : pAnsiChar) : LongInt;
  stdcall; external LIB_NAME;
function  MH_GetSerialNumber       (devidx : LongInt; serial : pAnsiChar) : LongInt;
  stdcall; external LIB_NAME;
function MH_GetFeatures            (devidx : LongInt; var features : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_GetBaseResolution     (devidx : LongInt; var resolution : Double; var binsteps : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_GetNumOfInputChannels (devidx : LongInt; var nchannels : LongInt) : LongInt;
  stdcall; external LIB_NAME;

function  MH_SetSyncDiv            (devidx : LongInt; syncdiv : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function MH_SetSyncEdgeTrg         (devidx : LongInt; level : LongInt; edge : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_SetSyncChannelOffset  (devidx : LongInt; value : LongInt) : LongInt;
  stdcall; external LIB_NAME;

function MH_SetInputEdgeTrg        (devidx : LongInt; channel : LongInt; level : LongInt; edge : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_SetInputChannelOffset (devidx : LongInt; channel : LongInt; value : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_SetInputChannelEnable (devidx : LongInt; channel : LongInt; enable : LongInt) : LongInt;
  stdcall; external LIB_NAME;

function  MH_SetStopOverflow       (devidx : LongInt; stop_ovfl : LongInt; stopcount : LongWord) : LongInt;
  stdcall; external LIB_NAME;
function  MH_SetBinning            (devidx : LongInt; binning : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_SetOffset             (devidx : LongInt; offset : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_SetHistoLen           (devidx : LongInt; lencode : LongInt; var actuallen : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_SetMeasControl        (devidx : LongInt; control : LongInt; startedge : LongInt; stopedge : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_SetTriggerOutput      (devidx : LongInt; period: LongInt) : LongInt;
  stdcall; external LIB_NAME;

function  MH_ClearHistMem          (devidx : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_StartMeas             (devidx : LongInt; tacq : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_StopMeas              (devidx : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_CTCStatus             (devidx : LongInt; var ctcstatus : LongInt) : LongInt;
  stdcall; external LIB_NAME;

function  MH_GetHistogram          (devidx : LongInt; var chcount : LongWord; channel : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_GetAllHistograms      (devidx : LongInt; var chcount : LongWord) : LongInt;
  stdcall; external LIB_NAME;
function  MH_GetResolution         (devidx : LongInt; var resolution : Double) : LongInt;
  stdcall; external LIB_NAME;
function  MH_GetSyncPeriod         (devidx : LongInt; var period : Double) : LongInt;
  stdcall; external LIB_NAME;
function  MH_GetSyncRate           (devidx : LongInt; var syncrate : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_GetCountRate          (devidx : LongInt; channel : LongInt; var cntrate : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_GetAllCountRates      (devidx : LongInt; var syncrate : LongInt; var cntrates : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_GetFlags              (devidx : LongInt; var flags : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_GetElapsedMeasTime    (devidx : LongInt; var elapsed : Double) : LongInt;
  stdcall; external LIB_NAME;
function  MH_GetStartTime          (devidx : LongInt; var timedw2 : LongWord; var timedw1 : LongWord; var timedw0 : LongWord) : LongInt;
  stdcall; external LIB_NAME;

function  MH_GetWarnings           (devidx : LongInt; var warnings : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_GetWarningsText       (devidx : LongInt; text : pAnsiChar; warnings : LongInt) : LongInt;
  stdcall; external LIB_NAME;

// for the time tagging modes only
function  MH_SetMarkerHoldoffTime  (devidx : LongInt; holdofftime : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_SetMarkerEdges        (devidx : LongInt; me1 : LongInt; me2 : LongInt; me3 : LongInt; me4 : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_SetMarkerEnable       (devidx : LongInt; en1 : LongInt; en2 : LongInt; en3 : LongInt; en4 : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_ReadFiFo              (devidx : LongInt; var buffer : LongWord; var nactual : LongInt) : LongInt;
  stdcall; external LIB_NAME;

//for debugging only
function  MH_GetDebugInfo          (devidx : LongInt; debuginfo : pAnsiChar) : LongInt;
  stdcall; external LIB_NAME;
function  MH_GetNumOfModules       (devidx : LongInt; var nummod : LongInt) : LongInt;
  stdcall; external LIB_NAME;
function  MH_GetModuleInfo         (devidx : LongInt; modidx : LongInt; var modelcode : LongInt; var versioncode : LongInt) : LongInt;
  stdcall; external LIB_NAME;

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