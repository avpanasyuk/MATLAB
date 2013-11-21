function [density values bin_bounds] = avp_hist(y,nbins,show),
% usually histogam is calculated by taking all values range, dividing it on
% equal ranges,  and then calculating number of points in each range.
% Causes big instability as some ranges have a lot of points and some
% don't.
% instead we make bins with equal number of points. Density in this case is
% 1/change in value over the current bin. 
% Problem arises when there is no change in value over the current bin. So
% we picking up unique values first.
    y = y(find(isfinite(y)));
    [uy k l] = unique(sort(y)); %uy is unique y values
    
    if nargin < 2 || isempty(nbins), nbins = ceil(sqrt(numel(y))); end % by default the number of bins 
    if nargin < 3 || isempty(show), show = 0; end
	% is determined by whole vector length

    nuy = numel(uy);
    ndivs = 1:max([floor((nuy-1)/nbins) 1]):(nuy-1); % NBINS can not be bigger then 
    % number of unique elements
    
    k = [0;k];
    % density is the number of total (non-unique) points in bin divided by
    % the value range in this bin
    density = (k(ndivs+1) - k(ndivs))./(uy(ndivs+1)-uy(ndivs))/numel(y);
    values = (uy(ndivs+1)+uy(ndivs))/2;
    bin_bounds = [uy(ndivs);uy(end)];
	if show, plot(values,density,'*'); end
end
