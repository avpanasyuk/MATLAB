% !!!!!!!!!!!!!!!! usage discouraged, use pop
function [Value x] = pop_value(type,x,n)
%> using typecast
%> @param type - type to cast to using typecast
%> @param x - bytes sequence 
%> @param n - number of 'type' values
if ~exist('n','var'), n = 1; end
[data x] = AVP.pop_bytes(x,n*AVP.get_size_of_type(type)); 
Value = typecast(data,type);
end


