function bit = getbits(val, num, lowest)
  %> @retval bit - value of subset of bits, scalar or array of the same size as lowest
  %> @param val - value to select bits from or array of the same size as lowest
  %> @param num number of bits in the subset scalar or array of the same size as lowest
  %> @param lowest 1-based index of the lowest bit in the subset, may be an
  %> array then return is array of the same size
  
  %% bring everything to common size if possible
  if numel(val) ~= 1, Sz = size(val);
  else
    if numel(num) ~= 1, Sz = size(num);
    else
      if numel(lowest) ~= 1,
        Sz = size(lowest);
      else
        Sz = [1,1];
      end
    end
  end
  if numel(val) ~= 1
    if any(size(val) ~= Sz), error('Should not be so!'); end
  else
    val = repmat(val,Sz);
  end
  if numel(num) ~= 1
    if any(size(num) ~= Sz), error('Should not be so!'); end
  else
    num = repmat(num,Sz);
  end
  if numel(lowest) ~= 1
    if any(size(lowest) ~= Sz), error('Should not be so!'); end
  else
    lowest = repmat(lowest,Sz);
  end
  
  %% calculate
  bit = bitand(bitshift(val,1-lowest),cast(2.^num-1,'like',val));
end
