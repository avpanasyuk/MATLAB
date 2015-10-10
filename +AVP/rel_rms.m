function o = rel_rms(x,y)
  o = sqrt(mean((2*(x-y)./(x+y)).^2));
end
