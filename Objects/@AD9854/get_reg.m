% reads register value
function res = get_reg(obj,register)
% create instruction byte
InstByte = obj.register.(register)(1);
% bit 8 is 1 - read operation
InstByte = bitset(InstByte,8);
send_bits(obj,1,InstByte);
res = read_bits(obj,obj.register.(register)(2));
end
