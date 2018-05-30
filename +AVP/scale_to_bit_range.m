function d = scale_to_bit_range(d,nbits)
  %> scales to integer with a given number of bits
  if ~exist('nbits','var'), nbits = 8; end
  d = round(AVP.scale_to_range(d,[0,2^nbits-0.0001])+0.5);
end