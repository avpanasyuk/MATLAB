function out=checkXOR(x)
  out = uint8(0);
  for n=1:numel(x), out = bitxor(out,x(n)); end
end
