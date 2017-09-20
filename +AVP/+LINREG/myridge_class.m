classdef myridge_class < AVP.LINREG.input_data
  %> myridge_class evaluates iterrating ridge regression, supressing and
  %> eliminating useless parameters. Errors are aveluated using Kfold,
  %> either uniformly dividing on data blocks  or specified by the last index of
  %> each data block
  %> USE static myridge_class.do_regression(X,y) to do everything
  
  properties
    C %>< solution for zscored X,y
  end
  
  methods
    function a = myridge_class(X,y)
      %> constructor just preprocess variables and do not run regression
      %> use "do_regression" for this
      %> @param X - [NumSamples,NumIndepParam] matrix
      %> @param y - [NumSamples] vector of dependent parameters
      a = a@AVP.LINREG.input_data(X,y);
      a.C = [];
    end
    
    function do_regression(a,complexity,ParSuppressFactor,SelectPars)
      %> lowest level function which calculated regression by LQR inversion with
      %> independent parameters selection and coefficients suppression
      %> @param complexity - log-scaled value, suppress amplitude of all
      %>      coefficients uniformly
      %> @param SelectPars - vector  of indexes of independent parameters we
      %>      use, the rest is ignored
      %> @param ParSuppressFactor - individual suppression factor for each of
      %>      coefficients, the smaller coefficient the higher is suppress
      %>      factor
      
      a.C = zeros(size(a.X.D,2),1);
      a.C(SelectPars) = (a.X.D(:,SelectPars).'*a.X.D(:,SelectPars) +...
        10.^(-complexity)*diag(ParSuppressFactor))\...
        (a.X.D(:,SelectPars).'*a.y.D);
    end
    
    function [C, Offset] = get_C(a)
      [C, Offset] = a.dezscore_solution(a.C);
    end
    
    
    function Err_zscored = get_error_zscored(a,C_other_zscored)
      Err_zscored = a.X.D*C_other_zscored - a.y.D;
    end
    
    function errs = get_self_error(a)
      errs = AVP.rms(a.get_error_zscored(a.C));
    end
  end
  
  methods(Static)
    function [err, Ypredict, C, Offset, options] = do_shebang(X,y,Log10_ComplRange,varargin)
      %> @param X - [NumSamples,NumIndepParam] matrix
      %> @param y - [NumSamples] vector of dependent parameters
      %> @param Log10_ComplRange - complexity range
      %> @param varargin
      %>        KfoldDividers - last index of each data block in Kfold
      %>        K - if KfoldDividers is not specidied uniformly divides
      %>            X and Y on K datablocks
      %>        tol - interrupt iterrations when C changes less then this
      %>        fminbnd_options
      %>        WeightPwr - what power is supppression factor from coeff
      %>         smallness
      %>        CoeffThres - when coeff is smaller then this part of max in
      %>           WeightPwr power ignore corresponding indep var
      %>        SumSqrC_Pwr - in what power MaxC enters merit function
      %> @retval err = AVP.rms(y - Ypredict)/AVP.rms(y);
      
      AVP.opt_param('K',10,true);
      KfoldDividers = [0,... % add 0 in front for convenience
        AVP.opt_param('KfoldDividers',fix([1:K]*size(X,1)/K),true)];
      AVP.opt_param('tol',1e-2,true);
      AVP.opt_param('fminbnd_options',optimset('TolX',0.1),true);
      AVP.opt_param('WeightPwr',4,true);
      AVP.opt_param('CoeffThres',0.01,true);
      AVP.opt_param('MaxIters',40,true);
      AVP.opt_param('err_func',@(data,fit) AVP.rms(fit - data)./AVP.rms(data),true);
      AVP.opt_param('SumSqrC_Pwr',0);
      AVP.vars2struct('options', 'KfoldDividers', 'fminbnd_options', 'WeightPwr',...
        'CoeffThres', 'MaxIters','err_func','SumSqrC_Pwr');
      
      % we divide the whole dataset on datablocks according to KfoldDividers
      % to calculate error for each block we do following: remove it from
      % dataset, calculate regression from this dataset and then calculate
      % error using removed block and RMS all such errors
      for dsI = 1:numel(KfoldDividers) - 1
        TrainIs = [1:KfoldDividers(dsI),KfoldDividers(dsI+1)+1:KfoldDividers(end)];
        l_train{dsI} = AVP.LINREG.myridge_class(X(TrainIs,:),y(TrainIs));
        TestIs{dsI} = [KfoldDividers(dsI)+1:KfoldDividers(dsI+1)];
        Xtest{dsI} = X(TestIs{dsI},:);
        ytest{dsI} = y(TestIs{dsI});
      end
      
      l_whole = AVP.LINREG.myridge_class(X,y); % does normalizations
      
      % prepare for iterrations
      % set initial values
      ParSuppressFactor = ones(1,size(X,2)); % we will be removing useless parameters by
      % increasing ParSuppressFactor for small coefficients
      SelectPars = [1:size(X,2)]; % if parameter is too small we will remove it altogether
      % SelectPars are indexes of remaining parameters
      OldC = [];
      Niter = 0;
      
      for IterI=1:MaxIters
        % find minimum Kfold error vs complexity
        inv_merit_func = @(compl) ...
          AVP.LINREG.myridge_class.K_fold_merit(...
          l_train, compl, Xtest, ytest, TestIs,err_func,...
          ParSuppressFactor,SelectPars,SumSqrC_Pwr);
        best_compl = fminbnd(inv_merit_func,...
          Log10_ComplRange(1),Log10_ComplRange(2),fminbnd_options);
        
        OldC = l_whole.C;
        l_whole.do_regression(best_compl,ParSuppressFactor,SelectPars);
        
        % plot results
        subplot(2,1,1)
        plot(l_whole.C)
        [~, Ypredict] = inv_merit_func(best_compl);
        subplot(2,1,2)
        plot([Ypredict,y],'.')
        err = err_func(y,Ypredict);
        % set(gca,'XLim',[0 300])
        AVP.legend({'Calculated','True'});
        xlabel(sprintf('Error:%g, Nparam:%d, best_compl:%g',...
          err,numel(SelectPars),best_compl));
        drawnow
        
        CoeffNorm = abs(l_whole.C)/max(abs(l_whole.C));
        SelectPars = find(CoeffNorm > CoeffThres);
        ParSuppressFactor = (CoeffNorm(SelectPars)).^(-WeightPwr);
 
        Niter = Niter + 1;

        if ~isempty(OldC) && max(abs(OldC - l_whole.C)) < max(abs(OldC))*tol
          break
        end
      end
      
      [C, Offset] = l_whole.get_C();
    end
    
    function [inv_merit,Ypredict] = K_fold_merit(l_train, compl, Xtest, Ytest, TestIs, ...
        err_func, ParSuppressFactor,SelectPars,SumSqrC_Pwr)
      % function to calculate invert of merit value  for a given complexity ..
      % @param l_train - cell array of linreg_class created with training data
      % @param compl - complexity to calculate with, lambda = 10^(-compl)
      % @param Xtest - cell array of independent test parameters
      % @param Ytest - cell array of dependent test parameters
      % we calculate a total error over all partial datasets
      %> @retval inv_merit - error time max(C)^SumSqrC_Pwr
        
      for dsI = 1:numel(l_train)
        l_train{dsI}.do_regression(compl, ParSuppressFactor,SelectPars);
        [C, Offset] = l_train{dsI}.get_C();
        
        Yp = Offset + Xtest{dsI}*C;
        
        YpA{dsI} = Yp;
        % InvMeritArr(dsI) = err_func(Ytest{dsI},Yp)*max(abs(l_train{dsI}.C))^MaxC_Pwr;
        InvMeritArr(dsI) = err_func(Ytest{dsI},Yp)*sum(l_train{dsI}.C.^2)^SumSqrC_Pwr;
      end
      
      for dsI = 1:numel(l_train) % this is moved here so previous FOR can
        % be replaced by PARFOR
        Ypredict(TestIs{dsI},1) = YpA{dsI};
      end
      inv_merit = AVP.rms(InvMeritArr);
    end % K_fold_merit
  end % methods(Static)
end % myridge_class


function test
  Ns = 1000;
  x = rand(Ns,50);
  c = rand(50,1);
  c(21:end) = 0;
  y = x*c + rand(Ns,1);
  
  [err, Ypredict, C, Offset] = ...
    AVP.LINREG.myridge_class.do_shebang(x,y,[-4,2],...
    'fminbnd_options',optimset('Display','iter','TolX',0.1));
  
  plot([c,C])
end

