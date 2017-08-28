function err = err_func(data,fit,dim,degree)
  d = data - fit;
  if ~exist('degree','var') || isempty(degree)
    degree = 2;
  end
  if ~exist('dim','var') || isempty(dim)
    dim = find(size(data) ~= 1,1,'first');
  end
  %      err = sqrt((d(:)'*d(:))/(data(:)'*data(:)));
  %   else
  err = (sum((d.*conj(d)).^(degree/2),dim)./...
    sum((data.*conj(data)).^(degree/2),dim)).^(2/degree);
end
  
  