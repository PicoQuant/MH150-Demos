# Demo for access to MultiHarp 150/160 hardware via MHLIB v3.1.
# The program performs a measurement based on hard coded settings.
# The resulting data is stored in a binary output file.
#
# Keno Goertz, PicoQuant GmbH, July 2019
# Michael Wahl, PicoQuant GmbH, May 2020, March 2021
# Revised Stefan Eilers, PcoQuant GmbH, March 2022

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
binning = 0 # you can change this, meaningful only in T3 mode
offset = 0 # you can change this, meaningful only in T3 mode
tacq = 1000 # Measurement time in millisec, you can change this
syncDivider = 1 # you can change this, observe mode! READ MANUAL!

syncTriggerEdge = 0 # you can change this, can be set to 0 or 1 
syncTriggerLevel = -50 # you can change this (in mV) 
syncChannelOffset = -5000 # you can change this (in ps, like a cable delay)
inputTriggerEdge = 0 # you can change this, can be set to 0 or 1  
inputTriggerLevel = -50 # you can change this (in mV)
inputChannelOffset = 0 # you can change this (in ps, like a cable delay)

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
countRate = ct.c_int()
flags = ct.c_int()
nRecords = ct.c_int()
ctcstatus = ct.c_int()
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

mhlib.MH_GetLibraryVersion(libVersion)
print("Library version is %s" % libVersion.value.decode("utf-8"))
if libVersion.value.decode("utf-8") != LIB_VERSION:
    print("Warning: The application was built for version %s" % LIB_VERSION)

outputfile = open("tttrmode.out", "wb+")

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
    print("No device available.")
    closeDevices()
print("Using device #%1d" % dev[0])
print("\nInitializing the device...")

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

# Meaningful only in T3 mode
if mode == MODE_T3:
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

progress = 0
sys.stdout.write("\nProgress:%9u" % progress)
sys.stdout.flush()

tryfunc(mhlib.MH_StartMeas(ct.c_int(dev[0]), ct.c_int(tacq)), "StartMeas")

while True:
    tryfunc(mhlib.MH_GetFlags(ct.c_int(dev[0]), byref(flags)), "GetFlags")
    
    if flags.value & FLAG_FIFOFULL > 0:
        print("\nFiFo Overrun!")
        stoptttr()
    
    tryfunc(
        mhlib.MH_ReadFiFo(ct.c_int(dev[0]), byref(buffer), byref(nRecords)),
        "ReadFiFo", measRunning=True
    )

    if nRecords.value > 0:
        # We could just iterate through our buffer with a for loop, however,
        # this is slow and might cause a FIFO overrun. So instead, we shrinken
        # the buffer to its appropriate length with array slicing, which gives
        # us a python list. This list then needs to be converted back into
        # a ctype array which can be written at once to the output file
        outputfile.write((ct.c_uint*nRecords.value)(*buffer[0:nRecords.value]))
        progress += nRecords.value
        sys.stdout.write("\rProgress:%9u" % progress)
        sys.stdout.flush()
    else:
        tryfunc(mhlib.MH_CTCStatus(ct.c_int(dev[0]), byref(ctcstatus)),
                "CTCStatus")
        if ctcstatus.value > 0: 
            print("\nDone")
            stoptttr()
    # within this loop you can also read the count rates if needed.

closeDevices()
outputfile.close()
