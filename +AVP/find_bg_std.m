function [bg_std bg_points] = find_bg_std(x, varargin)
  %> @param x - vector
  AVP.opt_param('reps',5);
  AVP.opt_param('Nsigmas',3);
  
  x = double(x);
  
  bg_points = 1:numel(x);
  
  for RepI = 1:reps
    bg_std = std(x(bg_points));
    n = numel(bg_points);
    bg_points = find(x < mean(x(bg_points)) + Nsigmas*bg_std);
    if numel(bg_points) == n, break; end
  end
end