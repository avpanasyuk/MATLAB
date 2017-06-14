function [rel_std x_mean] = rel_std(x,varargin)
  %> calculates mean and relative STD colonwise by default
  %> @param x - input, may be complex
  %> @param varargin - passed to "mean"
  if ~strcmp(class(x),'double'), x = double(x); end
  x_mean = mean(x,varargin{:});
  rel_std = sqrt(real(1 - x_mean.*conj(x_mean)./mean(x.*conj(x),varargin{:})));
end
