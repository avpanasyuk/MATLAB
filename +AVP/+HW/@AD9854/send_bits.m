% send a specified value
function send_bits(obj,num_bytes,value)
res = uint64(0);
for n=(double(num_bytes)*8):-1:1
    putvalue(obj.parport.SDIO,bitget(value,n)); % set data bit
    putvalue(obj.parport.Sclk,1); % rising edge - writing
    pause(0.01)
%    putvalue(obj.parport.SDIO,bitget(value,n) == 0);
    putvalue(obj.parport.Sclk,0); % falling edge - reading
%    res = bitset(res,n,getvalue(obj.OutPort));
end
%if res ~= value
%    error('Problem sending bits!');
%end


    
    
