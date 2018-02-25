% DOES NOT WORK TOO WELL
function [C,SelectedVarIs] = princ_comp(X,y,varargin)
  %> @param X,y  - zscored
  AVP.opt_param('min_corr',1e-3);
  SelectedVarIs = [];
  RemainingVarIs = 1:size(X,2);
  C = zeros(size(X,2),1);
  
  for CompI=1:size(X,2) % maximium number of components is num of indep vars
    % find best correlation
    corrs = abs(X(:,RemainingVarIs).'*y);
    [~,MaxI_] = max(corrs);
    MaxI = RemainingVarIs(MaxI_);
    SelectedVarIs = [SelectedVarIs,MaxI]; 
    RemainingVarIs(MaxI_) = [];
    % C(SelectedVarIs,CompI) = X(:,SelectedVarIs)\y;
    % C(CompI) = max(corrs)/size(X,1);
    C(MaxI) = X(:,MaxI)\y;
    % ortagonalize with current variable
    corrs = (X(:,MaxI).'*X(:,RemainingVarIs))/size(X,1);
    X(:,RemainingVarIs) = X(:,RemainingVarIs) - X(:,MaxI)*corrs;    
  end
end % princ_comp

function test
  Ns = 1000;
  x = rand(Ns,50);
  c = rand(50,1);
  c(21:end) = 0;
  y = x*c + 4*rand(Ns,1);
  err_func = @(data,fit) AVP.rms(fit-data)./AVP.rms(data);
  
  Kfd = AVP.LINREG.kfold_class(x,y,10);
  
  [C,SelectedVarIs] = AVP.LINREG.princ_comp(Kfd.X.D,Kfd.y.D);
  plot([Kfd.y.D,Kfd.X.D*C(:,end)])
  err_func(Kfd.y.D,Kfd.X.D*C(:,end))
  subplot(2,1,1)
  plot([c,m.C])
  
  m = AVP.LINREG.mysvd_mdl(Kfd,'method','pls');
  subplot(2,1,2)
  plot([c,m.C])
end
