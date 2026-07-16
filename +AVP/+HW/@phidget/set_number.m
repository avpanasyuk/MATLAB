function set_number(phidget,number,range)
% set_number(phidget,number,range)
% sets values for all digital outputs based on the binary presentation of
% NUMBER. If RANGE is defined sets bits in RANGE to lower NUMBER bits
% PARAMETERS
% NUMBER
% RANGE - optional parameter, 2 element vector, start and end bits to read (1-based), 
% [1,8] by default
	if nargin < 3, range = [1,8]; end 
    bits = bitget(uint8(number),[1:range(2)-range(1)+1]);
    for i=range(1):range(2), set(phidget,i,bits(i-range(1)+1)), end;
end
