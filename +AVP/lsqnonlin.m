function [c,sigma,resnorm,residual,exitflag,output,lambda,jacobian] = ...
  lsqnonlin(func,c_init,options)
%+
% extension of LSQNONLIN which does robust fitting and returns
% uncertainties in parameters.
% FUNC should not be weighted, weights are separate
% ASSUME w = 1/err_y
% PARAMETERS
% OPTIONAL
% suppress_coeffs - trying to minimize the FUNC and C as well but extending
% vactro returned by FUNC with C vector dot-multiplied by SUPRESS_COEFFS
% vector
% PASS_OPTIONS - cell array to pass as varargin to LSQNONLIN 
%-
%% PARSE OPTIONS
robust_iters = 0; % maximum number of robust iterations, they stop if 
robust_tol = 1e-3; % robust_tol is reached first
pass_options = optimset(); % options for original LSQNONLIN
lb = []; ub = [];
weights = [];
n_coeffs = 0;
display = false;
suppress_coeffs = [];

if exist('options','var')
  if isfield(options,'pass_options'), pass_options = options.pass_options; end  
  if isfield(options,'lb'), lb = options.lb; end
  if isfield(options,'ub'), ub = options.ub; end
  if isfield(options,'robust_iters'), robust_iters = options.robust_iters; end
  if isfield(options,'robust_tol'), robust_tol = options.robust_tol; end
  if isfield(options,'weights'), weights = options.weights; end
  if isfield(options,'display'), display = options.display; end
  if isfield(options,'suppress_coeffs'), suppress_coeffs = options.suppress_coeffs; end
end 
pass_options.Display = 'off';

if ~exist('func_1','var')
  if isempty(weights),
    func_0 = @(c) func(c);
  else
    func_0 = @(c) func(c).*weights;
  end
  n_coeffs = 0;
  if ~isempty(suppress_coeffs), 
    func_1 = @(c) [func_0(c),c.*options.suppress_coeffs];
    n_coeffs = numel(c_init);
  else func_1 = func_0;
end
  
c = c_init; w_init = weights; % for robust iterations

for ri=1:robust_iters+1, % first iteration is not robust
  [c,resnorm,residual,exitflag,output,lambda,jacobian] = ...
    lsqnonlin(func_1,c,lb,ub,pass_options);
  residual = func(c); % returned residuals are not correct because they are weighted
  if any(c == 0), break; end % can not calculate relative tolerance
  if max((1-c_init./c).^2) < robust_tol.^2; break; end
  if isempty(w_init),
    weights = 1./max(abs(residual),mean(abs(residual))/100);
  else
    weights = 1./sqrt((1./w_init.^2 + residual.^2)/2);
  end
  if ~isempty(suppress_coeffs), 
    func_1 = @(c) [func(c).*weights,c.*options.suppress_coeffs];
  else func_1 = @(c) func(c).*weights; end
  c_init = c;
end

if nargout > 1,
  sigma = nlparci(c,residual,'jacobian',jacobian(1:end-n_coeffs,:)); 
  % nlparci returns 95%
  % confidence interval, which corresponds to two sigmas
  sigma = ((sigma(:,2)-sigma(:,1))./4).'; % confidence interal is 2 sigmas both 
  % left and rgiht
end

if display, 
  if isempty(weights),
    disp({'lsqnonlin: mean error ',sqrt(mean(residual(1:end-n_coeffs).^2))})
  else
    disp({'lsqnonlin: weighted mean error ',...
    sqrt(sum((residual(1:end-n_coeffs).*weights(1:end-n_coeffs)).^2)/...
    sum(weights(1:end-n_coeffs).^2))})
  end
end

  
% if we do not have statistical toolbox:
%[Q,R]=qr(jacobian,0);
%Rinv=inv(R);
%sigmaest=(Rinv*Rinv')*resnorm/(numel(residual) - numel(c));
%sigma=sqrt(diag(sigmaest));
end

