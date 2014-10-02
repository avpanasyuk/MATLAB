function [Value x] = pop_value(type,x,n_bytes)
% using typecast
% @param type - type to cast to using typecast
[data x] = AVP.pop_bytes(x,n_bytes);
Value = typecast(data,type);
end


