classdef lasso_class < AVP.LINREG.input_data
  %> lasso_class calculates my_pc results for a given complexity
  %> Lambda in lasso = 10^(-complexity)
  %> NOTE: MATLAB lasso is broken and does not calculate multiple lambdas
  %> in one call correctly
  properties
    C %>< solution for zscored X,y
    FitInfo
    complexity
    options
  end
  
  methods
    function a = lasso_class(X,y)
      %> constructor just preprocess variables and do not run lasso
      %> use "do_lasso" member function for this
      a = a@AVP.LINREG.input_data(X,y);
    end
    
    function do_lasso(a,complexity,options,varargin)
      % default options
      RelTol = 1e-3;
      if exist('options','var')
        if isfield(options,'RelTol'), RelTol = options.RelTol; end
      else options = [];
      end
      
      a.options = options;
      a.complexity = complexity;
      [a.C a.FitInfo] = lasso(a.X.D,a.y.D,'Lambda',10.^(-complexity),...
        'Standardize',false,'RelTol',RelTol,...
        'Options',statset('UseParallel',true),varargin{:});
    end
    
    function [C, Offset] = get_C(a, varargin)
      %> @param varargin (optional) - 'compexity'
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
    function [err, Ypredict, C, Offset] = K_fold_err(X,Y,complexity,k)
      %> this is a function for fminbnd to find best complecity
      %> @retval err is normalized by std(Y)
      [Ypredict, C, Offset] = AVP.KfoldCrossVerif(...
        @(Xpart,Ypart) AVP.LINREG.lasso_class.run(Xpart,Ypart,complexity),X,Y,k);
      err = std(Ypredict - Y,1,1)./std(Y,1,1);
    end
    function [Coeffs, Offsets] = run(X,Y,complexity)
      % function for AVP.KfoldCrossVerif. 
      % @retval Coeffs - zscored 
      % @retval Offsets - zeros (because on zscored data)
      temp = AVP.LINREG.lasso_class(X,Y);
      temp.do_lasso(complexity);
      [Coeffs Offsets] = temp.get_C();
    end
  end
end

