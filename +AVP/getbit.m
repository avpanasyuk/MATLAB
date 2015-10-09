function bit = getbit(val, num)
  bit = double(bitand(bitshift(uint32(val),1-num),1));
end
