%> @file freq_comp - finding frequency components

function [pIs, Power] = freq_comp(x,n,varargin)
  % finds "n" maximum frequency component power and frequencies
  AVP.opt_param('goleyN',3);
  AVP.opt_param('w',11);
  nX = numel(x);
  
  f = AVP.realfft(double(x));
  ff = real(f.*conj(f));
  plot(ff)
  minff = max([min(ff),max(ff)/1000]);
  ff(ff < minff) = minff;
  ff = log(ff/minff);
  plot(ff)
  ff = sgolayfilt(ff,goleyN,w);
  all_pI_range = [];
  pIs = [];
  Power = [];
  for nI=1:n
    [peak,pI] = max(ff)
    if ismember(pI,all_pI_range), break; end
    pI_range = (max([1,pI - (w-1)/2]):...
      min([nX,pI + (w-1)/2])).';
    
    for tryI=1:2
      p = polyfit(pI_range,ff(pI_range),2);
      if p(1) >= 0, return; end % fitted dip
      this_peak = max(0,polyval(p,1:numel(ff))).';
      plot([ff,this_peak, ff - this_peak])
      % pause
      ff = ff - this_peak;
      pI_range = find(this_peak);
    end
    all_pI_range = [all_pI_range; pI_range];
    pIs = [pIs, -p(2)/2/p(1)];
    
    %calculate power
    Power = [Power,exp(p(3)-(p(2)/2)^2/p(1))*sqrt(pi)/sqrt(-p(1))*minff];
  end
end

