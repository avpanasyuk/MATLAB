classdef myridge_class < AVP.LINREG.input_data
  %> myridge_class evaluates iterrating ridge regression, supressing and
  %> eliminating useless parameters. Errors are aveluated using Kfold,
  %> either uniformly dividing on data blocks  or specified by the last index of
  %> each data block
  %> USE static myridge_class.do_regression(X,y) to do everything
  
  properties
    C %>< solution for zscored X,y
  end
  
  properties(Constant)
    ComplFunc = @(ComplI) 10.^(1-ComplI^2)
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
      
      a.C = zeros(1,size(a.X.D,2));
      a.C(SelectPars) = (a.X.D(:,SelectPars).'*a.X.D(:,SelectPars) +...
        a.ComplFunc(complexity)*diag(ParSuppressFactor)*size(a.X.D,1))\...
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
    function [err, Ypredict, C, Offset, best_compl, options] = do_shebang(X,y,varargin)
      %> @param X - [NumSamples,NumIndepParam] matrix
      %> @param y - [NumSamples] vector of dependent parameters
      %> @param ComplRange - complexity range
      %> @param varargin
      %>        KfoldDividers - last index of each data block in Kfold.
      %>            First elements should be 0
      %>        K - if KfoldDividers is not specidied uniformly divides
      %>            X and Y on K datablocks
      %>        tol - interrupt iterrations when C changes less then this
      %>        fminbnd_options
      %>        WeightPwr - what power is supppression factor from coeff
      %>         smallness. The smaller it is, the smaller the error but
      %>         more coefficients.
      %>        SumSqrC_Pwr - in what power the sum of coeffs squares
      %>          enters merit function. Bigger values restrict
      %>          coefficients from growing too big. Tuned
      %>        err_func - function err_func(data,fit) to estimate an
      %>           error. Returns a single normalized error value.
      %>        ComplRange - range of complixity changes, tuned.
      %>        comb_merit_fun - combine inv_merit for each patient into a
      %>          single number to use for complexity optimization
      %> @retval err = err_func(y,Ypredict)
      
      AVP.opt_param('K',5,true);
      KfoldDividers = AVP.opt_param('KfoldDividers',round(0:size(X,1)/K:size(X,1)),true); % first element is 0 for convenience
      AVP.opt_param('tol',1e-2,true);
      AVP.opt_param('fminbnd_options',optimset('Display','none','TolX',0.1),true);
      AVP.opt_param('WeightPwr',3,true);
      AVP.opt_param('MaxIters',40,true);
      AVP.opt_param('ComplRange',[0,3],true); % range is well tuned!
      AVP.opt_param('SumSqrC_Pwr',0);
      AVP.opt_param('err_func',@(data,fit) AVP.rms(fit - data)/AVP.rms(data),true);
      AVP.opt_param('comb_merit_fun',@AVP.rms); 
      AVP.vars2struct('options');
      AVP.opt_param('DoPar',false);
      
      % we divide the whole dataset on datablocks according to KfoldDividers
      % to calculate error for each block we do following: remove it from
      % dataset, calculate regression from this dataset and then calculate
      % error using removed block and RMS all such errors
      for Ki = 1:numel(KfoldDividers) - 1
        TrainIs = [1:KfoldDividers(Ki),KfoldDividers(Ki+1)+1:KfoldDividers(end)];
        l_train{Ki} = AVP.LINREG.myridge_class(X(TrainIs,:),y(TrainIs));
        TestIs{Ki} = [KfoldDividers(Ki)+1:KfoldDividers(Ki+1)];
        Xtest{Ki} = X(TestIs{Ki},:);
        ytest{Ki} = y(TestIs{Ki});
      end
      
      l_whole = AVP.LINREG.myridge_class(X,y); % does normalizations
      
      % prepare for iterrations
      % set initial values
      ParSuppressFactor = ones(1,size(X,2)); % we will be removing useless parameters by
      % increasing ParSuppressFactor for small coefficients
      SelectPars = [1:size(X,2)]; % if parameter is too small we will remove it altogether
      % SelectPars are indexes of remaining parameters
      OldC = [];
      
      %best_compl = ComplRange(2);
      
      for IterI=1:MaxIters
        % find minimum Kfold error vs complexity
        inv_merit_func = @(compl) ...
          AVP.LINREG.myridge_class.K_fold_merit(...
          l_train, compl, Xtest, ytest, TestIs,err_func,...
          ParSuppressFactor,SelectPars,SumSqrC_Pwr,comb_merit_fun,DoPar);
        best_compl = fminbnd(inv_merit_func,...
          ComplRange(1),ComplRange(2),fminbnd_options);
        
        OldC = l_whole.C;
        l_whole.do_regression(best_compl,ParSuppressFactor,SelectPars);
        
        % plot results
        subplot(2,1,1)
        plot(l_whole.C)
        [best_merit, Ypredict] = inv_merit_func(best_compl);
        subplot(2,1,2)
        plot([Ypredict,y],'.')
        err = err_func(y,Ypredict);
        % set(gca,'XLim',[0 300])
        AVP.PLOT.legend({'Calculated','True'});
        xlabel(sprintf('err\\_func:%g, Nparam:%d, best\\_compl:%g, best\\_merit:%g',...
          err,numel(SelectPars),best_compl,best_merit));
        
        fprintf('compl:%3.1f,err:%6.4f,nC:%d,Merit:%6.4f\n',best_compl,err,numel(find(l_whole.C)),best_merit);
        drawnow
        
        if max(abs(l_whole.C)) > 10
          SumSqrC_Pwr = SumSqrC_Pwr+0.1;
          fprintf('SumSqrC_Pwr raised to %f due to high abs(C)\n', SumSqrC_Pwr);
        end
        
        % we are suppressing small coefficients
        CoeffNorm = abs(l_whole.C)/rms(l_whole.C);
        NewParSuppressFactor = CoeffNorm(SelectPars).^(-WeightPwr);
        IsParGood = NewParSuppressFactor*AVP.LINREG.myridge_class.ComplFunc(ComplRange(1)) < 1e8;
        if all(IsParGood) % we have not discarded any new parameters
          ParSuppressFactor = sqrt(ParSuppressFactor.*NewParSuppressFactor);
          WeightPwr = WeightPwr + (4 - WeightPwr)/8; % number of parameters is dropping too slow
          fprintf('WeightPwr is raised to %f because number of parameters is not decreasing\n', WeightPwr);
        else
          GoodI = find(IsParGood);
          SelectPars = SelectPars(GoodI);
          ParSuppressFactor = NewParSuppressFactor(GoodI);
          if numel(IsParGood) > numel(GoodI)*3/2 % number of parameters is dropping too fast
            WeightPwr = WeightPwr - (WeightPwr - 2)/4;
            fprintf('WeightPwr is dropped to %f because number of parameters is dropping too fast\n', WeightPwr);
          end
        end
        
        if numel(SelectPars) == 0
          SumSqrC_Pwr = SumSqrC_Pwr/1.1;
          fprintf('SumSqrC_Pwr lowered to %f due to convergence to constant\n', SumSqrC_Pwr);
          ParSuppressFactor = ones(1,size(X,2));
          SelectPars = [1:size(X,2)];
          OldC = [];
          IterI=1;
          continue
        end
        
        if ~isempty(OldC) && max(abs(OldC - l_whole.C)) < max(abs(OldC))*tol
          break
        end
      end
      
      [C, Offset] = l_whole.get_C();
      options.SumSqrC_Pwr = SumSqrC_Pwr;
    end
    
    
    function [inv_merit,Ypredict] = K_fold_merit(l_train, compl, Xtest, Ytest, TestIs, ...
        err_func, ParSuppressFactor,SelectPars,SumSqrC_Pwr, comb_merit_fun, DoPar)
      %> function to calculate invert of merit value  for a given complexity ..
      %> @param l_train - cell array of linreg_class created with training data
      %> @param compl - complexity to calculate with, lambda =
      %ComplFunc(ComplI)
      %> @param Xtest - cell array of independent test parameters
      %> @param Ytest - cell array of dependent test parameters
      %> @param SumSqrC_Pwr - in what power NumC enters merit function
      %> we calculate a total error over all partial datasets
      %> @param comb_merit_fun - function to combine merit for each patient
      %> into one merit to select complexity
      %> @retval inv_merit - error time max(C)^SumSqrC_Pwr
      
      function [Yp,InvMeritArr] = do_regression(l_train, Xtest, Ytest)
        l_train.do_regression(compl, ParSuppressFactor,SelectPars);
        [C, Offset] = l_train.get_C();
        
        Yp = Offset + Xtest*C.';
        
        InvMeritArr = err_func(Ytest,Yp)*(0.1+sum(l_train.C.^2)^SumSqrC_Pwr);       
      end
      
      hloop = @do_regression;
      
      if DoPar
        parfor Ki = 1:numel(l_train)
          [YpA{Ki},InvMeritArr(Ki)] = feval(hloop,l_train{Ki}, Xtest{Ki}, Ytest{Ki});
        end
      else
        for Ki = 1:numel(l_train)
           [YpA{Ki},InvMeritArr(Ki)] = do_regression(l_train{Ki}, Xtest{Ki}, Ytest{Ki});
       end
      end
      
      for Ki = 1:numel(l_train) % this is moved here so previous FOR can
        % be replaced by PARFOR
        Ypredict(TestIs{Ki},1) = YpA{Ki};
      end
      inv_merit = comb_merit_fun(InvMeritArr(:));
    end % K_fold_merit
  end % methods(Static)
end % myridge_class


function test
  Ns = 1000;
  x = rand(Ns,50);
  c = rand(1,50);
  c(21:end) = 0;
  y = x*c.' + 2*rand(Ns,1);
  
  [err, Ypredict, C, Offset, ~, options] = ...
    AVP.LINREG.myridge_class.do_shebang(x,y,'SumSqrC_Pwr',0,...
    'WeightPwr',3,'fminbnd_options',optimset('Display','none','TolX',0.1));
  
  plot([c;C].')
end

