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
  [minstd,ii] = min(x_std(Same:end));
  Nbg = Same + ii - 1;              % absolute index of the min-std boundary (ii is relative to Same:end)
  bg = xs(Nbg);
  bg_std = minstd*sqrt(Nbg);
  % remove low outliers within the background cluster, then average
  cluster = xs(Same:Nbg);
  cluster = cluster(cluster >= bg - Nsigmas*bg_std);
  if isempty(cluster), cluster = xs(Same:Nbg); end   % degenerate guard (flat bg, bg_std ~ 0)
  bg = mean(cluster); bg_std = std(cluster);
end