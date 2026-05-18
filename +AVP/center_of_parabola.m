function centroid = center_or_parabola(y)
	%> @param y is either 3 point or five point vector
	%> @return centroid is displacement relative to central value

switch numel(y)
	case 3
    % Parabolic interpolation formula
    centroid = 0.5 * (y(1) - y(3)) / (y(1) - 2*y(2) + y(3));
	case 5
    % Savitzky-Golay least-squares quadratic coefficients (5-point)
    a = (2*y(1) - y(2) - 2*y(3) - y(4) + 2*y(5)) / 14;
    b = (-2*y(1) - y(2) + y(4) + 2*y(5)) / 10;

    centroid = -b / (2 * a);        % fractional offset from peak index
	otherwise
		error("input is either 3 point or five point vector");
end

