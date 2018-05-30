% strip outliers on edges by throwing away given percent of outlying point
function [a MinEdge MaxEdge]=enhance(a,percent)
  as = sort(a(:));
  n = numel(as);
  margin = round(n*percent);
  MinEdge = as(1+margin);
  MaxEdge = as(end-margin);
  TooBig = find(a > MaxEdge); a(TooBig) = MaxEdge;
  TooSmall = find(a < MinEdge); a(TooSmall) = MinEdge;
end



