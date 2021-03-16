
% Demo for access to MultiHarp 150 Hardware via MHLIB.DLL v 2.0.
% The program performs a TTTR measurement based on hardcoded settings.
% The resulting data stream is stored in a binary output file.
%
% Axel Hagen, PicoQuant, May 2020


% Constants from mhdefin.h

REQLIBVER   =   '2.0';    % this is the version this program expects
MAXDEVNUM   =       8;
TTREADMAX   = 1048576;    % 1M event records 
MODE_HIST   =       0;
MODE_T2	   =        2;
MODE_T3	   =        3;

FLAG_FIFOFULL = hex2dec('0002');

TRGLVLMIN	  =      -1200;	    % mV
TRGLVLMAX	  =       1200;	    % mV
OFFSETMIN	  =          0;     % ns
OFFSETMAX	  =  100000000;	    % ns

ACQTMIN		  =          1;	    % ms
ACQTMAX		  =  360000000;	    % ms  (100*60*60*1000ms = 100h)

% Errorcodes from errorcodes.h

MH_ERROR_DEVICE_OPEN_FAIL		 = -1;

% Settings for the measurement, Adapt to your setup!
 
Mode          = MODE_T3; %  you can change this
SyncTrgEdge   =       0; %  you can change this
SyncTrgLevel  =    -100; %  you can change this
InputTrgEdge  =       0; %  you can change this
InputTrgLevel =    -100; %  you can change this
SyncDiv       =       1; %  you can change this (observe mode!)
Binning       =       0; %  you can change this
Tacq          =   10000; %  you can change this       
    

fprintf('\nMultiHarp 150 MHLib.DLL Demo Application             PicoQuant 2020\n');

if (~libisloaded('MHlib'))    
    %Attention: The header file name given below is case sensitive and must
    %be spelled exactly the same as the actual name on disk except the file 
    %extension. 
    %Wrong case will apparently do the load successfully but you will not
    %be able to access the library!
    %The alias is used to provide a fixed spelling for any further access via
    %calllib() etc, which is also case sensitive.
    
    %To load the right dll for OS and bitness we use the mexext command.
    %Therefor the next four lines, demonstrating the old manual way, have
    %been commented.
    
    %loadlibrary('Mhlib.dll',   'mhlib.h', 'alias', 'MHlib'); % Windows 32 bit
    %loadlibrary('MHLib64.dll', 'mhlib.h', 'alias', 'MHlib'); % Windows 64 bit 
    %loadlibrary('/usr/local/lib/mh150/mhlib.so', 'mhlib.h', 'alias', 'MHlib'); % Linux 32 bit       
    %loadlibrary('/usr/local/lib64/mh150/mhlib.so', 'mhlib.h', 'alias', 'MHlib'); % Linux 64 bit
    
    OS = mexext;
    if strcmp('mexw32', OS)
        DLL = 'MHLib.dll';                        % Windows 32 bit
    elseif strcmp('mexw64', OS)
        DLL = 'MHLib64.dll';                      % Windows 64 bit
    elseif strcmp('mexa32', OS)
        DLL = '/usr/local/lib/mh150/mhlib.so';    % Linux 32 bit
    elseif strcmp('mexa64', OS)
        DLL = '/usr/local/lib64/mh150/mhlib.so';  % Linux 64 bit
    else
        fprintf('\nNo supported OS\n');
        return;
    end
    loadlibrary(DLL, 'mhlib.h', 'alias', 'MHlib');
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

fid = fopen('tttrmode.out','wb');
if (fid<0)
    fprintf('Cannot open output file\n');
    return;
end

fprintf('Measurement Mode  : T%ld\n',Mode);
fprintf('Binning           : %ld\n',Binning);
fprintf('AcquisitionTime   : %ld\n',Tacq);
fprintf('SyncDivider       : %ld\n',SyncDiv);
fprintf('SyncTrgEdge       : %ld\n',SyncTrgEdge);
fprintf('SyncTrgLevel      : %ld\n',SyncTrgLevel);
fprintf('InputTrgEdge      : %ld\n',InputTrgEdge);
fprintf('InputTrgLevel     : %ld\n',InputTrgLevel);


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

    
% in this demo we will use the first MultiHarp device we found, i.e. dev(1)
% you could also check for a specific serial number, so that you always know 
% which physical device you are talking to.

if (found<1)
	fprintf('\nNo device available. Aborted.\n');
	return; 
end

fprintf('\nUsing device #%1d',dev(1));
fprintf('\nInitializing the device...');

[ret] = calllib('MHlib', 'MH_Initialize', dev(1), Mode, 0);
if(ret<0)
	fprintf('\nMH_Initialize error %d. Aborted.\n',ret);
    closedev;
	return;
end 

%this is only for information
Model      = blanks(24); %enough length!
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
    fprintf('\nMH_SetSyncEdgeTrg error %ld. Aborted.\n', ret);
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

if (Mode ~= MODE_T2)    %MH_SetBinning is meaningless in T2 mode
    [ret] = calllib('MHlib', 'MH_SetBinning', dev(1), Binning);
    if (ret<0)
        fprintf('\nMH_SetBinning error %ld. Aborted.\n', ret);
        closedev;
        return;
    end
end

if (Mode ~= MODE_T2)    %MH_SetOffset is meaningless in T2 mode
    [ret] = calllib('MHlib', 'MH_SetOffset', dev(1), 0);
    if (ret<0)
        fprintf('\nMH_SetOffset error %ld. Aborted.\n', ret);
        closedev;
        return;
    end
end

%MH_GetResolution is meaningless in T2 mode but it does no harm
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
            % otherwise you get new values after every 100 ms


% from here you can repeat the measurement (with the same settings)


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
	fprintf('\nCountrate%1d=%1d/s', i, Countrate);
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


buffer  = uint32(zeros(1,TTREADMAX));
bufferptr = libpointer('uint32Ptr', buffer);

nactual = int32(0);
nactualptr = libpointer('int32Ptr', nactual);

ctcdone = int32(0);
ctcdonePtr = libpointer('int32Ptr', ctcdone);

Progress = 0;
fprintf('\nProgress:%9d',Progress);
       
ret = calllib('MHlib', 'MH_StartMeas', dev(1),Tacq); 
if (ret<0)
    fprintf('\nMH_StartMeas error %ld. Aborted.\n', ret);
    closedev;
    return;
end
       
while(1)  
    
    flags = int32(0);
    flagsPtr = libpointer('int32Ptr', flags);
    [ret,flags] = calllib('MHlib', 'MH_GetFlags', dev(1), flagsPtr);
    if (ret<0)
    	  fprintf('\nMH_GetFlags error %ld. Aborted.\n', ret);
    	  break
    end
   
    if (bitand(uint32(flags),FLAG_FIFOFULL)) 
        fprintf('\nFiFo Overrun!\n'); 
        break;
    end
		
    [ret, buffer, nactual] = calllib('MHlib','MH_ReadFiFo', dev(1), bufferptr, nactualptr);
    %Note that MH_ReadFiFo may return less than requested  
    if (ret<0)  
        fprintf('\nMH_ReadFiFo error %d\n',ret); 
        break;
    end  

    if(nactual) 
        cnt = fwrite(fid, buffer(1:nactual),'uint32');
        if(cnt ~= nactual)
            fprintf('\nfile write error\n');
            break;
        end          
		Progress = Progress + nactual;
		fprintf('\b\b\b\b\b\b\b\b\b%9d',Progress);
    else
        [ret,ctcdone] = calllib('MHlib', 'MH_CTCStatus', dev(1), ctcdonePtr);
        if (ret<0)  
            fprintf('\nMH_CTCStatus error %d\n',ret); 
            break;
        end       
        if (ctcdone) 
            fprintf('\nDone\n'); 
            break;
        end
    end
     
	 %you can read the count rates here if needed

end %while


ret = calllib('MHlib', 'MH_StopMeas', dev(1)); 
if (ret<0)
    fprintf('\nMH_StopMeas error %ld. Aborted.\n', ret);
    closedev;
    return;
end
        
closedev;
    
fprintf('\nBinary output data is in tttrmode.out\n');

if(fid>0) 
    fclose(fid);
end

