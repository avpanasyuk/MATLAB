function d = diff(x, dim)
  %> calculates difference between elements x along dim
  if ~exist('dim','var'), dim = 1; end
  s1.subs = repmat({':'},1,ndims(x));
  s1.type = '()'; 
  s2 = s1;
  s1.subs{dim} = 1:size(x,dim)-1;
  s2.subs{dim} = s1.subs{dim} + 1;
  d = subsref(x,s2) - subsref(x,s1);
end
