# MultiHarp 150/160  MHLIB v3.1.  Usage Demo with Python

#     The resulting photon event data is instantly histogrammed. T3 mode only!
#     The resulting data is stored in an ASCII output file.

#     The program performs a TTTR measurement based on hard-coded settings.
#     Event data is filtered by the device's main event filter in the FPGA.
#     Actually there are two such filters: Main Filter and Row Filter.
#     The Main Filter operates on all input channels of the device and it is
#     the recommended starting point for work with event filtering.
#     The Row Filter operates only on one vertical row of input channels.
#     It is of interest only if you need to work with very high count rates. 
#     Please read the manual for details. 
#     The purpose of this demo is to show the software calls for setting the
#     Main Filter parameters and activating the Main Filter.
        

# Keno Goertz, PicoQuant GmbH, July 2019
# Michael Wahl, PicoQuant GmbH, May 2020, March 2021
# Stefan Eilers, PicoQuant GmbH, Mar 2022

# Tested with
#    - Spyder 5.1.5 with Python 3.9.7 on Windows 10
     
#   Note: At the API level channel numbers are indexed 0..N-1
#         where N is the number of channels the device has.
#   Note: This demo writes only raw event data to the output file.
#         It does not write a file header as regular .ptu files have it.       

import time
import ctypes as ct
from ctypes import byref
import os
import sys
import numpy as np 

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
binning = 1 # you can change this, meaningful only in T3 mode
offset = 0 # you can change this, meaningful only in T3 mode
tacq = 250 # Measurement time in millisec, you can change this
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

# Main Event Filter variables

#   The following variables are for programming the Main Event Filter.
#   For the sake of consistency at API level both filters are organized
#   by rows of channels. MAXROWS is the largest number of input rows
#   a MultiHarp device can have.
#   Please read the manual on what the filter parameters are about.
#   Here we implement a simple "Singles Filter" which is the most obvious 
#   and most useful type of event filter in typical quantum optics applications.
#   The idea is that photon events that are "single" in the sense that there is no 
#   other event in temporal proximity (within timerange) will be filtered out.
#   This reduces the bus load and the file size if you write the records to a file.
#   Any further (application specific) coincidence processing will eventually be 
#   done in software, either on the fly or subsequently on the stored data.
#   The Row Filters are off by default and we will not touch them here.

MAXROWS = 8    # largest possible number of input rows
inputrows = 0  # actual number of rows, we determine this later
mainfilter_timerange = 10000; # in picoseconds
mainfilter_matchcnt = 1      # must have at least one other event in proximity
mainfilter_inverse = 1       # normal filtering mode, see manual
mainfilter_enable = 0        # activate the filter with 1, deactivate with 0
mainfilter_usechans = [0xF,0,0,0,0,0,0,0]  # bitmasks for which channels are to be used ,we use only the first four channels
mainfilter_passchans = [0,0,0,0,0,0,0,0]   # bitmasks for which channels to pass unfiltered, we do not pass any channels unfiltered

# The following are count rate buffers for the filter test further down
ftestsyncrate = ct.c_int()          
ftestchanrates = (ct.c_int*64)()
ftestsumrate = ct.c_int()

# Histogramming variables
T3HISTBINS = 32768 #  is 2^15, dtime in T3 mode has 15 bits
histogram = np.zeros((MAXINPCHAN, T3HISTBINS)) # array with 32768 bins and up to 64 channels

# Got PhotonT2
# TimeTag: Overflow-corrected arrival time in units of the device's base resolution 
# Channel: Channel the photon arrived (0 = Sync channel, 1..N = regular timing channel)
def GotPhotonT2(TimeTag, Channel):
    pass

# Got MarkerT2
# TimeTag: Overflow-corrected arrival time in units of the device's base resolution 
# Markers: Bitfield of arrived markers, different markers can arrive at same time (same record)    
def GotMarkerT2(TimeTag, Markers):
    pass

# Got PhotonT3
# TimeTag: Overflow-corrected arrival time in units of the sync period 
# DTime: Arrival time of photon after last Sync event in units of the chosen resolution (set by binning)
# Channel: 1..N where N is the numer of channels the device has
def GotPhotonT3(truensync, Channel, DTime):
        
    histogram[Channel, DTime] = histogram[Channel, DTime] + 1 # histogramming

# Got MarkerT3
# TimeTag: Overflow-corrected arrival time in units of the sync period 
# Markers: Bitfield of arrived Markers, different markers can arrive at same time (same record)    
def GotMarkerT3(truensync, Markers):
    pass
    
# ProcessT2
# HydraHarpV2 or TimeHarp260 or MultiHarp T2 record data
def ProcessT2(TTTRRecord):
    global recNum, nRecords, oflcorrection, Markers, Channel, Special
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
    global recNum, nRecords, oflcorrection#, Markers, Channel, Special, DTime
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
            # number of overflows is stored in nSync
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
    mhlib = ct.WinDLL("mhlib.dll")
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


# Main Event Filter 
# Here we program the Main Filter 
inputrows = int(numChannels.value/8) # a MultiHarp has 8 channels per row
if numChannels.value==4:         # except it is a 4-channel model  
    inputrows = 1;
for i in range(0,inputrows):
    tryfunc(mhlib.MH_SetMainEventFilterChannels(ct.c_int(dev[0]), ct.c_int(i),
                                                ct.c_int(mainfilter_usechans[i]),
                                                ct.c_int(mainfilter_passchans[i])),
            "SetMainEventFilterChannels")

tryfunc(mhlib.MH_SetMainEventFilterParams(ct.c_int(dev[0]), mainfilter_timerange,
                                          mainfilter_matchcnt, mainfilter_inverse),
        "SetMainEventFilterParam")
tryfunc(mhlib.MH_EnableMainEventFilter(ct.c_int(dev[0]), mainfilter_enable),"EnableMainEventFilter")

# Filter programming ends here


# Note: after Init or SetSyncDiv you must allow >100 ms for valid  count rate readings
# Subsequently you get new values after every 100ms
# The same applies to the filter test below.
time.sleep(0.2)# in s

print("\nMeasuring input rates...\n");

tryfunc(mhlib.MH_GetSyncRate(ct.c_int(dev[0]), byref(syncRate)), "GetSyncRate")
print("\nSyncrate=%1d/s" % syncRate.value)

for i in range(0, numChannels.value):
    tryfunc(mhlib.MH_GetCountRate(ct.c_int(dev[0]), ct.c_int(i), byref(countRate)),
            "GetCountRate")
    print("Countrate[%1d]=%1d/s" % (i, countRate.value))
    

# Main Filter test
#   Now we perform a filter test. This is not strictly necessary but helpful
#   when the overall count rate is over the USB troughput limit and you wish to
#   use the filter to alleviate this.
#   The filter test consists of just a simple retrievel of input and output rates 
#   of the filter(s), so that you can assess its effect in terms of rate reduction.
#   You can do this a few times in a loop, so that you can also see if there are 
#   significant fluctuations. However, note that for each round you will need to 
#   wait for at least 100ms to get new results.
#   The filter test must be performed while measurement is running. In order
#   to avoid FiFo buffer overruns we can use MH_SetFilterTestMode to disable the
#   transfer of meaurement data into the FiFo.
tryfunc(mhlib.MH_SetFilterTestMode(dev[0], 1),"SetFilterTestMode") # disable FiFo input
tryfunc(mhlib.MH_StartMeas(ct.c_int(dev[0]), ct.c_int(tacq)),"StartMeas") # longest possible time, we will stop manually
        
time.sleep(0.2) # allow the hardware at least 100ms time for rate counting 

# To start with, we retrieve the front end count rates. This is somewhat redundant 
# here as we already retrieved them above. However, for demonstration purposes, 
# this time we use a more efficient method that fetches all rates in one go.
ftestsumrate = 0           
tryfunc(mhlib.MH_GetAllCountRates(ct.c_int(dev[0]), byref(ftestsyncrate), ftestchanrates),"GetAllCountRates") 

# We only care about the overall rates, so we sum them up here.
for i in range(0,numChannels.value):  
    ftestsumrate = ftestsumrate + ftestchanrates[i]   
if mode == MODE_T2:
    ftestsumrate = ftestsumrate + ftestsyncrate.value
print('\nFront end input rate = ', ftestsumrate, '/s')
    
# Although we are not using the Row Filter here, it is useful to retrieve its outout 
# rates as it is the input to the Main Filter. This is not necessarily the same as
# the front end count rates as there may already have been losses due to front end 
# troughput limits. We do the same summation as above.
ftestsumrate = 0
tryfunc(mhlib.MH_GetRowFilteredRates(ct.c_int(dev[0]), byref(ftestsyncrate), ftestchanrates),"GetRowFilteredRates")
for i in range(0,numChannels.value):
    ftestsumrate = ftestsumrate + ftestchanrates[i]
if mode == MODE_T2:
    ftestsumrate = ftestsumrate + ftestsyncrate.value
print('Main Filter input rate = ', ftestsumrate, '/s')    

# Now we do the same rate retrieval and summation for the Main Filter output.
ftestsumrate = 0
tryfunc(mhlib.MH_GetMainFilteredRates(ct.c_int(dev[0]), byref(ftestsyncrate), ftestchanrates),"GetMainFilteredRates")
for i in range(0,numChannels.value):        
    ftestsumrate = ftestsumrate + ftestchanrates[i]
if mode == MODE_T2:
    ftestsumrate = ftestsumrate + ftestsyncrate.value
print('Main Filter output rate = ', ftestsumrate, '/s') 

tryfunc(mhlib.MH_StopMeas(ct.c_int(dev[0])),"StopMeas") # test finished, stop measurement

#Testmode must be switched off again to allow a real measurement
tryfunc(mhlib.MH_SetFilterTestMode(ct.c_int(dev[0]), 0),"SetFilterTestMode") # re-enable FiFo input)

# End of Main Filter test
# Now we begin the real measurement

if mode == MODE_T2:
    print('\nThis demo is not for use with T2 mode!\n')
else:
    histogramfile = open("histogramout.txt", "w")
    for j in range (0, numChannels.value): 
	    histogramfile.write('  ch%2u ' % j) # file head
    histogramfile.write('\n')
    
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
            retcode = mhlib.MH_StopMeas(ct.c_int(dev[0]))
            if retcode < 0:
                print("\nMH_StopMeas error %1d. Aborted." % retcode)
            print("\nDone")
            break#stoptttr()
     # within this loop you can also read the count rates if needed.


# Saving histogram data
if mode == MODE_T3:
    for i in range(0, T3HISTBINS - 1):
        for j in range(0, numChannels.value):
            histogramfile.write("%6u " % (histogram[j,i]))
        histogramfile.write("\n")
    histogramfile.close() 

if sys.version_info[0] < 3:
    raw_input("\nPress RETURN to exit"); print
else:
    input("\nPress RETURN to exit"); print 
    
closeDevices()


