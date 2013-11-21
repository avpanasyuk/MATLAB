function [c,sigma] = nlinfit(Params,data,func,c_init,options)
%+
% FUNC is modelfun(c,Params). 
% PARAMS is [num points x num parameters]
%-
%% PARSE OPTIONS
do_plot = false;
if exist('options','var')
  if isfield(options,'do_plot'), do_plot = options.do_plot; end
end

[c,residual,J,COVB,mse] = nlinfit(Params,data,func,c_init,options);

if nargout > 1,
  sigma = nlparci(c,residual,'cover',COVB); % nlparci returns 95%
  % confidence interval, which corresponds to two sigmas
  sigma = (sigma(:,2)-sigma(:,1))./4; % confidence interal is 2 sigmas both 
  % left and rgiht
end

if do_plot,
  n = numel(data);
  errorbar(1:n,data,1./w_init,'ro'); hold on
  plot(1:n,func(c),'go'); hold off
end
  
% if we do not have statistical toolbox:
%[Q,R]=qr(jacobian,0);
%Rinv=inv(R);
%sigmaest=(Rinv*Rinv')*resnorm/(numel(residual) - numel(c));
%sigma=sqrt(diag(sigmaest));
end

