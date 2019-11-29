function [density values ydivs p] = hist(y,varargin)
  % usually histogam is calculated by taking all values range, dividing it on
  % equal ranges,  and then calculating number of points in each range.
  % Causes big instability as some ranges have a lot of points and some
  % don't.
  % instead we make bins with equal number of points. Density in this case is
  % 1/change in value over the current bin.
  % Problem arises when there is no change in value over the current bin. So
  % we picking up unique values first.
  %> @param varargin
  %>      nbins
  %>      show
  
  y = y(isfinite(y(:)));
  n = numel(y);
  AVP.opt_param('nbins',ceil(sqrt(n)));
  AVP.opt_param('show',true);
  AVP.opt_param('plot_logx',false);
  AVP.opt_param('fit_gauss',false);
  
  idivs = round(linspace(1,n,nbins)).';
  y = sort(y);
  [ydivs Inds] = unique(y(idivs));
  idivs = idivs(Inds);
  
  density = (idivs(2:end)-idivs(1:end-1))./(ydivs(2:end)-ydivs(1:end-1));
  values = (ydivs(2:end)+ydivs(1:end-1))/2;
  
  if fit_gauss
    core_densI = find(density > max(density)/40);
    core_val = values(core_densI);
    p = polyfit(core_val,log(density(core_densI)),2);
  else p = [];
  end
  if show
    if plot_logx
      semilogx(abs(values),density,'*-');
    else
      plot(values,density,'.-');
      if fit_gauss
        fit = exp(polyval(p,core_val));
        hold on
        plot(core_val,fit); hold off
      end
    end
  end
end
