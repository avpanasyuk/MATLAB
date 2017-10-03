function x = insert_unity_dim(x,dimI)
  s = size(x);
  x = reshape(x,[s(1:dimI-1) 1 s(dimI:end)]);
end