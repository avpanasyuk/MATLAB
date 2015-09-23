function X = offset_and_scale(X,meanX,stdX)
  X = (X - repmat(meanX,size(X,1),1))./repmat(stdX,size(X,1),1);
end
