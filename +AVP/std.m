function out = std(x, varargin)
  AVP.opt_param('pwr',2);
  AVP.opt_param('dim',1);
  
  out = mean((x - mean(x,dim)).^pwr,dim).^(1/pwr);
end
  