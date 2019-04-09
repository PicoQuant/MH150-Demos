
% Demo for access to MultiHarp 150 Hardware via MHLIB.DLL v 1.0.
% The program performs a measurement based on hard coded settings.
% The resulting histogram (65536 channels) is stored in an ASCII output file.
%
% Axel Hagen, PicoQuant, August 2018


% Constants from mhdefin.h

REQLIBVER   =     '1.0';    % this is the version this program expects
MAXDEVNUM   =         8;
MAXHISTBINS =     65536;	 % number of histogram channels
MAXLENCODE  =         6;	 % max histogram length is 65536	
MAXBINSTEPS	=    	 26;
MODE_HIST   =         0;
MODE_T2	    =         2;
MODE_T3	    =         3;

FLAG_OVERFLOW = hex2dec('0001');

TRGLVLMIN	  =       -1200;	   % mV
TRGLVLMAX	  =        1200;	   % mV
OFFSETMIN	  =           0;	   % ns
OFFSETMAX	  =   100000000;	   % ns

ACQTMIN		  =           1;	   % ms
ACQTMAX		  =   360000000;	   % ms  (100*60*60*1000ms = 100h)

% Errorcodes from errorcodes.h

MH_ERROR_DEVICE_OPEN_FAIL		 = -1;

% Settings for the measurement, Adapt to your setup!

SyncTrgEdge   =    0;     %  you can change this
SyncTrgLevel  =  -50;     %  you can change this
InputTrgEdge  =    0;     %  you can change this
InputTrgLevel =  -50;     %  you can change this
SyncDiv       =    8;     %  you can change this
Binning       =    0;     %  you can change this
Tacq          = 1000;     %  you can change this      
    
fprintf('\nMultiHarp 150 MHLib Demo Application             PicoQuant 2018\n');

if (~libisloaded('MHlib'))    
    %Attention: The header file name given below is case sensitive and must
    %be spelled exactly the same as the actual name on disk except the file 
    %extension. 
    %Wrong case will apparently do the load successfully but you will not
    %be able to access the library!
    %The alias is used to provide a fixed spelling for any further access via
    %calllib() etc, which is also case sensitive.
    %loadlibrary('Mhlib.dll',   'mhlib.h', 'alias', 'MHlib'); % Windows 32 bit
    loadlibrary('MHLib64.dll', 'mhlib.h', 'alias', 'MHlib'); % Windows 64 bit
else
    fprintf('Note: MHlib was already loaded\n');
end

if (libisloaded('MHlib'))
    fprintf('MHlib opened successfully\n');
    %libfunctionsview MHlib; %use this to test for proper loading
else
    fprintf('Could not open MHlib\n');
    return;
end
    
LibVersion    = blanks(8); %enough length!
LibVersionPtr = libpointer('cstring', LibVersion);

[ret, LibVersion] = calllib('MHlib', 'MH_GetLibraryVersion', LibVersionPtr);
if (ret<0)
    fprintf('Error in GetLibVersion. Aborted.\n');
    err = MH_GETLIBVERSION_ERROR;
else
	fprintf('MHLib version is %s\n', LibVersion);
end

if ~strcmp(LibVersion,REQLIBVER)
    fprintf('This program requires MHLib version %s\n', REQLIBVER);
    return;
end

fid = fopen('histomode.out','w');
if (fid<0)
    fprintf('Cannot open output file\n');
    return;
end

 fprintf(fid,'Binning           : %ld\n',Binning);
 fprintf(fid,'AcquisitionTime   : %ld\n',Tacq);
 fprintf(fid,'SyncDivider       : %ld\n',SyncDiv);
 fprintf(fid,'SyncTrgEdge       : %ld\n',SyncTrgEdge);
 fprintf(fid,'SyncTrgLevel      : %ld\n',SyncTrgLevel);
 fprintf(fid,'InputTrgEdge      : %ld\n',InputTrgEdge);
 fprintf(fid,'InputTrgLevel     : %ld\n',InputTrgLevel);


fprintf('\nSearching for MultiHarp devices...');

dev = [];
found = 0;
Serial     = blanks(8); %enough length!
SerialPtr  = libpointer('cstring', Serial);
ErrorStr   = blanks(40); %enough length!
ErrorPtr   = libpointer('cstring', ErrorStr);

for i=0:MAXDEVNUM-1
    [ret, Serial] = calllib('MHlib', 'MH_OpenDevice', i, SerialPtr);
    if (ret==0)       % Grab any MultiHarp we successfully opened
        fprintf('\n  %1d        S/N %s', i, Serial);
        found = found+1;            
        dev(found)=i; %keep index to devices we may want to use
    else
        if(ret==MH_ERROR_DEVICE_OPEN_FAIL)
            fprintf('\n  %1d        no device', i);
        else 
            [ret, ErrorStr] = calllib('MHlib', 'MH_GetErrorString', ErrorPtr, ret);
            fprintf('\n  %1d        %s', i,ErrorStr);
        end
    end
end
    
% In this demo we will use the first MultiHarp device we found, i.e. dev(1).
% If you have nultiple MultiHarp devices you could also check for a specific 
% serial number, so that you always know which physical device you are talking to.

if (found<1)
	fprintf('\nNo device available. Aborted.\n');
	return; 
end

fprintf('\nUsing device #%1d',dev(1));
fprintf('\nInitializing the device...');

[ret] = calllib('MHlib', 'MH_Initialize', dev(1), MODE_HIST, 0); 
if(ret<0)
	fprintf('\nMH_Initialize error %d. Aborted.\n',ret);
    closedev;
	return;
end 

%this is only for information
Model      = blanks(16); %enough length!
Partno     = blanks(8); %enough length!
Version    = blanks(8); %enough length!
ModelPtr   = libpointer('cstring', Model);
PartnoPtr  = libpointer('cstring', Partno);
VersionPtr = libpointer('cstring', Version);

[ret, Model, Partno] = calllib('MHlib', 'MH_GetHardwareInfo', dev(1), ModelPtr, PartnoPtr, VersionPtr);
if (ret<0)
    fprintf('\nMH_GetHardwareInfo error %1d. Aborted.\n',ret);
    closedev;
	return;
else
	fprintf('\nFound model %s part number %s version %s', Model, Partno, Version);             
end

NumInpChannels = int32(0);
NumChPtr = libpointer('int32Ptr', NumInpChannels);
[ret,NumInpChannels] = calllib('MHlib', 'MH_GetNumOfInputChannels', dev(1), NumChPtr); 
if (ret<0)
    fprintf('\nMH_GetNumOfInputChannels error %1d. Aborted.\n',ret);
    closedev;
	return;
else
	fprintf('\nDevice has %i input channels.', NumInpChannels);             
end

[ret] = calllib('MHlib', 'MH_SetSyncDiv', dev(1), SyncDiv);
if (ret<0)
    fprintf('\nMH_SetSyncDiv error %1d. Aborted.\n',ret);
    closedev;
    return;
end

[ret] = calllib('MHlib', 'MH_SetSyncEdgeTrg', dev(1), SyncTrgLevel, SyncTrgEdge);
if (ret<0)
    fprintf('\nMH_SyncSetEdgeTrg error %ld. Aborted.\n', ret);
    closedev;
    return;
end

 
[ret] = calllib('MHlib', 'MH_SetSyncChannelOffset', dev(1), 0);
if (ret<0)
   fprintf('\nMH_SetSyncChannelOffset error %ld. Aborted.\n', ret);
   closedev;
   return;
end 

for i=0:NumInpChannels-1 % we use the same input settings for all channels
    [ret] = calllib('MHlib', 'MH_SetInputEdgeTrg', dev(1), i, InputTrgLevel, InputTrgEdge);
    if (ret<0)
        fprintf('\nMH_SetInputEdgeTrg error %ld. Aborted.\n', ret);
        closedev;
        return;
    end   
    [ret] = calllib('MHlib', 'MH_SetInputChannelOffset', dev(1), i, 0);
    if (ret<0)
        fprintf('\nMH_SetInputChannelOffset error %ld. Aborted.\n', ret);
        closedev;
        return;
    end
end

HistLen = int32(0);
HistLenPtr = libpointer('int32Ptr', HistLen);
[ret, HistLen] = calllib('MHlib', 'MH_SetHistoLen', dev(1), MAXLENCODE, HistLenPtr);
if (ret<0)
    fprintf('\nMH_SetHistoLen error %ld. Aborted.\n', ret);
    closedev;
    return;
end

[ret] = calllib('MHlib', 'MH_SetBinning', dev(1), Binning);
if (ret<0)
    fprintf('\nMH_SetBinning error %ld. Aborted.\n', ret);
    closedev;
    return;
end
   
[ret] = calllib('MHlib', 'MH_SetOffset', dev(1), 0);
if (ret<0)
    fprintf('\nMH_SetOffset error %ld. Aborted.\n', ret);
    closedev;
    return;
end

ret = calllib('MHlib', 'MH_SetStopOverflow', dev(1), 0, 10000); %for example only 
if (ret<0)
    fprintf('\nMH_SetStopOverflow error %ld. Aborted.\n', ret);
    closedev;
    return;
end
 
Resolution = 0;
ResolutionPtr = libpointer('doublePtr', Resolution);
[ret, Resolution] = calllib('MHlib', 'MH_GetResolution', dev(1), ResolutionPtr);
if (ret<0)
    fprintf('\nMH_GetResolution error %ld. Aborted.\n', ret);
    closedev;
    return;
end
fprintf('\nResolution=%1dps', Resolution);


pause(0.4); % after Init or SetSyncDiv you must allow 400 ms for valid new count rates
            % otherwise you get new values every 100 ms

% From here you can repeat the measurement (with the same settings)


Syncrate = 0;
SyncratePtr = libpointer('int32Ptr', Syncrate);
[ret, Syncrate] = calllib('MHlib', 'MH_GetSyncRate', dev(1), SyncratePtr);
if (ret<0)
    fprintf('\nMH_GetSyncRate error %ld. Aborted.\n', ret);
    closedev;
    return;
end
fprintf('\nSyncrate=%1d/s', Syncrate);
 
for i=0:NumInpChannels-1
	Countrate = 0;
	CountratePtr = libpointer('int32Ptr', Countrate);
	[ret, Countrate] = calllib('MHlib', 'MH_GetCountRate', dev(1), i, CountratePtr);
	if (ret<0)
        fprintf('\nMH_GetCountRate error %ld. Aborted.\n', ret);
        closedev;
        return;
    end
	fprintf('\nCountrate%1d=%1d/s ', i, Countrate);
end

Warnings = 0;
WarningsPtr = libpointer('int32Ptr', Warnings);
[ret, Warnings] = calllib('MHlib', 'MH_GetWarnings', dev(1), WarningsPtr);
if (ret<0)
    fprintf('\nMH_GetWarnings error %ld. Aborted.\n',ret);
    closedev;
    return;
end
if (Warnings~=0)
    Warningstext = blanks(16384); %enough length!
    WtextPtr     = libpointer('cstring', Warningstext);
    [~, Warningstext] = calllib('MHlib', 'MH_GetWarningsText', dev(1), WtextPtr, Warnings);
    fprintf('\n\n%s',Warningstext);
end


ret = calllib('MHlib', 'MH_ClearHistMem', dev(1));    
if (ret<0)
    fprintf('\nMH_ClearHistMem error %ld. Aborted.\n', ret);
    closedev;
    return;
end
        
ret = calllib('MHlib', 'MH_StartMeas', dev(1),Tacq); 
if (ret<0)
    fprintf('\nMH_StartMeas error %ld. Aborted.\n', ret);
    closedev;
    return;
end
         
fprintf('\nMeasuring for %1d milliseconds...',Tacq);
        
ctcdone = int32(0);
ctcdonePtr = libpointer('int32Ptr', ctcdone);
while (ctcdone==0)
    [~,ctcdone] = calllib('MHlib', 'MH_CTCStatus', dev(1), ctcdonePtr);
end    
         
ret = calllib('MHlib', 'MH_StopMeas', dev(1)); 
if (ret<0)
    fprintf('\nMH_StopMeas error %ld. Aborted.\n', ret);
    closedev;
    return;
end
        
countsbuffer  = uint32(zeros(NumInpChannels,MAXHISTBINS));
for i=0:NumInpChannels-1  
    bufferptr = libpointer('uint32Ptr', countsbuffer(i+1,:));
    [ret,countsbuffer(i+1,:)] = calllib('MHlib', 'MH_GetHistogram', dev(1), bufferptr, i); 
    if (ret<0)
        fprintf('\nMH_GetHistogram error %ld. Aborted.\n', ret);
        closedev;
        return;
    end
end

flags = int32(0);
flagsPtr = libpointer('int32Ptr', flags);
[ret,flags] = calllib('MHlib', 'MH_GetFlags', dev(1), flagsPtr);
if (ret<0)
    fprintf('\nMH_GetFlags error %ld. Aborted.\n', ret);
    closedev;
    return;
end
        
if(bitand(uint32(flags),FLAG_OVERFLOW)) 
    fprintf('  Overflow.');
end    

Integralcount = sum(countsbuffer');        
fprintf('\nTotalCount=%1d', Integralcount);

fprintf('\nSaving file...');

for i=1:MAXHISTBINS
    fprintf(fid,'%7d ', countsbuffer(:,i));
    fprintf(fid,'\n');
end    

plot(countsbuffer')

fprintf('\nData is in histomode.out ');

closedev;
    
if(fid>0) 
    fclose(fid);
end

