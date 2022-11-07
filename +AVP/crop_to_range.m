function x = crop_to_range(x0, range)
  %> crops the values in x to range
  
  x = x0;
  x(isnan(x)) = range(2);
  x(x < range(1)) = range(1);
  x(x > range(2)) = range(2);
end