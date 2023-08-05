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
  %>      do_plot
  
  y = y(isfinite(y(:)));
  n = numel(y);
  AVP.opt_param('nbins',ceil(sqrt(n)));
  AVP.opt_param('do_plot',true);
  AVP.opt_param('plot_logx',false);
  AVP.opt_param('fitfunc','none'); % possible options "gauss", "xgauss", 
  % 'x2gauss','xexp','x2exp','x_to_n_exp','x_to_n_gauss'
  
  idivs = round(linspace(1,n,nbins)).';
  y = sort(y);
  [ydivs Inds] = unique(y(idivs));
  idivs = idivs(Inds);
  
  density = (idivs(2:end)-idivs(1:end-1))./(ydivs(2:end)-ydivs(1:end-1));
  values = (ydivs(2:end)+ydivs(1:end-1))/2;
  
  core_densI = find(density > max(density)/40);
  core_val = values(core_densI);
  switch(fitfunc)
    case 'gauss'
      p = polyfit(core_val,log(density(core_densI)),2);
      fitd = exp(polyval(p,core_val));
    case 'xgauss'
      [Max, MaxI] = max(density);
      b = sqrt(2)*values(MaxI);
      a = Max*exp(0.5)*sqrt(2)/b;
      p = fit(core_val,density(core_densI),'a*x*exp(-(x/b).^2)',...
        'Start',[a,b]);
      fitd = p(core_val);
    case 'x2gauss'
      [Max, MaxI] = max(density);
      b = values(MaxI);
      a = Max*exp(1)/b.^2;
      p = fit(core_val,density(core_densI),'a*x^2*exp(-(x/b).^2)',...
        'Start',[a,b]);
      fitd = p(core_val);
    case 'xexp'
      [Max, MaxI] = max(density);
      b = values(MaxI);
      a = Max*exp(1)/b;
      p = fit(core_val,density(core_densI),'a*x*exp(-(x/b))',...
        'Start',[a,b]);
      fitd = p(core_val);
    case 'x2exp'
      [Max, MaxI] = max(density);
      b = values(MaxI)/2;
      a = Max*exp(2)/4/b.^2;
      p = fit(core_val,density(core_densI),'a*x.^2*exp(-(x/b))',...
        'Start',[a,b]);
      fitd = p(core_val);
    case 'x_to_n_exp'
      [Max, MaxI] = max(density);
      c = 1;
      b = values(MaxI)/c;
      a = Max*exp(c)/(b*c).^c;
      p = fit(core_val,density(core_densI),'a*x.^c*exp(-(x/b))',...
        'Start',[a,b,c]);
      fitd = p(core_val);
    case 'x_to_n_gauss'
      [Max, MaxI] = max(density);
      c = 1;
      b = values(MaxI)*sqrt(2/c);
      a = Max*exp(c/2)/(b*sqrt(c/2)).^c;
      p = fit(core_val,density(core_densI),'a*x.^c*exp(-(x/b).^2)',...
        'Start',[a,b,c]);
      fitd = p(core_val);
    otherwise
      p = [];
      fitd = [];
  end
  if do_plot
    if plot_logx
      semilogx(abs(values),density,'*-');
    else
      plot(values,density,'.-');
      if ~isempty(fitd)
        hold on
        plot(core_val,fitd); hold off
      end
    end
  end
end
