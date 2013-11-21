% read a specified value
function res = read_bits(obj,num_bytes)
res = uint64(0);
for n=(double(num_bytes)*8):-1:1
    putvalue(obj.parport.Sclk,1); % rising edge - writing (ignored)
    pause(0.01);
    putvalue(obj.parport.Sclk,0); % falling edge - reading
    res = bitset(res,n,getvalue(obj.OutPort));
end
end
