function [c Y1 Y2 Yi1 Yi2] = corrcoef(Y1,Y2,options)
%+
% find correlation coefficient between two functions with possibly non-uniform x step
% if X is specified then vectors are replaced by values Y1, Y2, X calculated for the
% middles of the intervals. Those values equal area in the intervals
% OPTIONS
% DO_MEAN - subtract mean before calculating
% Xs - value on X axis
% SHIFT - SHIFT vectors before calculating
% X and SHIFT are exlusive
% When SHIFT > 0 Y1 selection starts from SHIFT+1
% when SHIFT < 0 Y2 selection starts from SHIFT+1
% RETURNS
% C - correlation coefficient
% Y1, Y2 - possibly cropped and mean-subtracted imput vectors
% Yi1,Yi2 - cropping indices
  N1 = numel(Y1); N2 = numel(Y2); Yi1 = [1:N1]; Yi2 = [1:N2];
  if exist('options','var')
    if isfield(options,'X'), X = options.X; end 
    if isfield(options,'shift') && options.shift ~= 0
      if options.shift > 0, Yi1 = [1+options.shift:N1];
      else Yi2 = [1-options.shift:N2]; end 
    end     
  else options = []; end
  
  N1 = numel(Yi1); N2 = numel(Yi2); 
  if N1 ~= N2,
    N = min([N1,N2]);
    Yi1 = Yi1(1:N); Yi2 = Yi2(1:N);
  end
  
  Y1 = Y1(Yi1); Y2 = Y2(Yi2); % we want to return unshifted results as well
  
  if isfield(options,'do_mean') && options.do_mean
    Y1 = Y1(:) - mean(Y1(:)); 
    Y2 = Y2(:) - mean(Y2(:));
  end
    
  if exist('X','var'),
    dX = X(2:end)-X(1:end-1);
    Y12 = (Y1(2:end).*Y2(2:end)+Y1(1:end-1).*Y2(1:end-1)).*dX;
    c = sum((Y1(2:end).*Y2(2:end)+Y1(1:end-1).*Y2(1:end-1)).*dX)/...
      sqrt(sum((Y1(2:end).^2+Y1(1:end-1).^2).*dX)*...
      sum((Y2(2:end).^2+Y2(1:end-1).^2).*dX));
  else
    c = sum(Y1.*Y2)/sqrt(sum(Y1.^2)*sum(Y2.^2));
  end 
end

