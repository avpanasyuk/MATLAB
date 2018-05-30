function d = scale_to_range(d,range)
  %> scales to integer with a given number of bits
  if ~exist('range','var'), range = [0,254.99999]; end
  mid = min(d(:));
  mad = max(d(:));
  d = range(1) + double(d-mid)*(range(2)-range(1))/double(mad-mid);
end