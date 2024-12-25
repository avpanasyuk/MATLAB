function g = gauss(x,s)
  g = 1/sqrt(2*pi)/s*exp(-x.^2/(2*s.^2));
end