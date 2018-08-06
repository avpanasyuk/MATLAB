function res = apply_func_to_vars(func,varargin)
  %> @param varargin - all input parameters should be variables of the same
  %> size. the function combines them along new dimension and them runs 
  %> FUNC(combined_array,dim)
  if nargin == 1, res = varargin{1}; 
  else
    sz = size(varargin{1});
    nd = ndims(varargin{1});
    
    size_diff = cellfun(@(x) any(size(x) - sz),varargin(2:end));
    if any(size_diff)
      error('All imput parameters should have the same size!');
    end
    res = func(cat(nd+1,varargin{:}),nd+1);
end