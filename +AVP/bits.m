% Author Alexander Panasyuk
% returns number stored in bits from b1 to b2, b1 <= b2, 0-based
% see GETBIT and GETBITS as well
function out = bits(n,b1,b2)
  if ~exist('b2','var'), b2 = b1; end
  out = bitand(bitshift(n,-b1),bitshift(n./n,b2-b1+1)-1);
end

