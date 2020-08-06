function is_prop_col = find_proportional_columns(x, tol)
  %> the function does not find linearly dependent columns, use
  %> CONTRIB.lin_indep_cols for that. It find only roughly proportional
  %> columns and returns indexes of all except of first ones
  
  if ~exist('tol','var'), tol = 1e-5; end
  r = x.'*(1./x);
  r2 = x.'.^2*(1./x).^2;
  norm_std = r2./(r.^2/size(x,1)) - 1;
  % AVP.PLOT.hist(log10(norm_std + min(norm_std(norm_std > 0))));
  % imagesc(log10(norm_std+10*eps)); colorbar % 1e-2 seems to be the division
  % plot(log10(norm_std(1,:)+10*eps)) % it looks like 1e-6 is a good boundary
  % Inds = find(norm_std(1,:) < 1e-6); % looks excellent
  % ColNamesCP(Inds) % looks excellent
  
  % collect all proportional columns
  % ignore bottom half, assign big value to it
  BotTri = ones(size(r,1));
  BotTri = tril(BotTri) == 1;
  norm_std(BotTri) = tol+1;
  MinColStd = min(norm_std,[],1);
  semilogy(MinColStd + min(MinColStd(MinColStd > 0)));
  is_prop_col = min(norm_std,[],1) < tol;
end
