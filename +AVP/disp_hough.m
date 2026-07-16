function disp_hough(BW, H, theta, rho, N)
  %> overlays the N strongest AVP.hough lines on the image they came from.
  %> Handy for checking that a restricted-Theta search actually locked onto the
  %> edge you meant rather than onto some interior feature.
  %>
  %> @param BW - the image passed to AVP.hough
  %> @param H, theta, rho - what AVP.hough returned (theta in degrees)
  %> @param N - how many peaks to draw, default 1
  %>
  %> See also AVP.hough
  if ~AVP.is_defined('N'), N = 1; end

  imagesc(BW); colormap gray; hold on
  [~, order] = sort(H(:), 'descend');
  cols = 1:size(BW,2);
  for k = 1:min(N, numel(order))
    [rhi, thi] = ind2sub(size(H), order(k));
    t = theta(thi); r = rho(rhi);
    % rho = x*cosd(t) + y*sind(t), with x = column-1 and y = row-1 (0-based)
    if abs(sind(t)) > 1e-6
      plot(cols, (r - (cols-1)*cosd(t))/sind(t) + 1, 'Color', 'Red', 'LineWidth', 1)
    else
      plot([1 1]*(r/cosd(t) + 1), [1 size(BW,1)], 'Color', 'Red', 'LineWidth', 1)
    end
  end
  hold off
end
