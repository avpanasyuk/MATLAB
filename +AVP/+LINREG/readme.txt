Ok, that's how kfold_class works. This is universal class which uses the same approach for different regression engines.

1. I am getting a matrix of independent parameters Xmat (rows are samples) and a vector of dependent Y
and divider indexes KfoldDivs for kfold. Xmat already contains all cross products if necessary, but neither
Xmat or Y are zscored.

We are going to find the optimum subset of parameters. So we are going to run a loop here

Set vector SelectedParamI which specifies subset of independent parameter we still conider to all parameters

WHILE BEST PARAMETER SUBSET NOT FOUND
    % there is parameter Complexity which "regulates" regression so it does not overfit. It may have different 
    % implementation, like the number of singular values of lambda parameter in ridge regression. For each
    % subset of parameters I find the value of Complexity which minimizes Kfold error. After this using I reduce parameters subset 
    % (again, how it is done may be different for different regression engines) abd repeat the loop.
    
    best_complexity = FIND_MINIMUM(CALCULATE_KFOLD_ERROR(COMPLEXITY, SelectedParamI);
    % .......

END WHILE

^ hmm, the whole loop above seems to be specific to regression engine.




