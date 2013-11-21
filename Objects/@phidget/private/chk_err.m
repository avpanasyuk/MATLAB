function chk_err(phidget,err_code)
    if err_code ~= 0,
        ErrCodes = {'OK','NOTFOUND','NOMEMORY','UNEXPECTED','INVALIDARG','NOTATTACHED',...
            'INTERRUPTED','INVALID','NETWORK','UNKNOWNVAL','BADPASSWORD','UNSUPPORTED',...
            'DUPLICATE','TIMEOUT','OUTOFBOUNDS','EVENT','NETWORK_NOTCONNECTED'};
        error(['USB controller library error!. Something to do with ' ErrCodes{err_code+1} '. Check cables!']);
    end
% The code below, though better, crashes MMTLAB
%     err_str_ptr = libpointer('stringPtrPtr',{''});
%     calllib('plib', 'CPhidget_getErrorDescription', res_code, err_str_ptr);
%     error(get(err_str_ptr, 'Value'))
end
    
