% OK, I need a principal component regression which I understand.
% Principal components seems to be simple. You just have a bunch of
% orthogonal vectors, then you correlate them with dependent variable, find
% the one with best correlation, subtract it, wash and repeat. Do they have
% to be orthogonal? Why not. So, we can not SVD first to get orthogonal ones,
% and tehn do this procedure.

% the difference between this function and SVD is that we order vectors by
% biggest correlation with the Y, and not by SV
% X and LC 
function [U, Sinv, V] = pc_regression(X,y,options)
  SV_range = 3; % the lowest considered Sval is Sval(1)/10^SV_range
  SVvsCorr = 1; % when we choose PC how important is SV vs correlation with Coeff.
% when  SVvsCorr == 0 it should be analog of SVD. 

  if exist('options','var'),
    if isfield(options,'SV_range'), SV_range = options.SV_range; end
    if isfield(options,'SVvsCorr'), SVvsCorr = options.SVvsCorr; end
  else options = []; end

  [U,S,V] = svd(X,0); % X = U*S*V'.
  % we can not really use all S values, some of then are way too small and
  % screw things up
  S = diag(S);
  LastSVi = find(S > S(1)/10.^SV_range,1,'last');
  
  V = V(:,1:LastSVi);
  Sinv = 1./S(1:LastSVi);
  U = U(:,1:LastSVi);

  % calculate all correlations
  Corrs = U.'*y; % no need to normalize, U - orthonormal
  [~,SortI] = sort(abs(Corrs.^SVvsCorr./Sinv.^(1-SVvsCorr)),'descend');
  % Ok, now we just have to reorder matrices in order of best vector correlation
  % and we are done
  V = V(:,SortI);
  Sinv = Sinv(SortI);
  U = U(:,SortI);
end

function pc_regression_log
[tp tp_names] = UC.TEST24HOURS.build_tp_matrix(s,PatParams);
[tpn,mu,sigma] = zscore(tp); % Z = (x-mean(x))/std(x)
[U,S,V] = svd(tpn,0); % X = U*S*V'.
% OK, we got a set of orthogonal vectors in U
plot(log(diag(S)))
% we can not really use all S values, some of then are way too small and
% screw things up
[~,max_svn] = max(find(abs(S) > exp(-10)));
V = V(:,1:max_svn);
Sinv = diag(S);
Sinv = 1./Sinv(1:max_svn);
U = U(:,1:max_svn);

% now let's try to see which one is the most relevant
lc = log(s.Coeff{1});
%%% !!!!! EXTREMELY IMPORTANT TO DO ZSCORE AND NOT ONLY RANDOM MEAN - FOR
%%% SOME REASON IT WORKS UNCOMPARABLY BETTER! !!! No reason to shout - it was
%%% before I've removed oversmall SV
[lcz,lc_mu,lc_s] = zscore(lc);
lc_mu = mean(lc); lcz = lc - lc_mu; lc_s = 1; % just removing mean
%%lcz = lc; lc_mu = 0; lc_s = 1;
% calculate all correlations
Corrs = U.'*lcz;
plot(Corrs) % the order is a bit similar to SV order, but not quite
[CorrS SortI] = sort(abs(Corrs),'descend');
plot(CorrS,'x')
% OK, there is a dependency on components
% What is the best fit
Coeffs = V*diag(Sinv)*U.'*lcz;
lcz_fit = tpn*Coeffs;
plot([lcz,lcz_fit])
% convert back to unnormalized LC amplitude
Coeffs = Coeffs*lc_s;
lc0_fit = tpn*Coeffs;
plot([lc,lc0_fit+lc_mu])
std(lc-lc0_fit)

% Ok, now we just have to reorder matrices in order of best vector correlation
% and we are done
V = V(:,SortI);
Sinv = Sinv(SortI);
U = U(:,SortI);
Coeffs = V*diag(Sinv)*U.'*lcz;
Coeffs = Coeffs*lc_s;
lc0_fit = tpn*Coeffs;
plot([lc,lc0_fit+lc_mu])
std(lc-lc0_fit)

% OK, we've got 27% at best, so 29 we are getting are pretty close
end


