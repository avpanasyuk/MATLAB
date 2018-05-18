function d = filter2(f,d)
%> basically FILTER2 only standard one assumes there are zeros outside the
%> input image. This one mirrors image relatiovely to the edge
%> @param f - filter d is getting convolved with
%> @param d - data
  sz = size(f);
  s = fix(sz/2);
  d = [[d(s(1):-1:1,s(2):-1:1),d(s(1):-1:1,:),d(s(1):-1:1,end:-1:end-s(2)+1)];...
    [d(:,s(2):-1:1),d,d(:,end:-1:end-s(2)+1)];...
    [d(end:-1:end-s(1)+1,s(2):-1:1),d(end:-1:end-s(1)+1,:),d(end:-1:end-s(1)+1,end:-1:end-s(2)+1)]];
  d = filter2(f,d);
  d = d(s(1)+1:end-s(1),s(2)+1:end-s(2));  
end