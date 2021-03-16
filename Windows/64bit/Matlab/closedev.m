fprintf('\nclosing all MultiHarp devices\n');
if (libisloaded('MHlib'))   
    for i=0:7 % no harm to close all
        calllib('MHlib', 'MH_CloseDevice', i);
    end
end
