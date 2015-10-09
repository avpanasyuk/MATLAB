function bit = getbits(val, num, lowest)
%> @retval bit - value of subset of bits, scalar or array of the same size as lowest
%> @param val - value to select bits from or array of the same size as lowest
%> @param number of bits in the subset scalar or array of the same size as lowest
%> @param lowest 1-based index of the lowest bit in the subset, may be an
%> array then return is array of the same size
  Sz = size(lowest);
  % if lowest is array and num or val scalars make them vectors
  if any(size(num) ~= Sz)
    if numel(num) == 1
      num = repmat(num,Sz);
    else error('Should not be so!'); end
  end
  if any(size(val) ~= Sz)
    if numel(val) == 1
      val = repmat(val,Sz);
    else error('Should not be so!'); end
  end
  bit = bitand(bitshift(val,1-lowest),cast(2.^num-1,'like',val));
end
