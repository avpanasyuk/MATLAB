function err = err_by_95perc(data,fit)
  % return 1-sigma error by finding 95 percentile and dividing by 2
   err = AVP.level_at_percentile(abs(fit-data)/rms(data),erf(2/sqrt(2)))/2;
end