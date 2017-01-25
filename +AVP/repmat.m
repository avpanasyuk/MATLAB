function x = repmat(x, factor, dim)
  facts = ones(1,ndims(x));
  facts(dim) = factor;
  x = repmat(x,facts);
end