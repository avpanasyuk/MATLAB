function sz = sizeof(var)
  w = whos('var');
  sz = w.bytes;
end