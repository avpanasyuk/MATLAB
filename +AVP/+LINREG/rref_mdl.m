DOES NOT WORK
classdef rref_mdl < handle
  %> this class works with regression algorithm which can easily evaluate
  %> solution for different complexities simultaniously
  properties
    C %>< solution for zscored Kfold_data.X.D,y, zeros for unused parameters
    Offset = 0
    KfoldErr
    options = struct;
  end
  
  methods
    function a = rref_mdl(Kfold_data,varargin)
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
      
      if ~isa(Kfold_data,'AVP.LINREG.kfold_class')
        error('Kfold_data should be AVP.LINREG.kfold_class!');
      end
      
      tol = 0; err_func = {}; DoPar = false; % we have to do it due to presence of nested function
      
      AVP.opt_param('tol',1e-12);
      AVP.opt_param('err_func',@(data,fit) AVP.rms(fit - data)./AVP.rms(data));
      AVP.opt_param('DoPar',false);
      
      function C = regress_func(train_data)
        if ~isa(train_data,'AVP.LINREG.input_data')
          error('train_data should be AVP.LINREG.input_data!');
        end
        [A,SelectParIs] = rref([train_data.X.D,train_data.y.D]);
        C = zeros(size(train_data.X.D,2),1);
        C(SelectParIs) = A(1:numel(SelectParIs)-1,end);
      end % regress_func
      
      % hmm, this methos is not minimizing for complexity, so we need Kfold 
      % to calculate errors only. 
      Ypredict = Kfold_data.predict(@regress_func, DoPar);
      a.KfoldErr = err_func(Kfold_data.y.D,Ypredict);
      plot([Kfold_data.y.D,Ypredict],'.')
      legend({'data','fit'})
      xlabel('SampleI')
      ylabel(sprintf('Data vs Fit, err = %g',a.KfoldErr))
      drawnow
      
      % calculate coeffs over whole dataset
      [a.C, a.Offset] = Kfold_data.dezscore_solution(regress_func(Kfold_data));
    end % constructor
  end % methods
end % mysvd_mdl


function test
  Ns = 1000;
  x = rand(Ns,50);
  c = rand(50,1);
  c(21:end) = 0;
  y = x*c + 4*rand(Ns,1);
  
  Kfd = AVP.LINREG.kfold_class(x,y,10);
  
  m = AVP.LINREG.rref_mdl(Kfd);
  subplot(2,1,1)
  plot([c,m.C])
  
  m = AVP.LINREG.mysvd_mdl(Kfd,'method','pls');
  subplot(2,1,2)
  plot([c,m.C])
end

