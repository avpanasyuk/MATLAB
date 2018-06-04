classdef myridge_mdl < handle
  %> myridge_class evaluates iterrating ridge regression, supressing and
  %> eliminating useless parameters (that's my contribution').
  %> Errors are evaluated using Kfold,
  %> either uniformly dividing on data blocks  or specified by the last index of
  %> each data block
  %> ridge regression is a regression which minimizes RMS error plus RMS
  %> coefficients*ComplFunc(complexity). Complexity is optimized in such
  %> a way that Kfold error is minimal.
  %> The problem with ridge regression is that it minimizes big coefficient
  %> is incensitive to small coefficients. I suggest to calculate RMS of
  %> coeffcients with weights, we makes smaller coefficients to get
  %> suprossed faster, eliminating them.
  %> USE static myridge_class.do_regression(Kfold_data.X.D,y) to do everything
  
  properties
    C %>< solution for zscored Kfold_data.X.D,y of length size(Kfold_data.X.D,2)
    %>< some (most) elements may be 0
    Offset = 0
    options = struct;
    SelectParIs = {} % cell array of selected indep par indexes for each iteration
    KfoldErr = [] % array [num_iter] - error for each iteration
  end
  
  methods(Static)
    function C = do_regression(train_data,SuppressPar,SelectParIs)
      %> lowest level function which calculated regression by LQR inversion with
      %> independent parameters selection and coefficients suppression
      %> @param SelectParIs - vector  of indexes of independent parameters we
      %>      use, the rest is ignored
      %> @param SuppressPar - individual suppression factor for each of
      %>      coefficients
      %> @param train_data: AVP.LINREG.input_data class
      %> retval C - [param_num,1]
      
      C = zeros(size(train_data.X.D,2),1);
      C(SelectParIs) = (train_data.X.D(:,SelectParIs).'*train_data.X.D(:,SelectParIs) +...
        diag(SuppressPar)*size(train_data.X.D,1))\...
        (train_data.X.D(:,SelectParIs).'*train_data.y.D);
    end  % do_regression
  end % methods(Static)
  
  methods
    function a = myridge_mdl(Kfold_data,varargin)
      %> constructor just preprocess variables and do not run regression
      %> use "do_regression" for this
      %> @param Kfold_data: AVP.linreg.kfold_class
      %> @param varargin
      %>        - ntol - interrupt iterrations when C changes less then this
      %>        - fminbnd_options
      %>        - WeightPwr - what power is supppression factor from coeff
      %>            smallness. The smaller it is, the smaller the error but
      %>             more coefficients.
      %>        - TuneWeightPwr - whether to tune WeightPwr in run time.
      %>        - err_func - function err_func(data,fit) to estimate an
      %>             error. Returns a single normalized error value.
      %>        - ComplRange - range of complixity changes, tuned.
      %> @retval err = err_func(y,Ypredict)
      
      AVP.cell_struct_varargin
      
      if ~isa(Kfold_data,'AVP.LINREG.kfold_class')
        error('Kfold_data should be AVP.LINREG.kfold_class!');
      end
      
      AVP.opt_param('tol',1e-2);
      AVP.opt_param('fminbnd_options',optimset('Display','none','TolX',0.05));
      AVP.opt_param('WeightPwr',3); %
      AVP.opt_param('SmallnessThres',0.1); %
      AVP.opt_param('ComplPwr',3); %
      AVP.opt_param('MaxIters',100);
      AVP.opt_param('ComplRange',[1,3]); % range is well tuned!
      AVP.opt_param('err_func',@(data,fit) AVP.rms(fit - data)/AVP.rms(data));
      AVP.opt_param('compl_step',0.3);
      AVP.opt_param('SuppressFunc',@(ComplI) 10.^(1-ComplI^2));
      AVP.opt_param('DoPar',false,0);
      a.options = struct(varargin{:});
      
      % prepare for iterrations
      % set initial values
      ParSuppressFactor = ones(size(Kfold_data.X.D,2),1); % we will be removing useless parameters by
      % increasing ParSuppressFactor for small coefficients
      SelectParIs = [1:size(Kfold_data.X.D,2)]; % if parameter is too small we will remove it altogether
      % SelectPars are indexes of remaining parameters
      NewC = [];
      OldBestCompl = [];
      
      for IterI=1:MaxIters
        % find minimum Kfold error vs complexity
        % we need something we can ffed to AVP.LINREG.kfold_class.predict
        % as REGRESS_FUNC, which returns Ypredict
        regress_func = @(compl, train_data) AVP.LINREG.myridge_mdl.do_regression(...
          train_data, SuppressFunc(compl)*ParSuppressFactor, SelectParIs);
        
        inv_merit_func = @(compl) ...
          err_func(Kfold_data.predict(@(train_data) regress_func(compl,train_data),DoPar),...
          Kfold_data.yin);
        best_compl = fminbnd(inv_merit_func,ComplRange(1),ComplRange(2),fminbnd_options);
        
        OldC = NewC;
        NewC = regress_func(best_compl,Kfold_data);
        
        % plot results
        subplot(2,1,1)
        plot(NewC)
        Kfold_predict = Kfold_data.predict(@(train_data) regress_func(best_compl,train_data),DoPar);
        subplot(2,1,2)
        plot([Kfold_predict,Kfold_data.yin],'.')
        err = err_func(Kfold_data.yin,Kfold_predict);
        % set(gca,'XLim',[0 300])
        AVP.PLOT.legend({'Kfold_predicted','Measured'});
        xlabel(sprintf('err\\_func:%5.3f, Nparam:%d, best\\_compl:%4.2f',...
          err,numel(SelectParIs),best_compl));
        
        fprintf('compl:%4.2f,err:%6.4f,nC:%d\n',best_compl,err,numel(find(NewC)));
        drawnow
        
        % we are suppressing and discarding small coefficients
        %         CoeffNorm = abs(NewC)/rms(NewC);
        %         NewParSuppressFactor = CoeffNorm(SelectPars).^(-WeightPwr);
        CoeffNorm = abs(NewC(SelectParIs))/rms(NewC(SelectParIs));
        NewParSuppressFactor = (CoeffNorm*best_compl^ComplPwr).^(-WeightPwr); % suppressing
        
        IsParGood = CoeffNorm > SmallnessThres*tol; % discarding
        GoodI = find(IsParGood);
        SelectParIs = SelectParIs(GoodI);
        
        if all(IsParGood) % we have not discarded any new parameters
          % I have a problem in that solution starts to oscullate between
          % two different complexity values. I've got to put dumping here.
          % I mix ParSuppressFactor between old and new, and the bigger is
          % difference between consequitive complexities the slower
          % ParSuppressFactor changes
          if ~isempty(OldC) && max(abs(OldC - NewC)) < max(abs(OldC))*tol
            break
          end
          
          if isempty(OldBestCompl) % first iter with this number of parameters occured
            steps = 0;
          else
            steps = abs(best_compl - OldBestCompl)/compl_step;
          end
          ParSuppressFactor = ...
            (ParSuppressFactor.^(steps+1).*NewParSuppressFactor).^(1/(steps+2));
          OldBestCompl = best_compl;
        else % next iterration has a different number of parameters
          OldBestCompl = [];
          ParSuppressFactor = sqrt(NewParSuppressFactor.*ParSuppressFactor);
        end
        
        ParSuppressFactor = ParSuppressFactor(GoodI);
      end
      
      [a.C, a.Offset] = Kfold_data.dezscore_solution(NewC);
    end
  end % constructor
end % myridge_mdl


function test
  Ns = 1000;
  x = rand(Ns,50);
  c = rand(50,1);
  c(21:end) = 0;
  y = x*c + 2*rand(Ns,1);
  
  Kfd = AVP.LINREG.kfold_class(x,y,10);
  
  m = AVP.LINREG.myridge_mdl(Kfd,'SmallnessThres',0.01,...
    'WeightPwr',3,'fminbnd_options',optimset('Display','none','TolX',0.1));
  
  plot([c,m.C])
end
