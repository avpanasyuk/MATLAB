classdef my_pc_class < AVP.LINREG.input_data
  % my_pc_class calculates my_pc results with different complexity
  properties
    U %>< matrix U from svd
    V %>< matrix V from svd
    Sinv %>< inverted S diagonal from svd
    Corrs %>< U to y correlation
  end
  
  methods
    function a = my_pc_class(X,y, maxSinv)
      a = a@AVP.LINREG.input_data(X,y);
      [U,S,V] = svd(a.X.D,0); % X = U*S*V'
      Sinv = 1./diag(S);
      
      % remove overlarge Sinvs which just multiply noise
      if exist('maxSinv','var')
        GoodI = find(Sinv < maxSinv);
        Sinv = Sinv(GoodI);
        V = V(:,GoodI);
        U = U(:,GoodI);        
      end
      
      % calculate all correlations
      a.Corrs = U.'*a.y.D; % no need to normalize, U - orthonormal
      [~,SortI] = sort(abs(a.Corrs),'descend');
      % Ok, now we just have to reorder matrices in order of best vector correlation
      % and we are done
      a.V = V(:,SortI);
      a.Sinv = Sinv(SortI);
      a.U = U(:,SortI);
      a.Corrs = a.Corrs(SortI);
    end
    
    function C_zscored = get_C_zscored(a,complexity)
      if ~exist('complexity','var'),  complexity = numel(a.Sinv); end
      C_zscored = a.V(:,1:complexity)*diag(a.Sinv(1:complexity))*a.Corrs(1:complexity);
    end
    
    function [C, Offset] = get_C(a, varargin)
      %> @param varargin (optional) - 'compexity'
      [C, Offset] = a.dezscore_solution(a.get_C_zscored(varargin{:}));
    end
      
    function err_vs_complexity = K_fold_err_vs_complexity(a,k)
      if ~exist('k','var'), k = 10; end
      n_test = ceil(size(a.X.D,1)/k);
      err_vs_complexity = zeros(numel(a.Sinv),k);
      for repI = 1:k
        TestIds = (repI - 1)*n_test + [1:n_test];
        Xtrain = a.X.D;
        Xtrain(TestIds,:) = [];
        y_train = a.y.D;
        y_train(TestIds) = [];

        % we are using z_scored X and y here, but it should not make any
        % difference
        training = AVP.LINREG.my_pc_class(Xtrain,y_train);
        test_set = AVP.LINREG.my_pc_class(a.X.D(TestIds,:),a.y.D(TestIds));
        
        for complexity=1:numel(a.Sinv)
          err_vs_complexity(complexity,repI) = ...
            AVP.rms(test_set.get_error_zscored(training.get_C_zscored(complexity)));
        end
      end
      err_vs_complexity = median(err_vs_complexity,2);
    end
    
    function Err_zscored = get_error_zscored(a,C_other_zscored)
      Err_zscored = a.X.D*C_other_zscored - a.y.D;
    end
    
    function errs = get_self_errors(a,complexity)
      if ~exist('complexity','var'), complexity=1:numel(a.Sinv); end
      errs = arrayfun(@(compl) ...
      AVP.rms(a.get_error_zscored(a.get_C_zscored(compl))),...
        complexity);
    end
  end    
end

