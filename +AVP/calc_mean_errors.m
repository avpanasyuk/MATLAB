%% Calculate mean errors
function [Bias Prec Accur] = calc_mean_errors(errors)
  Bias = mean(errors);
  Prec = std(errors);
  Accur = sqrt(mean(errors.^2));
end
