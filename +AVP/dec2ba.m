% converts decimal to byte array
function ba = dec2ba(x,n) 
  if nargin<2, n=2; end
  if n ~= 2, error('not implemented yet'); end
  ba = zeros([n,size(x)],'uint8');
  x = uint16(x);
  ba(:) = uint8([bitand(x,255);bitshift(x,-8)]);
end
  
  
  