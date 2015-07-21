% @param X (and Y and Z) - vectors of the same length
function [Xout,Yout,Zout] = cloud_surface(X,Y,Z,options)
  % default values
  Grid = numel(X).^0.25;
  Grid = ceil([Grid,Grid]);
  if exist('options','var') && ~empty(options)
    if isfield(options,'Grid'), Grid = options.Grid; end
  end
  
  % Ok, now we have to distribute vectors X and Y uniformly
  Xsorted = sort(X);
  XsortedBinned = reshape(Xsorted(1:fix(numel(X)/Grid(1))*Grid(1)),...
    [],Grid(1));
  Xbins = median(XsortedBinned);
  Xunif = interp1(Xbins,1:Grid(1),X,'spline');
  % now most of X are uniformly spaced between 1 and Grid(1)
  
  Ysorted = sort(Y);
  YsortedBinned = reshape(Ysorted(1:fix(numel(Y)/Grid(2))*Grid(2)),...
    [],Grid(2));
  Ybins = median(YsortedBinned);
  Yunif = interp1(Ybins,1:Grid(2),Y,'spline');
  % now most of Y are uniformly spaced between 1 and Grid(2)
  
  kdt = KDTreeSearcher([Xunif,Yunif]);
  function [Xavg, Yavg, Zavg] = SumNeighbours(X_,Y_)
    neibI = rangesearch(kdt,[X_,Y_],1/sqrt(2));
    Xavg = mean(X(neibI{1}));
    Zavg = mean(Z(neibI{1}));
    Yavg = mean(Y(neibI{1}));
  end
  
  [XX,YY] = meshgrid(1:Grid(1),1:Grid(2));
  [Xout,Yout,Zout] = arrayfun(@SumNeighbours,XX,YY);
  
  h = scatter3(X,Y,Z,'.'); hold on
  surface(Xout,Yout,Zout); hold off
  pause(0.1)
  sMarkers=h.MarkerHandle; %hidden marker handle
  % sMarkers.FaceColorData = uint8(255*[1;0;0;0.1]); %fourth element allows setting alpha
  sMarkers.EdgeColorData = uint8(255*[1;0;0;0.1]);
  set(gca,'XLim',[min(Xout(:)),max(Xout(:))])
  set(gca,'YLim',[min(Yout(:)),max(Yout(:))])
  set(gca,'ZLim',AVP.crop_range(Z))
end
