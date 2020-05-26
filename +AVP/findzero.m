function [X,Y] = findzero(fun, range, varargin)
  %> find approximation of x where fun crosses 0
  %> @param fun - function y(x)
  %> @param range - ends should have different signs of y, sorted
  %> @param varargin
  %>    - tolX - tolerance of x, iterations stop when X step < tolX
  %>    - tolY - tolerance of Y, iterations stop when abs(Y) < tolY
  %>    - no_error - when true if ends have the same sign
  %>            returns best one instead of generating error
  %>    - under - when true returns solution at which y < 0
  %>    - MaxIter - maximum number of iterations, default = 40
  %>    - fzero_opts - structure created by optimset for fzero's 
   
  AVP.opt_param('tolX',0);
  AVP.opt_param('tolY',0);
  AVP.opt_param('no_error',false);
  AVP.opt_param('under',false);
  AVP.opt_param('fzero_opts',[]);
  ItersLeft = AVP.opt_param('MaxIter',40);
   
  x = range;
  y = arrayfun(fun, x);
  if abs(y(1)) < tolY, Y = y(1); X = x(1); return; end
  if abs(y(2)) < tolY, Y = y(2); X = x(2); return; end
  OldX = x(1);
       
  if sign(y(1)) ~= sign(y(2))
    while ItersLeft
      % Ok, we do  linear interpolation between 
      % edge points and bisecting in turns. We can do not use linear
      % interpolation alone because depending on function shape it may
      % converge very fast, or very slow. And X steps may be very small but still far away from the solution.
      % BISECTION converges with the same
      % speed, so when we have both we get kinda optinal situation
      if mod(ItersLeft,2) == 0
        X = x(1) - (x(2) - x(1))/(y(2)-y(1))*y(1);
      else 
        X = (x(1) + x(2))/2;
      end
      Y = fun(X);
      
      if abs(Y) < tolY && (~under || Y < 0), return; end
      
      if sign(Y) == sign(y(1))
        x = [X; x(2)];
        y = [Y; y(2)];
      else
        x = [x(1); X];
        y = [y(1); Y];
      end
      if abs(X - OldX) < tolX, break, end
      if mod(ItersLeft,2) == 0, OldX = X; end % OldX tracks only linear interpolation
      
      ItersLeft = ItersLeft - 1;
    end
  else
    if AVP.is_true('no_error')
      if under && y(1) > 0,
        error('findzero:positive','both ends are positive')
      end
      if abs(y(1)) < abs(y(2)), X = x(1); Y = y(1);
      else X = x(2); Y = y(2); end
      return
    else
      error('findzero:nocross','Values at the ends of RANGE should cross zero!')
    end
  end
     
  if under
    [Y, Ind] = min(y);
  else
    [~, Ind] = min(abs(y)); Y = y(Ind);
  end
  X = x(Ind);
end


