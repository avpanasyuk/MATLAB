function [constant, error, LastI] = find_constant_level_from_start(x, varargin)
  %> if a single continuous interval in data corresponds to
  %> constant level we find it.
  %> We go through all values of start and stop of this interval
  %> and find minimum std.
  %> @param from_first, if true assumes that constant interval starts in the beginning
  %> if false then constant interval may be in the middle
  %> @param min_length - minimal length of the constant interval, sqrt(numel(x))
  %> by default
  
  n = numel(x); % keyboard
  
  AVP.opt_param('span',min(n-1,max(10,fix(n^0.5))));
  AVP.opt_param('use_slope',fix(n^0.25));
  AVP.opt_param('do_plot',true);
  AVP.opt_param('num_sigmas',2);
  
  csx2 = cumsum(x.^2); csx_sqr = cumsum(x);
  Std = sqrt((csx2(1+span:end) - csx2(1:end-span) - ...
    (csx_sqr(1+span:end) - csx_sqr(1:end-span)).^2/span)/span);
  error = min(Std);
  for it=1:2
    while num_sigmas > 1
      LastI = find(Std >= error*num_sigmas,1,'first');
      if isempty(LastI), num_sigmas = num_sigmas - 1;
      else break; end
    end
    error = median(Std(1:LastI));
  end
  
  constant = median(x(1:LastI));
  x_range = 1800;
  subplot(4,1,1); plot(x); set(gca,'XLim',[1,x_range])
  subplot(4,1,2); plot(Std); set(gca,'XLim',[1,x_range])
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
  if do_plot
    plot(x,'.'); hold on
    plot([1,LastI],[constant,constant],'b');
    AVP.PLOT.vert_lines(LastI);
    hold off
  end
end





