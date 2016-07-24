classdef lasso_class < AVP.LINREG.input_data
  %> my_pc_class calculates my_pc results for a given complexity
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
      RelTol = 1e-4;
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
    
    function [err, training, Ypredict] = K_fold_err(a,complexity,k,all_folds)
      %> @retval err is normalized by std(Y)
      if ~exist('k','var'), k = 10; end
      if exist('all_folds','var') &&  all_folds
        num_folds = k;
      else
        num_folds = 1;
      end
      
      Ns = size(a.X.D,1);
      %n_test = fix(Ns/k);
      Ypred = cell(1,num_folds);

      PartBoundI = round(linspace(1,Ns+1,k+1));
      X = a.X.reconstruct();
      y = a.y.reconstruct(); 
      
      parfor foldI = 1:num_folds
        TestIds = [PartBoundI(foldI):PartBoundI(foldI+1)-1];
        Xtrain = X;
        Xtrain(TestIds,:) = [];
        y_train = y;
        y_train(TestIds) = [];
        
        % we are using z_scored X and y here, but it should not make any
        % difference
        training{foldI} = AVP.LINREG.lasso_class(Xtrain,y_train);
        training{foldI}.do_lasso(complexity);
        [Coeffs Offset] = training{foldI}.get_C();
        Ypred{foldI} = X(TestIds,:)*Coeffs + Offset;
      end
      Ypredict = vertcat(Ypred{:});
      err = std(Ypredict - y,1,1)./std(y,1,1);      
    end
    
    function Err_zscored = get_error_zscored(a,C_other_zscored)
      Err_zscored = a.X.D*C_other_zscored - a.y.D;
    end
    
    function errs = get_self_error(a)
      errs = AVP.rms(a.get_error_zscored(a.C));
    end
    
    function get_fit(a,other_C)
      if ~exist('other_C','var'), other_C = a.C; end
    end
  end
end

