function out=checkXOR(x)
  out = x(1); out(1) = 0;
  for n=1:numel(x), out = bitxor(out,x(n)); end
end
