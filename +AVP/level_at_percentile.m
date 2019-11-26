function levels = level_at_percentile(x,perc)
  %> finds under which level "l" "perc" percintile of "x" lies along
  %> the first dimension
  %> @param perc - percentile, maybe vector
  %> @retval levels - array(size(x,2:end),numel(perc))
  sz = size(x);
  
  if any(perc > 1 | perc < 0), error('level_at_percentile: wrong perc value'); end
  % I am trying to find precise number here, so I will linearlyy
  % interpolate
  thres = AVP.CONVERT.to_column(perc*(sz(1)-1)+1);
  I1 = fix(thres);
  
  x_mat = reshape(sort(x,1),sz(1),[]);
  levels = repmat((thres - I1),1,size(x_mat,2)).*(x_mat(I1+1,:)-x_mat(I1,:))+x_mat(I1,:);
  levels = reshape(levels.',[sz(2:end),numel(thres)]);
end

function test
  x = randn(100000,1);
  AVP.level_at_percentile(abs(x),erf(1/sqrt(2))) % ~68%, 0.99
  AVP.level_at_percentile(abs(x),erf(2/sqrt(2))) % ~95%, 1.98
  AVP.level_at_percentile(x,[0,1] + [1,-1]*(1-erf(3/sqrt(2)))/2) % [0.0013499      0.99865]%, [-2.9816       3.0374]
end






