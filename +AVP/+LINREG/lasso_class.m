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
    
    function do_lasso(a,complexity,varargin)
      RelErrMin = AVP.opt_param('RelErrMin',{},varargin{:}); 
      if isempty(RelErrMin)
        weights = ones(numel(a.y.D),1);
      else
        weights = 1./(abs(a.y.D) + RelErrMin);
      end
      
      a.options = varargin;
      a.complexity = complexity;
      [a.C, a.FitInfo] = lasso(a.X.D,a.y.D,'Lambda',10.^(-complexity),...
        'Standardize',false,'Options',statset('UseParallel',true),...
        'weights',weights);
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
    
    function [Merit, Err, Ypredict, C, Offset] = ...
        CrossDataset_err(a,X2,Y2,complexity,varargin)
      %> this is a function for fminbnd to find best complecity
      %> @retval Err is error normalized by std(Y)
      %> @retval Merit is Err times numel(C)^NumelC_Pwr
      NumelC_Pwr = AVP.opt_param('NumelC_Pwr',0,varargin{:}); 

      a.do_lasso(complexity,varargin{:});
      [C, Offset] = get_C(a);
      Ypredict = X2*C + Offset; 
      Err = std(Ypredict - Y2,1,1)./std(Y2,1,1);
      Merit = Err*numel(find(C)).^NumelC_Pwr;
    end
    
  end
  methods(Static)
    function [err, Ypredict, C, Offset] = K_fold_err(X,Y,complexity,k,varargin)
      %> this is a function for fminbnd to find best complecity
      %> @retval err is normalized by std(Y)
      [Ypredict, C, Offset] = AVP.KfoldCrossVerif(...
        @(Xpart,Ypart) AVP.LINREG.lasso_class.run(Xpart,Ypart,complexity,...
        varargin{:}),X,Y,k);
      err = std(Ypredict - Y,1,1)./std(Y,1,1);
    end
    function [Coeffs, Offsets] = run(X,Y,complexity,varargin)
      % function for AVP.KfoldCrossVerif. 
      % @retval Coeffs - dezscored 
      % @retval Offsets 
      temp = AVP.LINREG.lasso_class(X,Y);
      temp.do_lasso(complexity,varargin{:});
      [Coeffs, Offsets] = temp.get_C();
    end
  end
end

