%! this function estimate prediction capabilities of the regression 
%! by randomly dividing samples onto K subsets and for each subset 
%! calculating errors predicted regressing the rest of the data
%! @param X = [Num samples, N variables] matirx of independent variables
%! @param Y = [Num samples, 1] vector of dependent variable
%! @param regress_func = func(X,Y,...)
function [Ypredict, C] = KfoldCrossVerif(regress_func,X,Y,k,params)
  if ~exist('params','var'), params = {}; end
  Ns = size(X,1);
  Ypredict = Y; 
  % we got to pick samples randomly 
  Shuffle = randi([1,Ns],Ns,1);
  % Divide them on K subsets
  StartSub = round(linspace(1,Ns+1,k+1));
  for Isub=1:k
    SubSamples = Shuffle(StartSub(Isub):StartSub(Isub+1)-1);
    RestSamples = setdiff([1:Ns],SubSamples);
    C(:,Isub) = regress_func(X(RestSamples,:),Y(RestSamples),params{:});
    
    SScell{Isub} = SubSamples;
    Ypred{Isub} = X(SubSamples,:)*C(:,Isub);
  end
  
  for Isub=1:k, Ypredict(SScell{Isub}) = Ypred{Isub}; end
end
  