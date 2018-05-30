function [d, d_subsize] = bin(d,bin_size,func)
  %> @param bin array "d" by bin_size along each dimension
  %> @param func is applied to each bin to get a bin value
  %> this function should be able to act on a given dimension of an array
  %> so it will be called as func(out,bin_dim) where bin_dim is the dimension
  %> where all bins are combined. func = @mean by default
  if ~exist('func','var'), func = @mean; end
  
  sz = size(d);
  nd = ndims(d);
  if numel(bin_size) ~= nd
    if numel(bin_size) == 1
      bin_size = repmat(bin_size,1,numel(sz));
    else
      error(['Number of elements in "factors" should be equal to the number',...
        ' of dimensions in "d" or 1'])
    end
  end
  out_size = fix(sz./bin_size);
  d_subsize = out_size.*bin_size;
  if all(bin_size == 1), return; end
  
  for dimI=1:nd
    subinds{dimI} = 1:d_subsize(dimI);
  end
  new_size = [bin_size; out_size];
  d = reshape(d(subinds{:}),new_size(:).');
  % move all bin dimensions to the end
  d = permute(d,[[1:nd]*2,[1:nd]*2-1]);
  % combine all bin diomensions into one
  inds = num2cell([out_size, prod(bin_size)]);
  d = reshape(d,[out_size, prod(bin_size)]);
  d = func(d,nd+1);
end
