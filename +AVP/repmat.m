function x = repmat(x, factor, dim)
  %> runs repmat on a given dimension
  facts = ones(1,ndims(x));
  facts(dim) = factor;
  x = repmat(x,facts);
end