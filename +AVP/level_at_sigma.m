function levels = level_at_sigma(x,zero_centered,sigma)
  %> assuming normal distribution x finds levels
  %> corresponding to given sigmas.
  %> @param zero_centered, if true, assumes the distribution is zero centered, takes 
  %> abs(x) and and returns one level. If false, assumes reverse and
  %> returns two
  %> @param sigma - scalar
  %> @retval levels
  
  if zero_centered 
    levels = AVP.level_at_percentile(abs(x),erf(sigma/sqrt(2)));
  else
    levels = AVP.level_at_percentile(x,[0,1] + [1,-1]*(1-erf(sigma/sqrt(2)))/2);
  end
end

function test
  x = randn(100000,1);
  AVP.level_at_sigma(x,1,1) %  0.99
  AVP.level_at_sigma(x,1,2) %  1.98
  AVP.level_at_sigma(x,0,3) %  [-2.9816       3.0374]
end






