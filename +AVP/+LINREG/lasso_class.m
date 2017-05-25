classdef lasso_class < AVP.LINREG.input_data
  %> lasso_class evaluates lasso regression. Errors are aveluated using Kfold,
  %> either uniformly dividing on data blocks  or specified by the last index of
  %> each data block
  %> USE static lasso_class.do_regression(X,y) to do everything
  
  properties
    C %>< solution for zscored X,y
    FitInfo
  end
  
  methods
    function a = lasso_class(X,y)
      %> constructor just preprocess variables and do not run regression
      %> use "do_regression" for this
      %> @param X - [NumSamples,NumIndepParam] matrix
      %> @param y - [NumSamples] vector of dependent parameters
      a = a@AVP.LINREG.input_data(X,y);
      a.C = [];
    end
    
    function do_regression(a,complexity,varargin)
      AddForRelErr = AVP.opt_param'AddForRelErr',[];
      Alpha = AVP.opt_param'Alpha',1;
      
      if isempty(AddForRelErr) || AddForRelErr == 0
        weights = ones(numel(a.y.D),1);
      else
        weights = 1./(abs(a.y.D) + AddForRelErr);
      end
      
      [a.C, a.FitInfo] = lasso(a.X.D,a.y.D,'Lambda',10.^(-complexity),...
        'Standardize',false,'Options',statset('UseParallel',true),...
        'weights',weights,'Alpha',Alpha);
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
    function [err, Ypredict, C, Offset] = do_shebang(X,y,Log10_ComplRange,varargin)
      %> @param X - [NumSamples,NumIndepParam] matrix
      %> @param y - [NumSamples] vector of dependent parameters
      %> @param Log10_ComplRange - complexity range
      %> @param varargin
      %>        KfoldDividers - last index of each data block in Kfold
      %>        K - if KfoldDividers is not specidied uniformly divides
      %>            X and Y on K datablocks
      K = AVP.opt_param'K',10;
      KfoldDividers = [0,... % add 0 in front for convenience
        AVP.opt_param('KfoldDividers',[1:fix(size(X,1)/K)]*K,varargin{:})];
      fminbnd_options = AVP.opt_param('fminbnd_options',optimset('TolX',0.1),varargin{:});
      AddForRelErr = AVP.opt_param'AddForRelErr',0;
      
      % we divide the whole dataset on datablocks according to KfoldDividers
      % to calculate error for each block we do following: remove it from
      % dataset, calculate regression from this dataset and then calculate
      % error using removed block and RMS all such errors
      for dsI = 1:numel(KfoldDividers) - 1
        TrainIs = [1:KfoldDividers(dsI),KfoldDividers(dsI+1)+1:KfoldDividers(end)];
        l_train{dsI} = AVP.LINREG.lasso_class(X(TrainIs,:),y(TrainIs));
        TestIs{dsI} = [KfoldDividers(dsI)+1:KfoldDividers(dsI+1)];
        Xtest{dsI} = X(TestIs{dsI},:);
        ytest{dsI} = y(TestIs{dsI});
      end
      
      l_whole = AVP.LINREG.lasso_class(X,y); % does normalizations
      
      err_func = @(compl) ...
        AVP.LINREG.lasso_class.K_fold_err(...
        l_train, compl, Xtest, ytest, TestIs, ...
        'AddForRelErr', AddForRelErr);
      best_compl = fminbnd(err_func,...
        Log10_ComplRange(1),Log10_ComplRange(2),fminbnd_options);
      
      l_whole.do_regression(best_compl);
      [err, Ypredict] = err_func(best_compl);
      subplot(2,1,2)
      plot([y,Ypredict])
      set(gca,'XLim',[500 600])
      AVP.legend({'Calculated','True'});
      xlabel(sprintf('Error:%g, best_compl:%g',err,best_compl));
      drawnow
      
      [C, Offset] = l_whole.get_C();
    end
    
    function [err,Ypredict] = K_fold_err(l_train, compl, Xtest, Ytest, TestIs, varargin)
      % function to calculate error for a given complexity ..
      % return and cross_dataset error
      % @param l_train - cell array of linreg_class created with training data
      % @param compl - complexity to calculate with, lambda = 10^(-compl)
      % @param Xtest - cell array of independent test parameters
      % @param Ytest - cell array of dependent test parameters
      
      AddForRelErr = AVP.opt_param'AddForRelErr',0;
      
      % we calculate a total error over all partial datasets
      for dsI = 1:numel(l_train)
        l_train{dsI}.do_regression(compl, varargin{:});
        [C, Offset] = l_train{dsI}.get_C();
        
        Yp = Offset + Xtest{dsI}*C;
        
        Ypredict(TestIs{dsI},1) = Yp;
        ErrArr(dsI) = AVP.rms(AVP.rel_error(Ytest{dsI}+AddForRelErr,...
          Yp+AddForRelErr));
      end
      err = AVP.rms(ErrArr);
    end
  end
end

