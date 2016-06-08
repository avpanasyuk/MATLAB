function n = ndims(x)
  %> standard MATLAB NDIMS return 2 for scalar which is stupid.
  %> @retval n - a number of non-unitary dimentions in x
  n = numel(find(size(x) ~= 1));
end