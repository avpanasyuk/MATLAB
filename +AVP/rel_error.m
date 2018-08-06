function err = rel_error(x1,x2)
  err = (x1-x2)./sqrt((x1.^2+x2.^2)/2);
end