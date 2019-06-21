function [out_std, out_mean] = std(x, varargin)
  AVP.opt_param('pwr',2);
  AVP.opt_param('dim',1);
  
  out_mean = mean(x,dim);
  out_std = mean((x - AVP.repmat(out_mean,size(x,dim),dim)).^pwr,dim).^(1/pwr);
end
  