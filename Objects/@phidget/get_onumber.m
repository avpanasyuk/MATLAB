function out = get_onumber(phidget,range)
% get_onumber(phidget,range)
% reads all digital outputs in RANGE and converts values to a number
% RANGE - optional parameter, 2 element vector, start and end bits to read (1-based), 
% [1,8] by default
	if nargin < 2, range=[1,8]; end
    out = uint8(0); 
    for i=range(1):range(2), out = bitset(out,i-range(1)+1,get_doutput(phidget,i)); end;
end
