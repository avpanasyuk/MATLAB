function [coeffs, errs, params] = straight_ellipse(x,y,varargin)
  %> fits function ((x-x0)/lx).^2 + ((y-y0)/ly).^2 = 1, which is an ellipse
  %> without a turn
  %> @retval coeffs = [a,b,c,d]
  %> @retval params = [x0,y0,sqr(lx),sqr(ly)]
  %> @param varargin
  %>        - weights: vector of weights
  %>        - robust: logical

  % really start by fitting a*x.^2 + b*x + c*y.^2 + d*y = 1
  % so we minimize sum of errors sum((1-a*...).^2) by a,b,c,d
  % we get linear system
  % a*Sx.^4 + b*Sx.^3 + c*Sy.^2.*x.^2 + d*Sy*x.^2 = Sx.^2
  % ...
  x = x(:); y = y(:);
  x2 = x.^2; y2 = y.^2;
  if AVP.opt_param_present('weights')
    w = AVP.opt_param('weights');
    M = [[sum(x2.*x2.*w), sum(x.*x2.*w), sum(y2.*x2.*w), sum(y.*x2.*w)];...
      [sum(x2.*x.*w), sum(x2.*w), sum(y2.*x.*w), sum(y.*x.*w)];...
      [sum(x2.*y2.*w), sum(x.*y2.*w), sum(y2.*y2.*w), sum(y.*y2.*w)];...
      [sum(x2.*y.*w), sum(x.*y.*w), sum(y2.*y.*w), sum(y2.*w)]];
    r = [sum(x2.*w); sum(x.*w); sum(y2.*w); sum(y.*w)];
  else
    M = [[sum(x2.*x2), sum(x.*x2), sum(y2.*x2), sum(y.*x2)];...
      [sum(x2.*x), sum(x2), sum(y2.*x), sum(y.*x)];...
      [sum(x2.*y2), sum(x.*y2), sum(y2.*y2), sum(y.*y2)];...
      [sum(x2.*y), sum(x.*y), sum(y2.*y), sum(y2)]];
    r = [sum(x2); sum(x); sum(y2); sum(y)];
  end
  coeffs = pinv(M) * r;
  if nargout > 1 || AVP.opt_param_is_set('robust')
    errs = [x2,x,y2,y]*coeffs - 1;
  end
  if AVP.opt_param_is_set('robust')
    for IterI=1:8
      w = errs.^2 + realmin("single");
      w = 2./(w/median(w)+1);
      [coeffs, errs] = AVP.FIT.straight_ellipse(x,y,'weights',w);
    end
  end
  if nargout > 2 || AVP.opt_param_is_set('do_plot')
    % x0 = -b/(2*a), y0 = -d/(2*c), Lx2 = (a*d^2 + b^2*c + 4*a*c)/(4*a^2*c), Ly2 = (a*d^2 + b^2*c + 4*a*c)/(4*c^2*a)
    t  = (coeffs(4)^2/coeffs(3) + coeffs(2)^2/coeffs(1) + 4)/4;
    params = [-coeffs(2)/(2*coeffs(1)); -coeffs(4)/(2*coeffs(3)); t/coeffs(1); t/coeffs(3)];
  end
  if AVP.opt_param_is_set('do_plot')
    % a = atan2(y,x);
    a = [0:100]/100*2*pi;
    plot(x,y,'+',cos(a)*sqrt(params(3))+params(1),sin(a)*sqrt(params(4))+params(2),'-');
  end
end
