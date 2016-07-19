classdef zscored < handle
  properties
    D %> data
    Mean
    Std    
  end
  methods
    function a = zscored(x)
      [a.D, a.Mean, a.Std] = zscore(x);
    end
     
    function out = normalize_other(a,other)
      out = (other - repmat(a.Mean,size(other,1),1))./...
        repmat(a.Std,size(other,1),1);
    end
    
    function x = reconstruct(a)
      x = a.D.*repmat(a.Std,size(a.D,1),1) + repmat(a.Mean,size(a.D,1),1);
    end
  end
end
