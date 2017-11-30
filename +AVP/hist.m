function [density values ydivs] = hist(y,nbins,show),
% usually histogam is calculated by taking all values range, dividing it on
% equal ranges,  and then calculating number of points in each range.
% Causes big instability as some ranges have a lot of points and some
% don't.
% instead we make bins with equal number of points. Density in this case is
% 1/change in value over the current bin. 
% Problem arises when there is no change in value over the current bin. So
% we picking up unique values first.
    y = y(isfinite(y(:)));
    n = numel(y);
    if nargin < 2 || isempty(nbins), nbins = ceil(sqrt(n)); end % by default the number of bins 
    if nargin < 3 || isempty(show), show = 0; end
    
    idivs = round(linspace(1,n,nbins)).';
    y = sort(y);
    ydivs = y(idivs);
    
    density = (idivs(2:end)-idivs(1:end-1))./(ydivs(2:end)-ydivs(1:end-1));
    values = (ydivs(2:end)+ydivs(1:end-1))/2;
    
	  if show, plot(values,density,'*-'); end
end
