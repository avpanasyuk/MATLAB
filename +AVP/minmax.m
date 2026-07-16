function M = minmax(x,dim)
  if ~AVP.is_defined('dim'), dim = 1; end
  M = cat(ndims(x),shiftdim(min(x,[],dim),1),shiftdim(max(x,[],dim),1));
end
