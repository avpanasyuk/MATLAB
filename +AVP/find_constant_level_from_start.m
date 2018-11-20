function [constant, error, LastI] = find_constant_level_from_start(x, varargin)
  %> if a single continuous interval in data corresponds to
  %> constant level we find it.
  %> We go through all values of start and stop of this interval
  %> and find minimum std.
  %> @param from_first, if true assumes that constant interval starts in the beginning
  %> if false then constant interval may be in the middle
  %> @param min_length - minimal length of the constant interval, sqrt(numel(x))
  %> by default
  
  n = numel(x); 
  
  AVP.opt_param('min_length',min(n-1,max(10,fix(n^0.5))));
  AVP.opt_param('do_plot',true);
  AVP.opt_param('num_sigmas',2);
  
  
  min_length = max(min_length,find(abs(x - x(1)) > eps,1,'first'));
  Std = sqrt(max(0,(cumsum(x.^2)-cumsum(x).^2./[1:n].')./[1:n].'));
  error = min(Std(min_length+1:end));

  oldI = 1; 
  while 1
    while num_sigmas > 1
      LastI = find(Std(min_length:end) >= error*num_sigmas,1,'first');
      if ~isempty(LastI), break; end
      num_sigmas = num_sigmas - 1;
    end
   LastI = LastI + min_length - 1;
   new_error = median(Std(min_length:LastI));
   if new_error < error, break; end
   error = new_error;
   if LastI == oldI, break; end
   if oldI > LastI, keyboard; end
   oldI = LastI;
   % l(it) = LastI;
   % e(it) = error;
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





