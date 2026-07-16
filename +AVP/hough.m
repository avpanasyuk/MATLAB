function [H, theta, rho] = hough(BW, varargin)
  %> Standard Hough transform, drop-in replacement for the Image Processing
  %> Toolbox HOUGH so code depending on it runs without an IPT licence.
  %>
  %> Lines are parameterised as RHO = x*cos(THETA) + y*sin(THETA), where x is the
  %> column and y the row (0-based from the top-left), matching IPT's documented
  %> convention.
  %>
  %> @param BW - binary (or numeric) image; non-zero pixels vote.
  %> @param Theta - vector of angles in DEGREES to test. Default -90:89.
  %>   Restricting this to a narrow range is much faster and is the usual case
  %>   when the approximate line orientation is known.
  %> @param RhoResolution - spacing of the rho accumulator bins. Default 1.
  %>   NOTE: IPT accepts the abbreviation 'Rho'; AVP.opt_param matches names
  %>   exactly, so spell out 'RhoResolution'.
  %> @retval H - accumulator, numel(rho) x numel(Theta). H(i,j) counts votes for
  %>   rho(i), theta(j).
  %> @retval theta - the angles tested, in degrees (as passed in).
  %> @retval rho - vector of rho bin centres.
  %>
  %> Differences from IPT's HOUGH worth knowing: IPT sums the BW values whereas
  %> this counts non-zero pixels (identical for a logical BW, which is the normal
  %> input); and on an exact tie for the peak the two may pick different bins.
  %>
  %> See also AVP.disp_hough

  Theta = AVP.opt_param('Theta', -90:89);
  RhoResolution = AVP.opt_param('RhoResolution', 1);

  [nRows, nCols] = size(BW);
  [y, x] = find(BW);          % 1-based row/column of every voting pixel
  x = x - 1;                  % to 0-based, per the IPT convention
  y = y - 1;

  % rho spans the image diagonal, rounded out to a whole number of bins each side
  D = hypot(nRows - 1, nCols - 1);
  q = ceil(D / RhoResolution);
  rho = (-q:q) * RhoResolution;
  nRho = numel(rho);
  nTheta = numel(Theta);

  H = zeros(nRho, nTheta);
  if isempty(x), theta = Theta; return; end

  ct = cosd(Theta(:).');
  st = sind(Theta(:).');
  % One column of rho values per angle: nPixels x nTheta.
  r = x(:)*ct + y(:)*st;
  idx = round(r / RhoResolution) + q + 1;          % into 1..nRho
  idx = min(max(idx, 1), nRho);

  for j = 1:nTheta
    H(:,j) = accumarray(idx(:,j), 1, [nRho 1]);
  end
  theta = Theta;
end
