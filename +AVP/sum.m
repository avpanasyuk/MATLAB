function out=sum(x)
  x(~isfinite(x))=0;
  out = sum(x);
end
