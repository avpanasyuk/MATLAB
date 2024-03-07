function [x,y] = peak_3points(dY,dX)
  %> model is c(2)*dx^2+c(1)*dx = dy (central point is (0,0), so no "c(0)")
  %> c(2)*dX(1)^2  - c(1)*dX(1) = -dY(1)
  %> c(2)*dX(2)^2  + c(1)*dX(2) = dY(2)
  %> @param dY - vector of (2,:) [y2-y1, y3-y2]
  %> @param dX - vector of (2,:), [x2-x1, x3-x2], default [1,1]
  %> @retval x,y - peak coordinates relative to central point
  
  if ~exist('dX','var')
  	c = [[-1 1]; [1 1]]*[-dY(1); dY(2)]/2;
  else
  	c = pinv([[-dX(1) dX(1)^2]; [dX(2) dX(2)^2]])*[-dY(1); dY(2)];
  end
  x = -c(1)/2/c(2);
  y = x*c(1)/2;
end