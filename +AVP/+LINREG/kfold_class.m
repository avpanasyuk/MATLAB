%> Ok, what we feed to all regression algorithms is usually Kfolded dataset
%> with each training set zscored. Thta's what this class does

classdef kfold_class < AVP.LINREG.input_data %>< AVP.LINREG.input_data object - whole dataset zscored
  %> class which prepares Kfolds for regression
  properties
    Xin %>< original data
    yin %>< original data
    KfoldDivs %>< array[K+1] of last indexes in each Kold. First element is 0
    train %>< cell array[K] of AVP.LINREG.input_data objects - Kfold training sets zscored
  end % properties
  
  methods
    function a = kfold_class(X,y,KfoldDivs)
      %> X and y may not be zscored
      %> @param KfoldDivs: either array giving the last index of each fold
      %>       (first element is NOT 0)
      %>       or scalar giving K: number of uniformly distributed folds
      a = a@AVP.LINREG.input_data(X,y);
      a.Xin = X;
      a.yin = y;
      
      if numel(KfoldDivs) == 1.
        a.KfoldDivs = [0:round(size(X,1)/KfoldDivs):size(X,1)];
        a.KfoldDivs(end) = size(X,1);
      else
        a.KfoldDivs = [0;KfoldDivs(:)];
      end
      
      for foldI = numel(a.KfoldDivs)-1:-1:1
        TrainInds = [1:a.KfoldDivs(foldI),a.KfoldDivs(foldI+1)+1:a.KfoldDivs(end)];
        
        a.train{foldI} =  ...
          AVP.LINREG.input_data(X(TrainInds,:), y(TrainInds)); % does zscore
      end
    end % constructor
    
    function TestInds = get_test_inds(a,foldI)
      TestInds = [a.KfoldDivs(foldI)+1:a.KfoldDivs(foldI+1)];
    end % get_test_inds
    
    function [X,y] = get_test_data(a,foldI)
      %> returns original data subset
      TestInds = a.get_test_inds(foldI);
      X = a.Xin(TestInds,:);
      y = a.yin(TestInds);
    end
    
    function Ypredict = predict(a,regress_func,DoParallel)
      %> goes through Kfolds and applies REGRESS_FUNC to each training set,
      %> calculates prediction for corresponding test set, and combines all
      %> predictions into Ypredict
      %> @param regress_func(train_data), where train_data are
      %>               AVP.LINREG.input_data
      function y = predict(train_data, Xtest)
        %> function does regression of the train_data
        %>       (AVP.LINREG.input_data class)
        %>       and applies result to Xtest, which is not zscaled data
        C0 = regress_func(train_data);
        [C, Offset] = train_data.dezscore_solution(C0);        
        y = Offset + Xtest*C.';
      end
      
      hloop = @predict;
      
      if AVP.is_true('DoParallel')
        Ycell = {};
        parfor foldI = 1:numel(a.train)
          Inds = a.get_test_inds(foldI);
          Ycell{foldI}  = feval(hloop,a.train{foldI}, a.Xin(Inds,:));
        end
        Ypredict = vertcat(Ycell{:});
      else
        Ypredict = zeros(size(a.yin));
        for foldI = 1:numel(a.train)
          Inds = a.get_test_inds(foldI);
          Ypredict(Inds) = predict(a.train{foldI}, a.Xin(Inds,:));
        end
      end
    end % do_regress
  end % methods
end % class


