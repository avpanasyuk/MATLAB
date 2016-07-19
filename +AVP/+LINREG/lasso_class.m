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
    
    function [err, training] = K_fold_err(a,complexity,k,all_folds)
      %> @retval err is normalized by std(Y)
      if ~exist('k','var'), k = 10; end
      if exist('all_folds','var') &&  all_folds
        num_folds = k;
      else
        num_folds = 1;
      end
      
      n_test = fix(size(a.X.D,1)/k);
      err = zeros(1,num_folds);
      for foldI = 1:num_folds
        TestIds = (foldI - 1)*n_test + [1:n_test];
        Xtrain = a.X.D;
        Xtrain(TestIds,:) = [];
        y_train = a.y.D;
        y_train(TestIds) = [];
        
        % we are using z_scored X and y here, but it should not make any
        % difference
        training{foldI} = AVP.LINREG.lasso_class(Xtrain,y_train);
        training{foldI}.do_lasso(complexity);
        test_set = AVP.LINREG.lasso_class(a.X.D(TestIds,:),a.y.D(TestIds));
        
        err(foldI) = AVP.rms(test_set.get_error_zscored(training{foldI}.C));
      end
      err = median(err);
    end
    
    function Err_zscored = get_error_zscored(a,C_other_zscored)
      Err_zscored = a.X.D*C_other_zscored - a.y.D;
    end
    
    function errs = get_self_error(a)
      errs = AVP.rms(a.get_error_zscored(a.C));
    end
  end
end

