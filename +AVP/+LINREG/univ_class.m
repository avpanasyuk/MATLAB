classdef univ_class < handle
  properties
    Kfold
  end
  function mdl = univ_class(Kf,linreg_class,varargin)
    %> @param Kf: AVP.LINREG.kfold_class - 
    %>        input data processed, cross-multiplied, kfolded and zscored
    a.Kfold = Kf;
    
    SelectParIs = [1:size(a.Kfold.Xin,2)]; % if parameter is too small we will remove it altogether

    for IterI=1:MaxIters
      linreg_class
    end

    mdl = [err, SelectParIs, Cs, Offset, options];
  end % univ_class
end % classdef univ_class