function [a,b,err_a,err_b,yfit,residuals] = linear_fit(y,x,varargin)
  %+
  % linear fit. See GoogleDoc "linear fit with weights". Errors are divided
  % by sum(w) because it makes them right :-)
  % ASSUMPTION: W = 1/ERR_Y
  %-
  
  %% PARSE OPTIONS
  % defaults
  AVP.opt_param('robust_iters',0);
  AVP.opt_param('do_plot',false);
  AVP.opt_param('robust_tol',1e-4);
  AVP.opt_param('b_is_0',false);
  
  n = numel(y);
  if ~exist('x','var') || isempty(x), x=[1:n].'; end
  AVP.opt_param('w',ones(size(x)));
  
  good = find(isfinite(y(:)) & isfinite(x));
  y = y(good); x = x(good); w=w(good);
  
  old_a = 0; old_b = 0; w_init = w; % for robust iterations
  for ri=1:robust_iters+1, % first iteration is not robust
    % calculate means
    sw = sum(w);sw2 = sum(w.^2);
    sx2 = sum(x.^2.*w)/sw;
    sxy = sum(y.*x.*w)/sw;
    
    if b_is_0
      a = sxy/sx2;
      b =  0;
    else
      sx = sum(x.*w)/sw;
      sy = sum(y.*w)/sw;
      D = sx2-sx.^2;
      
      % calculate solution
      a = (sxy -sx*sy)/D;
      b = (sy*sx2 - sxy*sx)/D;
    end
    
    yfit = a*x + b;
    residuals = y - yfit;
    res_sqr = residuals.^2/median(residuals.^2);
    
    % calculate robust w
    if all(w_init == 1)
      w = 1./sqrt(1+res_sqr);
    else
      w = 1./sqrt(1./w_init.^2+res_sqr.^2);
    end
    % if a == 0 || b == 0, break; end % otherwise there is no way to get relative tolarance
    if ((a-old_a)/(a+old_a)*2).^2 < robust_tol.^2 && ...
        ((b-old_b)/(b+old_b)*2).^2 < robust_tol.^2, break; end
    old_a = a; old_b = b;
  end
  
  if nargout > 2 || do_plot
    if b_is_0
      % taking into account DOF calculate sqrt(N-DOF)
      DOF = 1;
      sw_DOF = sqrt(sw.^2 - DOF*sw2);
      err_a = sqrt(sum((residuals.*x.*w).^2))/sx2/sw_DOF;
      err_b = 0;
    else
      DOF = 2; % we are returning 2 values
      sw_DOF_sqr = sw.^2 - DOF*sw2;
      if sw_DOF_sqr > 0
        sw_DOF = sqrt(sw_DOF_sqr);
        err_a = sqrt(sum((residuals.*(x-sx).*w).^2))/sw_DOF/D;
        err_b = sqrt(sum((residuals.*(sx2-sx*x).*w).^2))/sw_DOF/D;
      else
        a = NaN; b = NaN; err_a = NaN; err_b = NaN;
      end
    end
  end
  
  if do_plot
    % errorbar(x,y,1./w_init,'r.'); hold on
    plot(x,y,'.'); hold on
    plot(x,(a+err_a)*x+b+err_b,'g');
    plot(x,(a-err_a)*x+b-err_b,'g');
    plot(x,yfit,'b'); hold off
  end
end



