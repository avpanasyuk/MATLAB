function out = bland_altman(x1,x2)
  out = 2*(x1-x2)./(x1+x2);
  % out(~(isfinite(x1) & isfinite(x2))) = 0;
end
