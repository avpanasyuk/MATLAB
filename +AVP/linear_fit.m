function [a,b,err_a,err_b,yfit,residuals] = linear_fit(y,x,w,options)
%+
% linear fit. See GoogleDoc "linear fit with weights". Errors are divided 
% by sum(w) because it makes them right :-)
% ASSUMPTION: W = 1/ERR_Y
%-

%% PARSE OPTIONS
% defaults
robust_iters = 0; % maximum number of robust iterations, they stop if 
robust_tol = 1e-3; % robust_tol is reached first
do_plot = false; 
if exist('options','var')
  if isfield(options,'robust_iters'), robust_iters = options.robust_iters; end
  if isfield(options,'do_plot'), do_plot = options.do_plot; end
  if isfield(options,'robust_tol'), robust_tol = options.robust_tol; end
end

n = numel(y);
if ~exist('x','var') || isempty(x), x=[1:n]; end
if ~exist('w','var') || isempty(w), w=ones(size(x)); end
good = find(isfinite(y) & isfinite(x));
y = y(good); x = x(good); w=w(good);

old_a = 0; old_b = 0; w_init = w; % for robust iterations
for ri=1:robust_iters+1, % first iteration is not robust
  % calculate means
  sw = sum(w);sw2 = sum(w.^2);
  sx = sum(x.*w)/sw; sy = sum(y.*w)/sw; sx2 = sum(x.^2.*w)/sw;
  sxy = sum(y.*x.*w)/sw;
  D = sx2-sx.^2;

  % calculate solution
  a = (sxy -sx*sy)/D;
  b = (sy*sx2 - sxy*sx)/D;
  yfit = a*x + b;
  residuals = y - yfit;
  
  % calculate robust w
  w = 1./sqrt(((1./w_init).^2+residuals.^2)/2); % in case we have no residuals
  if a == 0 || b == 0, break; end % otherwise there is no way to get relative tolarance
  if (1-old_a/a).^2 < robust_tol.^2 && ...
      (1-old_b/b).^2 < robust_tol.^2, break; end
  old_a = a; old_b = b;
end
  
if nargout > 2,
  % taking into account DOF calculate sqrt(N-DOF)
  DOF = 2; % we are returning 2 values 
  sw_DOF_sqr = sw.^2 - DOF*sw2;
  if sw_DOF_sqr > 0,
    sw_DOF = sqrt(sw_DOF_sqr);
    err_a = sqrt(sum((residuals.*(x-sx).*w).^2))/sw_DOF/D;
    err_b = sqrt(sum((residuals.*(sx2-sx*x).*w).^2))/sw_DOF/D;
  else
    a = NaN; b = NaN; err_a = NaN; err_b = NaN;
  end
end

if do_plot,
  errorbar(x,y,1./w_init,'ro'); hold on
  plot(x,yfit,'g-'); hold off
end
end

  

