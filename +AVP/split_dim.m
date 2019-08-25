function x = split_dim(x,dim,new_dims_sizes)
  sz = size(x);
  x = reshape(x,[sz(1:dim-1),new_dims_sizes,sz(dim+1:end)]);
end
