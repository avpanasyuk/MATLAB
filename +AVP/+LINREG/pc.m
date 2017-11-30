% no sense
function C = pc_regress(X,Y,min_sv)
  if ~exist('min_sv','var'), min_sv = 1e-3; end
  C = zeros(size(X,2),1);

  % remove linearly dependent columns in X
  [~,li] = rref(X.',min_sv);
  if isempty(li), return; end
  X = X(:,li);
  
  for iter=1:numel(li)
  % looking for a linear combination of X column which fit Y best
  % No, because it immediately gives us the solution. We need to use
  % the vectors we have
  
  % see what X column fits Y best
  
  a = pinv(X'*X, min_sv)*(X'*Y);
  [~,BestI] = max(abs(a));
  C(BestI) = a(BestI);
  pc = X(:,BestI);
  plot(real([pc*a(BestI),Y])); drawnow
  % orthogonize the rest of columns by subtracting 
  X = X - pc*(pinv(pc'*pc,min_sv)*(pc'*X));
  X(:,BestI) = [];
  Y = Y - pc*a(BestI);
  % columns are now linearly dependent, let's through away the smallest
  col_abs = sum(X.*conj(X)); 
  [~,mini] = min(col_abs);
  li(mini) = []; X(:,mini) = [];
  Y = Y - pc*((pc'*Y)/(pc'*pc)); % remove current principal component from Y  
  end
end

function test
  X = zscore(rand(20,4));
  % C0 = rand(2,1);
  % X = [X,X(:,1:2)*C0]; %making one linearly dependent row
  C1 = rand(4,1);
  Y = X*C1;
  Y = Y + rand(20,1)*0.1;
end
