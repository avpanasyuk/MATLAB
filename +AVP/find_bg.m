function [bg bg_std] = find_bg(x, varargin)
  AVP.opt_param('Nsigmas',3);
  AVP.opt_param('LeastPortion',1e-3); % least portion of data considered to be a background
  AVP.opt_param('LeastNumber',10); % least portion of data considered to be a background
  
  % finds background level by selecting subset of points
  % with minimal std
  xs = sort(x(:));
  n = numel(xs);
  Same = find(xs ~= xs(1), 1, 'first');
  if isempty(Same) || Same > max(min(LeastNumber,n),n*LeastPortion) % all bg is the same
    bg = xs(1); bg_std = 0;
    return;
  end
  
  cs_x = cumsum(xs);
  cs_x2 = cumsum(xs.^2);
  N = [1:numel(xs)].';
  x_std = (cs_x2./N - (cs_x./N).^2)./sqrt(N-0.999);
  [bg_std,ii] = min(x_std(Same:end));
  bg_std = bg_std*sqrt(ii + Same);
  bg = xs(ii + Same);
  % removing outliers
  xs = xs(find(xs(Same:ii) >= bg - Nsigmas*bg_std));
  bg = mean(xs); bg_std = std(xs);
end