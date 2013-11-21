function [c,varargout] = lsqcurvefit(func,data,c_init,options)
%+
% extension of LSQNONLIN which does robust fitting and returns
% uncertainties in parameters.
% FUNC should not be weighted, weights are separate
% ASSUME w = 1/err_y
%-
%% PARSE OPTIONS
do_plot = false;
weights = [];
if exist('options','var') && ~isempty(options)
  if isfield(options,'do_plot'), do_plot = options.do_plot; end
  if isfield(options,'weights'), weights = options.weights; end  
else options = []; end

[c,varargout{1:nargout}] = AVP.lsqnonlin(@(c) func(c)-data,c_init,options);

if do_plot,
  n = numel(data);
  if ~isempty(weights),
    errorbar(1:n,data,1./weights,'ro'); 
  else
    plot(1:n,data,'ro');
  end
  hold on; plot(1:n,func(c),'g'); hold off
end
  
% if we do not have statistical toolbox:
%[Q,R]=qr(jacobian,0);
%Rinv=inv(R);
%sigmaest=(Rinv*Rinv')*resnorm/(numel(residual) - numel(c));
%sigma=sqrt(diag(sigmaest));
end

