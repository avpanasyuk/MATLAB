%! calculates mean and varience simultaniously. Latter is STD squared
function [rel_std x_mean] = rel_std(x,varargin)
  if ~strcmp(class(x),'double'), x = double(x); end
  x_mean = mean(x,varargin{:});
  rel_std = sqrt(real(1 - x_mean.*conj(x_mean)./mean(x.*conj(x),varargin{:})));
end
