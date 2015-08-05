%! calculates mean and varience simultaniously. Latter is STD squared
function [x_mean x_vari] = mean_and_vari(x,dim)
  if ~exist('dim','var'), dim = 1; end
  x_mean = mean(x,dim);
  x_vari = mean(x.^2,dim) - x_mean.^2;
end
