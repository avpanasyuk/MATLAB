function out = merge_dims(x,dims)
  %> merge3dimentions "dims". Merged dimensions returned as first dimension
  sz = size(x);
  d = 1:ndims(x);
  d(dims) = 0;
  rest_dims = d(d ~= 0);
  x = permute(x,[dims,rest_dims]);
  if isempty(rest_dims), sz_rest = 1; else sz_rest = sz(rest_dims); end
  out = reshape(x,[prod(sz(dims)),sz_rest]);
end