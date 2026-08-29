% Author Alexander Panasyuk
% returns number stored in bits from b1 to b2, b1 <= b2, 0-based
% see BITGET, SETBITS as well
function out = bits(n,b1,b2)
  if ~exist('b2','var'), b2 = b1; end
  % the mask is cast to n's class rather than derived from n: n./n is NaN for a double
  % 0 (bitand then threw) and 0 for an integer-class 0 (bitand then returned 0 for
  % every field, silently).
  out = bitand(bitshift(n,-b1),cast(2^(b2-b1+1)-1,'like',n));
end
