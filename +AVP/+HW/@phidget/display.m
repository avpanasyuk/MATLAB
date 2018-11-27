function display(obj)
    % still can not make API function which return strings in char**
    % arguments to work. Crashes 
    % out = cellstr(['aaaaaaaaaaaaaaaaaaaaaaaaaaaa']);
    % pout = libpointer('stringPtrPtr',out);
    % out = call_common(obj,'getDeviceName',pout) 
    
	pVal = libpointer('int32Ptr',0);
	call_common(obj,'getSerialNumber',pVal)
	disp('PHIDGET Serial board number:'),disp(get(pVal,'Value'))
    for i=1:8, 
        a(i) = get_analog(obj,i);
        in(i) = get_dinput(obj,i);
        out(i) = get_doutput(obj,i);
    end        
        
    disp('Analog Inputs:'), disp(uint16(a))
    disp('Digital Inputs:'),disp(uint8([in, binvec2dec(in ~= 0)]))
    disp('Digital Outputs:'),disp(uint8([out, binvec2dec(out ~= 0)]))
end