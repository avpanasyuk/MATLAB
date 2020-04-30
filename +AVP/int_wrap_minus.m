function delta = int_wrap_minus(x1,x2)
  delta = double(x1) - double(x2);
  Is = delta < 0;
  delta(Is) = delta(Is) + double(intmax(class(x1))) + 1;
end