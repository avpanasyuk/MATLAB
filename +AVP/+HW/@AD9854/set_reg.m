% sets register value
function set_reg(obj,register,value)
% create instruction byte
% bit 8 is 0 - write operation
InstByte = obj.register.(register)(1); % address
send_bits(obj,1,InstByte)
send_bits(obj,obj.register.(register)(2),value);
end

