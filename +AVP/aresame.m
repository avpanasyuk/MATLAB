function are = aresame(x)
  %> whether all element of array are same
  are = ~any(x(2:end) ~= x(1));
end