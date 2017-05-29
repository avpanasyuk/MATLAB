function l = level_at_percentile(x,perc)
  %> finds under which level "l" "perc" percintile of "x" lies along 
  %> first dimension
  %> @param perc - percentile (< 1.0)
 sz = size(x);
 if perc == 1, l = ones([sz(2:end),1])*sz(1); return; end
 
 thres = perc*sz(1);
 I1 = max([fix(thres),1]);
 
 x_mat = reshape(sort(x,1),sz(1),[]);
 l = (thres - I1)*(x_mat(I1+1,:)-x_mat(I1,:))+x_mat(I1,:);
 l = reshape(l,[sz(2:end),1]);
end

function test
  x = randn(10000,1);
  AVP.level_at_percentile(abs(x),erf(1/sqrt(2))) % ~68%, 0.9939
  AVP.level_at_percentile(abs(x),erf(2/sqrt(2))) % ~95%, 1.975
  AVP.level_at_percentile(abs(x),erf(3/sqrt(2))) % ~99.7%, 2.96
end


 
 
  
  
  