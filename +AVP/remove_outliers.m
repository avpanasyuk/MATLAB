function [Out,OutliersInds,Mean,Std] = remove_outliers(x,varargin)
  % rempves outliers from a vector
  AVP.opt_param('Nsigmas',3);
  
  [OutliersInds,Mean,Std] = deal([]);
  Out = x(:);
  
  while 1
    
    Mean = mean(Out);
    Std = std(Out);
    CurBadInds = find(Out > Mean + Nsigmas*Std | Out < Mean - Nsigmas*Std);
    if isempty(CurBadInds), break; end
    OutliersInds = [OutliersInds,CurBadInds];
    Out(CurBadInds) = [];
    
  end
end