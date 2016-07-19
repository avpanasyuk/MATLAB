function err_vs_complexity = optim_lasso_fun(X,y,complexity,k)
  l = AVP.LINREG.lasso_class(X,y);
  
  [err_vs_complexity, training] = l.K_fold_err(complexity,k,true);
  cellfun(@(x) x.FitInfo.DF,training)
end
