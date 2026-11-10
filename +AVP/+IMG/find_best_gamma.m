function [img gamma] = find_best_gamma(img)
  %> finds the gamma that brings the mean to 0.5; gamma stays positive, so the
  %> tone mapping stays monotonic and cannot solarize
  imgs = AVP.scale_to_range(double(img),[0,1]);
  % For imgs in [0,1], mean(imgs.^x) is non-increasing for x > 0. A washed-out
  % (very thin) negative needs gamma well above 10 -- film frames measured up
  % to ~46 -- so the bracket reaches 100. It starts just above 0 because
  % 0^0 = 1 makes f jump at x = 0: with over half the pixels at the minimum,
  % that jump is the only sign change and the solver would return it.
  % Too bright for the bracket: clamp to its top, the closest the mean gets
  % to 0.5. Too dark at its bottom: gamma = 1, NOT the closest-mean end -- a
  % gamma near 0 would push every non-minimum pixel to white and binarise.
  GammaLo = 1e-3; GammaHi = 100;
  f = @(x) mean(imgs(:).^x)-0.5;
  if ~isfinite(f(GammaHi))
    % a constant frame (scale_to_range divides by max-min = 0) or a NaN/Inf
    % pixel; return zeros, as the Python port does
    warning('AVP:find_best_gamma:degenerate', 'image is constant or non-finite; using gamma = 1');
    gamma = 1;
    imgs = zeros(size(imgs));
  elseif f(GammaHi) > 0
    warning('AVP:find_best_gamma:tooBright', ...
      'mean %.3f stays above 0.5 even at gamma = %g; using that', mean(imgs(:)), GammaHi);
    gamma = GammaHi;
  elseif f(GammaLo) < 0
    warning('AVP:find_best_gamma:tooDark', ...
      'mean stays below 0.5 even at gamma = %g (most pixels at or near the minimum); using gamma = 1', GammaLo);
    gamma = 1;
  else
    gamma = fzero(f,[GammaLo,GammaHi],optimset('Display','off','TolX',0.01));
  end
  img = imgs.^gamma;
end
