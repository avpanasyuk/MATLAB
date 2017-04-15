function [d,f] = noise_density(t,v)
  %> @param t - time marks in sec
  %> @retval d - noise density in units/sqrt(samplinHz);
  n = fix(numel(v)/2)*2; % we need even number of samples
  t = t(1:n);
  v = v(1:n);
  
  dT = t(2:end)-t(1:end-1);
  dTm = median(dT);
  Tover = t(end)-t(1); % @ in sec
    
  ft = AVP.realfft(v);
  
  f = [0:n/2-1]/n/dTm; % Nyiquist
  d = abs(ft)*sqrt(Tover);
  % keyboard
end