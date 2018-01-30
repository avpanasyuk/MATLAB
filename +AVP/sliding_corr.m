function [corr, prop_coeff, offset] = sliding_corr(x1,x2,width)
  %> @retval corr - vector(numel(x1) - width): correlation over WIDTH sliding
  %> from one end of x1 and x2 to another
  %> @retval prop_coeff - vector(numel(x1) - width): propotionality coeff
  %> x2./x1 over width
  %> @retval offset - vector(numel(x1) - width): x2 - x1.*prop_coeff over
  %> WIDTH
  
  x1_cs = cumsum(x1);
  x2_cs = cumsum(x2);
  x12_cs = cumsum(x2.*x1);
  x1sqr_cs = cumsum(x1.^2);
  x2sqr_cs = cumsum(x2.^2);
  
  % keyboard
  
  x1_s = x1_cs(width+1:end) - x1_cs(1:end-width);
  x2_s = x2_cs(width+1:end) - x2_cs(1:end-width);
  x12_s = x12_cs(width+1:end) - x12_cs(1:end-width);
  x1sqr_s = x1sqr_cs(width+1:end) - x1sqr_cs(1:end-width);
  x2sqr_s = x2sqr_cs(width+1:end) - x2sqr_cs(1:end-width);
  
  num = x12_s - x1_s.*x2_s/width;
  x1norm = x1sqr_s - x1_s.^2/width;
  
  corr = num./sqrt(x1norm.*(x2sqr_s - x2_s.^2/width));
  if nargout > 1
    prop_coeff = num./x1norm;
  end
  if nargout > 2
    offset = (x2_s - x1_s.*prop_coeff)/width;
  end
end

