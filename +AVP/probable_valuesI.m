function [Inds, minV, maxV]  = probable_valuesI(x, Nsigmas)
  if ~exist('Nsigmas','var'), Nsigmas = 3; end
  % using confidence intervals for mean and sigma instead of mean values
  % for robustness
  [~,~,muci,sigmaci]  = normfit(x);
  minV = muci(1) - Nsigmas*sigmaci(2);
  maxV = muci(2) + Nsigmas*sigmaci(2);
  Inds = find(x > minV  & x < maxV);
end
