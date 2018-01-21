classdef kfold_class < AVP.LINREG.input_data %>< AVP.LINREG.input_data object - whole dataset zscored
  %> class which prepares Kfolds for regression
  properties
    Xin %>< original data
    yin %>< original data
    KfoldDivs %>< array[K+1] of last indexes in each Kold. First index is 0
    train %>< cell array[K] of AVP.LINREG.input_data objects - Kfold training sets zscored
  end % properties
  
  methods
    function a = kfold_class(X,y,KfoldDivs)
      %> X and y may not be zscored
      a = a@AVP.LINREG.input_data(X,y);
      AVP.vars2struct('a')
      a.input_data = AVP.LINREG.input_data(X,y);
      
      for foldI = numel(KfoldDivs)-1:-1:1
        TrainInds = [1:KfoldDividers(Ki),KfoldDividers(Ki+1)+1:KfoldDividers(end)];
 
        a.train(foldI) =  ...
          AVP.LINREG.input_data(X(TrainInds,:), y(TrainInds)); % does zscore
      end
    end % constructor
  end % methods
end % class


