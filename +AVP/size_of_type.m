function sz = size_of_type(type)
  x = zeros(1,1,type);
  w = whos('x');
  sz = w.bytes;
end