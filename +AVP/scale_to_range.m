function [d,offset,scale] = scale_to_range(d,range)
  %. Dout = Din*scale + offset
  %> scales to integer with a given number of bits
  if ~exist('range','var'), range = [0,254.99999]; end
  if ~isa(d,'double'), d = double(d); end
  mid = min(d(:));
  mad = max(d(:));
  scale = (range(2)-range(1))/(mad-mid);
  offset = range(1) - mid*scale;
  d = d*scale + offset;
end