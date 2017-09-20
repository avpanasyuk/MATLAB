function out = merge_dims(x,dims)
  sz = size(x);
  d = 1:ndims(x);
  d(dims) = 0;
  rest_dims = d(d ~= 0);
  x = permute(x,[dims,rest_dims]);
  out = reshape(x,[prod(sz(dims)),sz(rest_dims)]);
end