function x = setbits(xin,bits,num,pos,type)
  x = bitor(bitand(cast(xin,type),bitcmp(bitshift(2^num-1,pos),type)),...
    bitshift(bits,pos));
end