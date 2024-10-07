function C = svd(X,y,NumSVs)
  [Xs,mu,sigma] = zscore(X);
  
  [U,S,V] = svd(Xs,0); % X = U*S*V'.
  % we can not really use all S values, some of then are way too small and
  % screw things up
  S = diag(S);
  UY = U(:,1:LastSVi).'*train_data.y.D; % vector UY indicates correlation between Svects
  % and Y, we will prefer SVects with biggest correlation
  
  [~,SortI] = sort(abs(UY),'descend');
  % Ok, now we just have to reorder matrices in order of best vector correlation
  % and we are done
  V = V(:,SortI);
  SUY = UY(SortI)./S(SortI);
  
  C = zeros(size(train_data.X.D,2),numel(SUY));
  for ComplI = numel(SUY):-1:1
    C(SelectParIs,ComplI) = V(:,1:ComplI)*AVP.CONVERT.to_column(SUY(1:ComplI));
  end
end
