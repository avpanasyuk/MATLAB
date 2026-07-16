function [constant, error, FirstI, LastI] = find_constant_level(x, from_first, varargin)
  %> if a single continuous interval in data corresponds to
  %> constant level we find it.
  %> We go through all values of start and stop of this interval
  %> and find minimum std.
  %> @param from_first, if true assumes that constant interval starts in the beginning
  %> if false then constant interval may be in the middle
  %> @param min_length - minimal length of the constant interval, sqrt(numel(x))
  %> by default
  
  n = numel(x);

  AVP.opt_param('min_length',min(n-1,max(10,fix(n^0.25))));
  AVP.opt_param('use_slope',fix(n^0.25));
  AVP.opt_param('do_plot',true);
  AVP.opt_param('num_sigmas',2);
 
  if from_first
    Std = sqrt((cumsum(x.^2)-cumsum(x).^2./[1:n].')./[1:n].');
    error = min(Std(min_length:end));
    LastI = find(Std > error*num_sigmas,1,'first');
    constant = median(x(1:LastI));
%     if use_slope ~= 0
%      x_range = 800;
%      subplot(4,1,1); plot(x); set(gca,'XLim',[1,x_range])
%      subplot(4,1,2); plot(Std(1:end-fix(use_slope/2)+1)); set(gca,'XLim',[1,x_range])
%      Grad = [AVP.diff(smooth(Std,use_slope,'lowess'));0]; Grad(Grad < 0) = NaN;
%      subplot(4,1,3); plot(Grad(fix(use_slope/2):end));  set(gca,'XLim',[1,x_range])   
%      Std = Std(1:end-fix(use_slope/2)+1)./(Grad(fix(use_slope/2):end)).^0.5;
%      subplot(4,1,4); plot(log(Std)); set(gca,'XLim',[1,x_range])    
%      [error,LastI] = min(Std(min_length:end),[],'omitnan');
%      LastI = LastI + min_length;
%     end
    FirstI = 1;
  else
    x2 = cumsum(x.^2);
    [x2X,x2Y] = AVP.mesh(x2,x2);
    x_sqr = cumsum(x).^2;
    [x_sqrX,x_sqrY] = AVP.mesh(x_sqr,x_sqr);
    [nX,nY] = AVP.mesh(1:n,1:n);
    dn = nY - NX;
    Std = sqrt(triu((x2Y - x2X - (x_sqrY - x_sqrX)./dn)./dn,min_length)); % std of the interval Iy to Ix
    Std(Std == 0) = NaN;
    [error, LastI, FirstI] = AVP.min(Std,[],'omitnan');
  end
  constant = mean(x(FirstI:LastI));
  if do_plot
    plot(x,'.'); hold on
    plot([LastI,FirstI],[constant,constant],'b');
    AVP.PLOT.vert_lines([LastI,FirstI]);
    hold off
  end
end





