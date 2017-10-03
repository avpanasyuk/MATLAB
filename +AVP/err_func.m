function err = err_func(data,fit,dim,degree)
  %> works with complex data and fit
  delta = data - fit;
  if ~exist('degree','var') || isempty(degree)
    degree = 2;
  end
  if ~exist('dim','var') || isempty(dim)
    dim = find(size(data) ~= 1,1,'first');
  end
  err = (sum((delta.*conj(delta)).^(degree/2),dim)./...
    sum((data.*conj(data)).^(degree/2),dim)).^(1/degree);
end
  
  