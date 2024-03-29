# Demo for access to MultiHarp 150/160 hardware via MHLIB v3.1.
# The program performs a measurement based on hard coded settings.
# The resulting histogram (65536 channels) is stored in an ASCII output file.
#
# Keno Goertz, PicoQuant GmbH, July 2019
# Michael Wahl, PicoQuant GmbH, May 2020, March 2021
# Revised Stefan Eilers, PicoQuant GmbH, March 2022

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
MODE_HIST = 0
MAXLENCODE = 6
MAXINPCHAN = 64
MAXHISTLEN = 65536
FLAG_OVERFLOW = 0x0001

# Measurement parameters, these are hardcoded since this is just a demo
binning = 0 # you can change this
offset = 0
tacq = 1000 # Measurement time in millisec, you can change this
syncDivider = 1 # you can change this 

syncTriggerEdge = 0 # you can change this, can be set to 0 or 1 
syncTriggerLevel = -50 # you can change this (in mV) 
syncChannelOffset = -5000 # you can change this (in ps, like a cable delay)
inputTriggerEdge = 0 # you can change this, can be set to 0 or 1  
inputTriggerLevel = -50 # you can change this (in mV)
inputChannelOffset = 0 # you can change this (in ps, like a cable delay)

cmd = 0

# Variables to store information read from DLLs
counts = [(ct.c_uint * MAXHISTLEN)() for i in range(0, MAXINPCHAN)]
dev = []
libVersion = ct.create_string_buffer(b"", 8)
hwSerial = ct.create_string_buffer(b"", 8)
hwPartno = ct.create_string_buffer(b"", 8)
hwVersion = ct.create_string_buffer(b"", 8)
hwModel = ct.create_string_buffer(b"", 24)
errorString = ct.create_string_buffer(b"", 40)
numChannels = ct.c_int()
histLen = ct.c_int()
resolution = ct.c_double()
syncRate = ct.c_int()
countRate = ct.c_int()
flags = ct.c_int()
warnings = ct.c_int()
warningstext = ct.create_string_buffer(b"", 16384)

if os.name == "nt":
    mhlib = ct.WinDLL("mhlib64.dll")
else:
    mhlib = ct.CDLL("libmh150.so")

def closeDevices():
    for i in range(0, MAXDEVNUM):
        mhlib.MH_CloseDevice(ct.c_int(i))
    sys.exit(0)

def tryfunc(retcode, funcName):
    if retcode < 0:
        mhlib.MH_GetErrorString(errorString, ct.c_int(retcode))
        print("MH_%s error %d (%s). Aborted." % (funcName, retcode,
              errorString.value.decode("utf-8")))
        closeDevices()

mhlib.MH_GetLibraryVersion(libVersion)
print("Library version is %s" % libVersion.value.decode("utf-8"))
if libVersion.value.decode("utf-8") != LIB_VERSION:
    print("Warning: The application was built for version %s" % LIB_VERSION)

outputfile = open("histomode.out", "w+")

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
    print("No device available.")
    exit(0)
print("Using device #%1d" % dev[0])
print("\nInitializing the device...")

# Histo mode with internal clock
tryfunc(mhlib.MH_Initialize(ct.c_int(dev[0]), ct.c_int(MODE_HIST), ct.c_int(0)),
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
        "SetSyncChannelOffset")

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
    )

tryfunc(mhlib.MH_SetHistoLen(ct.c_int(dev[0]), ct.c_int(MAXLENCODE), byref(histLen)),
        "SetHistoLen")
print("Histogram length is %d" % histLen.value)

tryfunc(mhlib.MH_SetBinning(ct.c_int(dev[0]), ct.c_int(binning)), "SetBinning")
tryfunc(mhlib.MH_SetOffset(ct.c_int(dev[0]), ct.c_int(offset)), "SetOffset")
tryfunc(mhlib.MH_GetResolution(ct.c_int(dev[0]), byref(resolution)), "GetResolution")
print("Resolution is %1.1lfps" % resolution.value)

# Note: after Init or SetSyncDiv you must allow >100 ms for valid  count rate readings
time.sleep(0.2)

tryfunc(mhlib.MH_GetSyncRate(ct.c_int(dev[0]), byref(syncRate)), "GetSyncRate")
print("\nSyncrate=%1d/s" % syncRate.value)

for i in range(0, numChannels.value):
    tryfunc(mhlib.MH_GetCountRate(ct.c_int(dev[0]), ct.c_int(i), byref(countRate)),
            "GetCountRate")
    print("Countrate[%1d]=%1d/s" % (i, countRate.value))

# After getting the count rates you can check for warnings
tryfunc(mhlib.MH_GetWarnings(ct.c_int(dev[0]), byref(warnings)), "GetWarnings")
if warnings.value != 0:
    mhlib.MH_GetWarningsText(ct.c_int(dev[0]), warningstext, warnings)
    print("\n\n%s" % warningstext.value.decode("utf-8")) 

tryfunc(mhlib.MH_SetStopOverflow(ct.c_int(dev[0]), ct.c_int(0), ct.c_int(10000)),
        "SetStopOverflow") # for example only

while cmd != "q":
    tryfunc(mhlib.MH_ClearHistMem(ct.c_int(dev[0])), "ClearHistMem")

    input("press RETURN to start measurement"); print

    tryfunc(mhlib.MH_GetSyncRate(ct.c_int(dev[0]), byref(syncRate)), "GetSyncRate")
    print("Syncrate=%1d/s" % syncRate.value)

    for i in range(0, numChannels.value):
        tryfunc(mhlib.MH_GetCountRate(ct.c_int(dev[0]), ct.c_int(i), byref(countRate)),
                "GetCountRate")
        print("Countrate[%1d]=%1d/s" % (i, countRate.value))

    # here you could check for warnings again
    
    tryfunc(mhlib.MH_StartMeas(ct.c_int(dev[0]), ct.c_int(tacq)), "StartMeas")
    print("\nMeasuring for %1d milliseconds..." % tacq)
    
    ctcstatus = ct.c_int(0)
    while ctcstatus.value == 0:
        tryfunc(mhlib.MH_CTCStatus(ct.c_int(dev[0]), byref(ctcstatus)),
                "CTCStatus")
        
    tryfunc(mhlib.MH_StopMeas(ct.c_int(dev[0])), "StopMeas")
    
    for i in range(0, numChannels.value):
        tryfunc(
            mhlib.MH_GetHistogram(ct.c_int(dev[0]), byref(counts[i]),
                                  ct.c_int(i)),
            "GetHistogram"
        )

        integralCount = 0
        for j in range(0, histLen.value):
            integralCount += counts[i][j]
    
        print("  Integralcount[%1d]=%1.0lf" % (i,integralCount))

    tryfunc(mhlib.MH_GetFlags(ct.c_int(dev[0]), byref(flags)), "GetFlags")
    
    if flags.value & FLAG_OVERFLOW > 0:
        print("  Overflow.")

    print("Enter c to continue or q to quit and save the count data.")
    cmd = input()

for j in range(0, histLen.value):
    for i in range(0, numChannels.value):
        outputfile.write("%5d " % counts[i][j])
    outputfile.write("\n")

closeDevices()
outputfile.close()
