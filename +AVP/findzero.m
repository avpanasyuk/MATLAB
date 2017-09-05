function [X,Y] = findzero(fun, range, tol, under, no_error)
  %> find approximation of x where fun crosses 0
  %> @param fun - function y(x)
  %> @param range - ends should have different signs of y, sorted
  %> @param tol - tol of x hwen iterations stop
  %> @param no_error - optional, when defined if ends have the same sign
  %>        returns best one instead of generating error
  %> @param under - optional, when defined returns solution at which y < 0
  if ~exist('under','var') || isempty(under), under = false; end
  
  x = range;
  y = arrayfun(fun, x);
  if y(1) == 0, Y = y(1); X = x(1); return; end
  if y(2) == 0, Y = y(2); X = x(2); return; end
      
  if sign(y(1)) ~= sign(y(2))
    while 1,
      X = x(1) - (x(2) - x(1))/(y(2)-y(1))*y(1);
      Y = fun(X);
      if Y == 0, return; end
      
      if sign(Y) == sign(y(1))
        x = [X; x(2)];
        y = [Y; y(2)];
      else
        x = [x(1); X];
        y = [y(1); Y];
      end
      if (x(2) - x(1)) < tol, break, end
    end
  else
    if exist('no_error','var') && ~isempty(no_error) && no_error
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



