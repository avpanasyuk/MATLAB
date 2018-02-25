%> Ok, what we feed to all regression algorithms is usually Kfolded dataset
%> with each training set zscored. Thta's what this class does

classdef kfold_class < AVP.LINREG.input_data %>< AVP.LINREG.input_data object - whole dataset zscored
  %> class which prepares Kfolds for regression
  properties
    Xin %>< original data
    yin %>< original data
    KfoldDivs %>< either
    %>< array[K+1] of last indexes in each Kold. First element is 0.
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
    
    function Ypredict = predict(a, regress_func, DoParallel)
      %> goes through Kfolds and applies REGRESS_FUNC to each training set,
      %> calculates prediction for corresponding test set, and combines all
      %> predictions into Ypredict
      %> @param regress_func(train_data), where train_data are
      %>               AVP.LINREG.input_data, and which returns C is either
      %>               [x_varI] vector or [x_varI,num_solutions] matrix
      %>               (latter is when several cases/complexities are
      %>               calculated simultanously
      %> @retval Ypredict is [sampleI,num_solutions] array
      
      function y = predict(train_data, Xtest)
        %> function does regression of the train_data
        %>       (AVP.LINREG.input_data class)
        %>       and applies result to Xtest, which is not zscaled data
        %> retval y - predicted results array [num_samples,num_solutions]
        C0 = regress_func(train_data); % C0 may be matrix  [x_varI,num_solutions]
        [C, Offset] = train_data.dezscore_solution(C0);
        y = repmat(Offset,size(Xtest,1),1) + Xtest*C;
      end
      
      Ycell = {};
      hloop = @predict;
      if AVP.is_true('DoParallel')
        parfor foldI = numel(a.train):-1:1
          Inds = a.get_test_inds(foldI);
          Ycell{foldI}  = feval(hloop,a.train{foldI}, a.Xin(Inds,:));
        end
      else
        % Ypredict = zeros(size(a.yin),);
        for foldI = numel(a.train):-1:1
          Inds = a.get_test_inds(foldI);
          Ycell{foldI} = predict(a.train{foldI}, a.Xin(Inds,:));
        end
      end
      Ypredict = vertcat(Ycell{:});
    end % do_regress
  end % methods
end % class


