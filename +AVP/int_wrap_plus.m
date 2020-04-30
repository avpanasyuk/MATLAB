function s = int_wrap_plus(x1,x2)
  sum = double(x1) + double(x2);
  Is = sum > intmax(class(x1));
  sum(Is) = sum(Is) - double(intmax(class(x1))) - 1;
end