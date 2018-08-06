classdef pls_mdl < handle
  %> NOTE does not seem to reduce the numver of coeffs too well
  %> this class works with regression algorithm which can easily evaluate
  %> solution for different complexities simultaniously. It goes through
  %> iterations, selecting best complecity on each and throwing away small
  %> coefficients. We can select best iteration solution afterwards.
  properties
    C %>< dezscored solution Kfold_data.X.D,y
    Offset = 0 %>< dezscored solution Kfold_data.X.D,y
    options = struct;
    SelectParIs = {} % cell array of selected indep par indexes for each iteration
    KfoldErr = [] % array [num_iter] - error for each iteration
  end
  
  methods(Static)
    function C = do_regression(train_data,SelectParIs,varargin)
      %> this function does regression for all complexities simultaniosly,
      %> because complexity is just a number of singular vectors/values we
      %> are using. SO we calculate all of them, then throw them away one
      %> by one
      %> @param train_data: AVP.LINREG.input_data class
      %> @param SelectParIs - vector  of indexes of independent parameters we
      %>      use, the rest is ignored
      %> @param varargin - passed to plsregress
      %> @retval C - coeff array [num_complexities,all_xvar]
      
      if ~isa(train_data,'AVP.LINREG.input_data')
        error('Wrong input data type!');
      end
      
      [~,SUY,~,~,~,a.pctVar,~,stats] = ...
        plsregress(train_data.X.D(:,SelectParIs),train_data.y.D); % NO VARARGIN here
      V = stats.W;
      
      C = zeros(size(train_data.X.D,2),numel(SUY));
      for ComplI = numel(SUY):-1:1
        C(SelectParIs,ComplI) = V(:,1:ComplI)*AVP.to_column(SUY(1:ComplI));
      end
    end  % do_regression
  end % methods(Static)
  
  methods
    function a = pls_mdl(Kfold_data,varargin)
      %> constructor just preprocess variables and do not run regression
      %> use "do_regression" for this
      %> @param Kfold_data: AVP.linreg.kfold_class
      %> @param varargin
      %>        - ntol - interrupt iterrations when C changes less then this
      %>        - fminbnd_options
      %>        - WeightPwr - what power is supppression factor from coeff
      %>            smallness. The smaller it is, the smaller the error but
      %>             more coefficients.
      %>        - TuneWeightPwr - whether to tune WeightPwr in run time.
      %>        - err_func - function err_func(data,fit) to estimate an
      %>             error. Returns a single normalized error value.
      %>        - ComplRange - range of complixity changes, tuned.
      
      if ~isa(Kfold_data,'AVP.LINREG.kfold_class')
        error('Kfold_data should be AVP.LINREG.kfold_class!');
      end
      
      AVP.opt_param('tol',1e-2);
      AVP.opt_param('err_func',@(data,fit) AVP.rms(fit - data)./AVP.rms(data));
      AVP.opt_param('DoPar',false,0);
      AVP.opt_param('MaxIters',min([20,size(Kfold_data.Xin,2)]));
      
      CoeffsToThrowOutPerIter = fix(size(Kfold_data.Xin,2)/MaxIters);
            
      a.options = struct(varargin{:});
      
      SelectParIs = 1:size(Kfold_data.Xin,2);
      
      for IterI=1:MaxIters % because we throw away some parameters at each
        % iteration, we can not have more iterations than parameters
        
        % for each Kfold we have to run AVP.pls_mdl.do_regression once and
        % then calculate C for all the complexities and corresponding error for all the complexities
        % then we should add those errors for all the Kfold to get a total
        % error for complexity.

        Ypredict = Kfold_data.predict(@(train_data)...
          AVP.LINREG.pls_mdl.do_regression(train_data, SelectParIs, varargin{:}),DoPar);
        % Ypredict is array [num_samples,num_solutions]
        
        % calculate errors
        Errs = err_func(repmat(Kfold_data.yin,1,size(Ypredict,2)),Ypredict);
        
        % find best complexity
        [a.KfoldErr(IterI), BestCompl] = min(Errs);
        subplot(3,1,1)
        plot([Kfold_data.yin,Ypredict(:,BestCompl)],'.')
        legend({'data','fit'})
        title(sprintf('Iter %d',IterI))
        xlabel('SampleI')
        ylabel(sprintf('Data vs Fit, err = %g',a.KfoldErr(IterI)))
        
        % Ok, now lets get regression over all Kfolds at best complexity
        Czscaled =  AVP.LINREG.pls_mdl.do_regression(Kfold_data, SelectParIs, varargin{:});
        BestC(:,IterI) = Czscaled(:,BestCompl);
        % Czcaled and BestC first dimention corresponds to all variables
        subplot(3,1,2)
        plot(BestC(:,IterI))
        xlabel('Coeff index')
        ylabel('Coeffs')
        drawnow
        
        
        % find low sensitivity parameters
        SmallParIs = find(abs(BestC(SelectParIs,IterI)) < tol);
        a.SelectParIs{IterI} = SelectParIs;
        
        if numel(SmallParIs) < CoeffsToThrowOutPerIter % lets throw out least sensitive
          [~,SortedI] = sort(abs(BestC(SelectParIs,IterI)));
          %[~,LeastI] = min(abs(BestC(SelectParIs,IterI)));
          fprintf('Throwing out small coeffs!\n');
          if numel(SortedI) < CoeffsToThrowOutPerIter, break; end
          SelectParIs(SortedI(1:CoeffsToThrowOutPerIter)) = [];
        else
          fprintf('Number of small coeffs: %d\n',numel(SmallParIs));
          SelectParIs(SmallParIs) = [];
        end
        if isempty(SelectParIs), break; end % we ran out of parameters
      end
      
      % ok, lets see what is the best iteration
      subplot(3,1,3)
      NumParams = cellfun(@numel,a.SelectParIs);
      semilogy(NumParams,a.KfoldErr,'-+')
      xlabel('Number of Params')
      ylabel('Error')
      drawnow
      
      % pull out corresponding Coeffs
      [a.C, a.Offset] = Kfold_data.dezscore_solution(BestC);
    end % constructor
  end % methods
end % mysvd_mdl


function test
  Ns = 1000;
  x = rand(Ns,50);
  c = rand(50,1);
  c(21:end) = 0;
  y = x*c + 4*rand(Ns,1);
  
  Kfd = AVP.LINREG.kfold_class(x,y,10);
  
  tic
  m1 = AVP.LINREG.pls_mdl(Kfd);
  toc; tic
  m2 = AVP.LINREG.svd_mdl(Kfd);
  toc
  
  clf
  subplot(2,1,1)
  plot([c,m1.C])
  subplot(2,1,2)
  plot([c,m2.C])
end

