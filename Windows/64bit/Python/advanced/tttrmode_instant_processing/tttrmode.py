# MultiHarp 150/160  MHLIB v3.1.  Usage Demo with Python

# The program performs a measurement based on hard coded settings.
# The resulting data is stored in a ASCII output file.

# Keno Goertz, PicoQuant GmbH, July 2019
# Michael Wahl, PicoQuant GmbH, May 2020, March 2021
# Stefan Eilers, PicoQuant GmbH, Mar 2022

#   Tested with
#    - Spyder 5.1.5/Python 3.9.7 on Windows 10
     
#   Note: This is a console application (i.e. run in Windows cmd box)
#   Note: At the API level channel numbers are indexed 0..N-1
#         where N is the number of channels the device has.
#   Note: This demo writes only raw event data to the output file.
#         It does not write a file header as regular .ptu files have it.       

import time
import ctypes as ct
from ctypes import byref
import os
import sys

if sys.version_info[0] < 3:
    print("[Warning] Python 2 is not fully supported. It might work, but "
          "use Python 3 if you encounter errors.\n")
    raw_input("press RETURN to continue"); print

# From mhdefin.h
LIB_VERSION = "3.1"
MAXDEVNUM = 8
MODE_T2 = 2
MODE_T3 = 3
MAXLENCODE = 6
MAXINPCHAN = 64
TTREADMAX = 1048576
FLAG_OVERFLOW = 0x0001
FLAG_FIFOFULL = 0x0002

# Measurement parameters, these are hardcoded since this is just a demo
mode = MODE_T3 # set T2 or T3 here, observe suitable Syncdivider and Range!
binning = 4 # you can change this, meaningful only in T3 mode
offset = 0 # you can change this, meaningful only in T3 mode
tacq = 500 # Measurement time in millisec, you can change this
syncDivider = 1 # you can change this, observe mode! READ MANUAL!

syncTriggerEdge = 0 # you can change this, can be set to 0 or 1 
syncTriggerLevel = -50 # you can change this (in mV) 
syncChannelOffset = 0 # you can change this (in ps, like a cable delay)
inputTriggerEdge = 0 # you can change this, can be set to 0 or 1  
inputTriggerLevel = -50 # you can change this (in mV)
inputChannelOffset = 5000 # you can change this (in ps, like a cable delay)

# Variables to store information read from DLLs
buffer = (ct.c_uint * TTREADMAX)()
dev = []
libVersion = ct.create_string_buffer(b"", 8)
hwSerial = ct.create_string_buffer(b"", 8)
hwPartno = ct.create_string_buffer(b"", 8)
hwVersion = ct.create_string_buffer(b"", 8)
hwModel = ct.create_string_buffer(b"", 24)
errorString = ct.create_string_buffer(b"", 40)
numChannels = ct.c_int()
resolution = ct.c_double()
syncRate = ct.c_int()
Syncperiod = ct.c_double()
countRate = ct.c_int()
flags = ct.c_int()
recNum = ct.c_int()
nRecords = ct.c_int()
ctcstatus = ct.c_int()
warnings = ct.c_int()
warningstext = ct.create_string_buffer(b"", 16384)
TimeTag = ct.c_int()
Channel = ct.c_int()
Markers = ct.c_int()
DTime = ct.c_int()
Special = ct.c_int()
oflcorrection = ct.c_int()
progress = ct.c_int()

# Got PhotonT2
# TimeTag: Overflow-corrected arrival time in units of the device's base resolution 
# Channel: Channel the photon arrived (0 = Sync channel, 1..N = regular timing channel)
def GotPhotonT2(TimeTag, Channel):
    global outputfile, resolution
    outputfile.write("CH %2d %14.0lf\n" % (Channel, TimeTag * resolution.value))

# Got MarkerT2
# TimeTag: Overflow-corrected arrival time in units of the device's base resolution 
# Markers: Bitfield of arrived markers, different markers can arrive at same time (same record)   
def GotMarkerT2(TimeTag, Markers):
    global outputfile, resolution
    outputfile.write("MK %2d %14.0lf\n" % (Markers, TimeTag * resolution.value))

# Got PhotonT3
# TimeTag: Overflow-corrected arrival time in units of the sync period 
# DTime: Arrival time of photon after last Sync event in units of the chosen resolution (set by binning)
# Channel: 1..N where N is the numer of channels the device has
def GotPhotonT3(truensync, Channel, DTime):
    global outputfile, Syncperiod, resolution
    outputfile.write("CH %2d %10.8lf %8.0lf\n" % (Channel, 
                                                  truensync * Syncperiod.value,
                                                  DTime   * resolution.value))
    
# Got MarkerT3
# TimeTag: Overflow-corrected arrival time in units of the sync period 
# Markers: Bitfield of arrived Markers, different markers can arrive at same time (same record)    
def GotMarkerT3(truensync, Markers):
    global outputfile, Syncperiod
    outputfile.write("MK %2d %10.8lf\n" % (Markers, truensync * Syncperiod.value)) 
    
# ProcessT2
# HydraHarpV2 or TimeHarp260 or MultiHarp T2 record data
def ProcessT2(TTTRRecord):
    global outputfile, recNum, nRecords, oflcorrection, Markers, Channel, Special
    ch = 0
    truetime = 0
    T2WRAPAROUND_V2 = 33554432    
    try:   
        # The data handed out to this function is transformed to an up to 32 digits long binary number
        # and this binary is filled by zeros from the left up to 32 bit
        recordDatabinary = '{0:0{1}b}'.format(TTTRRecord,32)
    except:
        print("\nThe file ended earlier than expected, at record %d/%d."\
          % (recNum.value, nRecords.value))
        sys.exit(0)
        
    # Then the different parts of this 32 bit are splitted and handed over to the Variables       
    Special = int(recordDatabinary[0:1], base=2) # 1 bit for Special    
    Channel = int(recordDatabinary[1:7], base=2) # 6 bit for Channel
    TimeTag = int(recordDatabinary[7:32], base=2) # 25 bit for TimeTag

        
    if Special==1:
        if Channel == 0x3F: # Special record, including Overflow as well as Markers and Sync
        
            # number of overflows is stored in timetag
            if TimeTag == 0: # if it is zero it is an old style single overflow 
                oflcorrection += T2WRAPAROUND_V2
            else:
                oflcorrection += T2WRAPAROUND_V2 * TimeTag
        if Channel>=1 and Channel<=15: # Markers
            truetime = oflcorrection + T2WRAPAROUND_V2 * TimeTag
            #Note that actual marker tagging accuracy is only some ns
            ch = Channel
            GotMarkerT2(truetime, ch)
        if Channel==0: # Sync
            truetime = oflcorrection + TimeTag
            ch = 0 # we encode the sync channel as 0
            GotPhotonT2(truetime, ch)
    else: # regular input channel
        truetime = oflcorrection + TimeTag
        ch = Channel + 1 # we encode the regular channels as 1..N        
        GotPhotonT2(truetime, ch)
    
# ProcessT3
# HydraHarpV2 or TimeHarp260 or MultiHarp T3 record data
def ProcessT3(TTTRRecord):
    global outputfile, recNum, nRecords, oflcorrection#, Markers, Channel, Special, DTime
    ch = 0
    dt = 0
    truensync = 0
    T3WRAPAROUND = 1024
    try:
        recordDatabinary = "{0:0{1}b}".format(TTTRRecord, 32)
    except:
        print("The file ended earlier than expected, at record %d/%d."\
          % (recNum, nRecords))
        sys.exit(0)
    
    Special = int(recordDatabinary[0:1], base=2) # 1 bit for Special
    Channel = int(recordDatabinary[1:7], base=2) # 6 bit for Channel     
    DTime = int(recordDatabinary[7:22], base=2) # 15 bit for DTime   
    nSync = int(recordDatabinary[22:32], base=2) # nSync is number of the Sync period, 10 bit for nSync
    
    if Special==1:
        if Channel == 0x3F: # Special record, including Overflow as well as Markers and Sync
        
            # number of overflows is stored in timetag
            if nSync == 0: # if it is zero it is an old style single overflow 
                oflcorrection += T3WRAPAROUND
            else:
                oflcorrection += T3WRAPAROUND * nSync
        if Channel>=1 and Channel<=15: # Markers
            truensync = oflcorrection + T3WRAPAROUND * nSync
            #Note that the time unit depends on sync period
            GotMarkerT3(truensync, Channel)

    else: # regular input channel
        truensync = oflcorrection + nSync
        ch = Channel + 1 # we encode the regular channels as 1..N 
        dt = DTime
        # truensync indicates the number of the sync period this event was in
        # the dtime unit depends on the chosen resolution (binning)
        GotPhotonT3(truensync, ch, dt)        


if os.name == "nt":
    mhlib = ct.WinDLL("mhlib64.dll") 
else:
    mhlib = ct.CDLL("libmh150.so")


def closeDevices():
    for i in range(0, MAXDEVNUM):
        mhlib.MH_CloseDevice(ct.c_int(i))
    sys.exit(0)

def stoptttr():
    retcode = mhlib.MH_StopMeas(ct.c_int(dev[0]))
    if retcode < 0:
        print("MH_StopMeas error %1d. Aborted." % retcode)
    closeDevices()

def tryfunc(retcode, funcName, measRunning=False):
    if retcode < 0:
        mhlib.MH_GetErrorString(errorString, ct.c_int(retcode))
        print("MH_%s error %d (%s). Aborted." % (funcName, retcode,
              errorString.value.decode("utf-8")))
        if measRunning:
            stoptttr()
        else:
            closeDevices()
            
print("\nMultiHarp MHLib Demo Application                      PicoQuant GmbH, 2022")
print("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
mhlib.MH_GetLibraryVersion(libVersion)
print("Library version is %s" % libVersion.value.decode("utf-8"))
if libVersion.value.decode("utf-8") != LIB_VERSION:
    print("Warning: The application was built for version %s" % LIB_VERSION)

outputfile = open("tttrmodeout.txt", "w")

print("\n");

print("Mode              : %d" % mode)
print("Binning           : %d" % binning)
print("Offset            : %d" % offset)
print("AcquisitionTime   : %d" % tacq)
print("SyncDivider       : %d" % syncDivider)
print("syncTriggerEdge   : %d" % syncTriggerEdge)
print("SyncTriggerLevel  : %d" % syncTriggerLevel)
print("SyncChannelOffset : %d" % syncChannelOffset)
print("InputTriggerEdge  : %d" % inputTriggerEdge)
print("InputTriggerLevel : %d" % inputTriggerLevel)
print("InputChannelOffset: %d" % inputChannelOffset)

print("\nSearching for MultiHarp devices...")
print("Devidx     Status")

for i in range(0, MAXDEVNUM):
    retcode = mhlib.MH_OpenDevice(ct.c_int(i), hwSerial)
    if retcode == 0:
        print("  %1d        S/N %s" % (i, hwSerial.value.decode("utf-8")))
        dev.append(i)
    else:
        if retcode == -1: # MH_ERROR_DEVICE_OPEN_FAIL
            print("  %1d        no device" % i)
        else:
            mhlib.MH_GetErrorString(errorString, ct.c_int(retcode))
            print("  %1d        %s" % (i, errorString.value.decode("utf8")))

# In this demo we will use the first MultiHarp device we find, i.e. dev[0].
# You can also use multiple devices in parallel.
# You can also check for specific serial numbers, so that you always know 
# which physical device you are talking to.

if len(dev) < 1:
    print("\nNo device available.")
    closeDevices()
print("\nUsing device #%1d" % dev[0])
print("\nInitializing the device...\n")

# with internal clock
tryfunc(mhlib.MH_Initialize(ct.c_int(dev[0]), ct.c_int(mode), ct.c_int(0)),
        "Initialize")

# Only for information
tryfunc(mhlib.MH_GetHardwareInfo(dev[0], hwModel, hwPartno, hwVersion),
        "GetHardwareInfo")
print("Found Model %s Part no %s Version %s" % (hwModel.value.decode("utf-8"),
      hwPartno.value.decode("utf-8"), hwVersion.value.decode("utf-8")))

tryfunc(mhlib.MH_GetNumOfInputChannels(ct.c_int(dev[0]), byref(numChannels)),
        "GetNumOfInputChannels")
print("Device has %i input channels." % numChannels.value)

tryfunc(mhlib.MH_SetSyncDiv(ct.c_int(dev[0]), ct.c_int(syncDivider)), "SetSyncDiv")

tryfunc(
    mhlib.MH_SetSyncEdgeTrg(ct.c_int(dev[0]), ct.c_int(syncTriggerLevel),
                            ct.c_int(syncTriggerEdge)),
    "SetSyncEdgeTrg"
    )

tryfunc(mhlib.MH_SetSyncChannelOffset(ct.c_int(dev[0]), ct.c_int(syncChannelOffset)),
        "SetSyncChannelOffset") # in ps, emulate a cable delay

# we use the same input settings for all channels, you can change this
for i in range(0, numChannels.value):
    tryfunc(
        mhlib.MH_SetInputEdgeTrg(ct.c_int(dev[0]), ct.c_int(i), ct.c_int(inputTriggerLevel),
                                 ct.c_int(inputTriggerEdge)),
        "SetInputEdgeTrg"
    )

    tryfunc(
        mhlib.MH_SetInputChannelOffset(ct.c_int(dev[0]), ct.c_int(i),
                                       ct.c_int(inputChannelOffset)),
        "SetInputChannelOffset"
    )# in ps, emulate a cable delay


# Meaningful only in T3 mode
if mode == MODE_T3:
    tryfunc(mhlib.MH_SetBinning(ct.c_int(dev[0]), ct.c_int(binning)), "SetBinning")
    tryfunc(mhlib.MH_SetOffset(ct.c_int(dev[0]), ct.c_int(offset)), "SetOffset")
    
tryfunc(mhlib.MH_GetResolution(ct.c_int(dev[0]), byref(resolution)), "GetResolution")
print("Resolution is %1.1lfps" % resolution.value)

# Note: after Init or SetSyncDiv you must allow >100 ms for valid  count rate readings
time.sleep(0.15)# in s

tryfunc(mhlib.MH_GetSyncRate(ct.c_int(dev[0]), byref(syncRate)), "GetSyncRate")
print("\nSyncrate=%1d/s" % syncRate.value)

for i in range(0, numChannels.value):
    tryfunc(mhlib.MH_GetCountRate(ct.c_int(dev[0]), ct.c_int(i), byref(countRate)),
            "GetCountRate")
    print("Countrate[%1d]=%1d/s" % (i, countRate.value))
# after getting the count rates you can check for warnings
    

if mode == MODE_T2:
    outputfile.write("ev chn time/ps\n\n")
else:
    outputfile.write("ev chn ttag/s dtime/ps\n\n")

if sys.version_info[0] < 3:
    raw_input("\nPress RETURN to start"); print
else:
    input("\nPress RETURN to start"); print





tryfunc(mhlib.MH_StartMeas(ct.c_int(dev[0]), ct.c_int(tacq)), "StartMeas")

if mode == MODE_T3:
    # We need the sync period in order to calculate the true times of photon records.
    # This only makes sense in T3 mode and it assumes a stable period like from a laser.
    # Note: Two sync periods must have elapsed after MH_StartMeas to get proper results.
    # You can also use the inverse of what you read via GetSyncRate but it depends on
    # the actual sync rate if this is accurate enough.
    # It is OK to use the sync input for a photon detector, e.g. if you want to perform
    # something like an antibunching measurement. In that case the sync rate obviously is
    # not periodic. This means that a) you should set the sync divider to 1 (none) and
    # b) that you cannot meaningfully measure the sync period here, which probaly won't
    # matter as you only care for the time difference(dtime) of the events.
    tryfunc(mhlib.MH_GetSyncPeriod(ct.c_int(dev[0]), byref(Syncperiod)), "GetSyncPeriod")
    print("\nSync period is %12.9lf s\n" % (Syncperiod.value ))
    
print("\nStarting data collection...\n")    

progress = 0
sys.stdout.write("\nProgress:%9u" % progress)
sys.stdout.flush()

oflcorrection = 0

while True:
    tryfunc(mhlib.MH_GetFlags(ct.c_int(dev[0]), byref(flags)), "GetFlags")
    
    if flags.value & FLAG_FIFOFULL > 0:
        print("\nFiFo Overrun!")
        stoptttr()
    
    tryfunc(
        mhlib.MH_ReadFiFo(ct.c_int(dev[0]), byref(buffer), byref(nRecords)),
        "ReadFiFo", measRunning=True
    )

    # Here we process the data. Note that the time this consumes prevents us
    # from getting around the loop quickly for the next Fifo read.
    # In a serious performance critical scenario you would write the data to
    # a software queue and do the processing in another thread reading from
    # that queue.
    if nRecords.value > 0:        
        if mode == MODE_T2:
            for i in range(0,nRecords.value):
                ProcessT2(buffer[i])                
        else:
            for i in range(0,nRecords.value):
                ProcessT3(buffer[i])
            
        progress += nRecords.value
        sys.stdout.write("\rProgress:%9u" % progress)
        sys.stdout.flush()
    else:
        tryfunc(mhlib.MH_CTCStatus(ct.c_int(dev[0]), byref(ctcstatus)),
                "CTCStatus")
        if ctcstatus.value > 0: 
            print("\nDone")
            outputfile.close()
            stoptttr()
    # within this loop you can also read the count rates if needed.

closeDevices()
outputfile.close()
if sys.version_info[0] < 3:
    raw_input("\nPress RETURN to exit"); print
else:
    input("\nPress RETURN to exit"); print

