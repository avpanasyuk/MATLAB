function err = rel_error(x1,x2)
  err = 2*(x1-x2)./(abs(x1)+abs(x2));
end