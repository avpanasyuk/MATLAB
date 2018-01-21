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
  end % methods
  
  methods(Static)
    function do_regression(X,y,maxSinv)
      %>< X,y - zscored
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
    end % do_regression
    
    function [err, Ypredict, C, Offset, best_compl, options] = do_shebang(X,y,KfoldDiv,varargin)
      %> @param X - [NumSamples,NumIndepParam] matrix
      %> @param y - [NumSamples] vector of dependent parameters
      AVP.opt_param('MaxIters',100,true);
      
      Kf = AVP.LINREG.kfold_class(X,y,KfoldDiv);

      SelectPars = [1:size(X,2)]; % SelectPars are indexes of remaining parameters
      OldC = [];
      
      for IterI=1:MaxIters
        % find minimum Kfold error vs complexity
        inv_merit_func = @(compl) ...
          AVP.LINREG.my_pc_class.K_fold_merit(...
          l_train, compl, Xtest, ytest, TestIs,err_func,...
          ParSuppressFactor,SelectPars,SumSqrC_Pwr,comb_merit_fun,DoPar);
        best_compl = fminbnd(inv_merit_func,...
          ComplRange(1),ComplRange(2),fminbnd_options);
        
        OldC = l_whole.C;
        l_whole.do_regression(best_compl,ParSuppressFactor,SelectPars); % calculate new C
        
        % plot results
        subplot(2,1,1)
        plot(l_whole.C)
        [best_merit, Ypredict] = inv_merit_func(best_compl);
        subplot(2,1,2)
        plot([Ypredict,y],'.')
        err = err_func(y,Ypredict);
        % set(gca,'XLim',[0 300])
        AVP.PLOT.legend({'Calculated','True'});
        ylabel('Kfold prediction');
        xlabel(sprintf('err\\_func:%5.3f, Nparam:%d, best\\_compl:%4.2f, best\\_merit:%5.3f',...
          err,numel(SelectPars),best_compl,best_merit));
        
        fprintf('compl:%4.2f,err:%6.4f,nC:%d,Merit:%6.4f\n',best_compl,err,numel(find(l_whole.C)),best_merit);
        drawnow
        
        %         if max(abs(l_whole.C)) > 10
        %           SumSqrC_Pwr = SumSqrC_Pwr+0.1;
        %           fprintf('SumSqrC_Pwr raised to %f due to high abs(C)\n', SumSqrC_Pwr);
        %         end
        
        % we are suppressing and discarding small coefficients
        %         CoeffNorm = abs(l_whole.C)/rms(l_whole.C);
        %         NewParSuppressFactor = CoeffNorm(SelectPars).^(-WeightPwr);
        CoeffNorm = abs(l_whole.C(SelectPars))/rms(l_whole.C(SelectPars));
        NewParSuppressFactor = (CoeffNorm*best_compl^ComplPwr).^(-WeightPwr); % suppressing
        
        IsParGood = CoeffNorm > SmallnessThres*tol; % discarding
        GoodI = find(IsParGood);
        SelectPars = SelectPars(GoodI);
        
        if all(IsParGood) % we have not discarded any new parameters
          % I have a problem in that solution starts to oscullate between
          % two different complexity values. I've got to put dumping here.
          % I mix ParSuppressFactor between old and new, and the bigger is
          % difference between consequitive complexities the slower
          % ParSuppressFactor changes
          if ~isempty(OldC) && max(abs(OldC - l_whole.C)) < max(abs(OldC))*tol
            break
          end
          
          if SameNumParIter == 0 % first iter with this number of parameters occured
            steps = 0;
          else
            steps = abs(best_compl - OldBestCompl)/compl_step;
          end
          ParSuppressFactor = (ParSuppressFactor.^(steps+1).*NewParSuppressFactor).^(1/(steps+2));
          if TuneWeightPwr && SameNumParIter > 2
            WeightPwr = WeightPwr + (8 - WeightPwr)/4; % number of parameters is dropping too slow
            fprintf('WeightPwr is raised to %f because number of parameters is not decreasing\n', WeightPwr);
          end
          SameNumParIter = SameNumParIter + 1;
          OldBestCompl = best_compl;
          
          subplot(2,1,1)
          plot(CoeffNorm)
          subplot(2,1,2)
          semilogy([ParSuppressFactor;NewParSuppressFactor].')
          
        else % next iterration has a different number of parameters
          SameNumParIter = 0;
          ParSuppressFactor = sqrt(NewParSuppressFactor.*ParSuppressFactor);
        end
        
        ParSuppressFactor = ParSuppressFactor(GoodI);
        
        %         if numel(SelectPars) == 0
        %           SumSqrC_Pwr = SumSqrC_Pwr/1.1;
        %           fprintf('SumSqrC_Pwr lowered to %f due to convergence to a constant\n', SumSqrC_Pwr);
        %           ParSuppressFactor = ones(1,size(X,2));
        %           SelectPars = [1:size(X,2)];
        %           OldC = [];
        %           IterI=1;
        %           continue
        %         end
        % pause
      end
      
      [C, Offset] = l_whole.get_C();
      options.SumSqrC_Pwr = SumSqrC_Pwr;
    end
    
    
    function [inv_merit,Ypredict] = K_fold_merit(kfold, compl, SelectPars, DoPar)    
      function [Yp,InvMeritArr] = do_regression(l_train, Xtest, Ytest)
        l_train.do_regression(compl, ParSuppressFactor,SelectPars);
        [C, Offset] = l_train.get_C();
        
        Yp = Offset + Xtest*C.';
        
        InvMeritArr = err_func(Ytest,Yp)*(0.1+sum(l_train.C.^2)^SumSqrC_Pwr);
      end
      
      hloop = @do_regression;
      
      if DoPar
        parfor Ki = 1:numel(l_train)
          [YpA{Ki},InvMeritArr(Ki)] = feval(hloop,l_train{Ki}, Xtest{Ki}, Ytest{Ki});
        end
      else
        for Ki = 1:numel(l_train)
          [YpA{Ki},InvMeritArr(Ki)] = do_regression(l_train{Ki}, Xtest{Ki}, Ytest{Ki});
        end
      end
      
      for Ki = 1:numel(l_train) % this is moved here so previous FOR can
        % be replaced by PARFOR
        Ypredict(TestIs{Ki},1) = YpA{Ki};
      end
      inv_merit = comb_merit_fun(InvMeritArr(:));
    end % K_fold_merit
  end % methods(Static)
  
end % class

