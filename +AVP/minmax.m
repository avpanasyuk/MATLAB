function M = minmax(x,dim)
  if ~exist('dim','var') || isempty(dim) || dim == 0
    M = [min(x(:)),max(x(:))];
  else
    M = [min(x,[],dim),max(x,[],dim)];
  end
end
