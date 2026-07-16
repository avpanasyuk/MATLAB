function v = logspace(start,stop,n)
  % original logspace makes start = 10^start
  v = exp(linspace(log(start),log(stop),n));
end
