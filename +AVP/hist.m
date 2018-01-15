function [density values ydivs] = hist(y,varargin)
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
  AVP.opt_param('show',false);
  idivs = round(linspace(1,n,nbins)).';
  y = sort(y);
  ydivs = y(idivs);
  
  density = (idivs(2:end)-idivs(1:end-1))./(ydivs(2:end)-ydivs(1:end-1));
  values = (ydivs(2:end)+ydivs(1:end-1))/2;
  
  if show, plot(values,density,'*-'); end
end
