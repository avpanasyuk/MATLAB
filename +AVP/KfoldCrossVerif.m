function [Ypredict, C, Offset] = KfoldCrossVerif(regress_func,X,Y,k,varargin)
  %! this function estimate prediction capabilities of the regression
  %! by randomly dividing samples onto K subsets and for each subset
  %! calculating errors predicted regressing the rest of the data
  %! @param X = [Num samples, N variables] matirx of independent variables
  %! @param Y = [Num samples, M variables] vector of dependent variables
  %! @param regress_func is [Coeffs Offsets] = func(X,Y,...)
  %! @retval Ypredict - predicted Y, all k parts of each are collected from
  %! independent data
  %! @retval C
  func_params = AVP.opt_param('func_params',{},varargin{:});
  RandomPick = AVP.opt_param('RandomPick',false,varargin{:});
  
  Ns = size(X,1);
  if Ns ~= size(Y,1)
    error('KfoldCrossVerif: sizes not compatible!')
  end
  
  if RandomPick
    SampleI = randperm(Ns);
  else
    SampleI = 1:Ns;
  end
  
  C = zeros(size(X,2),size(Y,2),k);
  Offset = zeros(size(Y,2),k);
  
  % Divide them on K partitions
  PartBounds = round(linspace(1,Ns+1,k+1));
  parfor TestPartI=1:k
    TestSamplesI = SampleI(PartBounds(TestPartI):PartBounds(TestPartI+1)-1);
    
    Xtrain = X;
    Xtrain(TestSamplesI,:) = [];
    %Xtest = X(TestSamples,:);
    
    Ytrain = Y;
    Ytrain(TestSamplesI,:) = [];
    %Ytest = Y(TestSamplesI,:);
    
    [C(:,:,TestPartI), Offset(:,TestPartI)] = ...
      regress_func(Xtrain,Ytrain,func_params{:});
  end
  
  Ypredict = NaN(size(Y)); % just to set size
  for TestPartI=1:k
    TestSamplesI = SampleI(PartBounds(TestPartI):PartBounds(TestPartI+1)-1);
    Ypredict(TestSamplesI) = X(TestSamplesI,:)*C(:,:,TestPartI) + ...
      Offset(:,TestPartI);
  end
end
