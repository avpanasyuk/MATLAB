function [model, time] = aresbuild(Xtr, Ytr, trainParams, weights, keepX, modelOld, verbose)
% aresbuild
% Builds a regression model using the Multivariate Adaptive Regression
% Splines technique.
%
% Call:
%   [model, time] = ...
%             aresbuild(Xtr, Ytr, trainParams, weights, modelOld, verbose)
%
% All the arguments, except the first two, of this function are optional.
% Empty values are also accepted (the corresponding default values will be
% used).
%
% Input:
%   Xtr, Ytr      : Training data cases (Xtr(i,:), Ytr(i)), i = 1,...,n.
%                   Note that it is recommended to pre-scale Xtr values to
%                   [0,1] and to standardize Ytr values.
%   trainParams   : A structure of training parameters for the algorithm.
%                   If not provided, default values will be used (see
%                   function aresparams for details).
%   weights       : A vector of data case weights; if supplied, the
%                   algorithm calculates the sum of squared errors
%                   multiplying the squared residuals by the supplied
%                   weights. The length of weights vector must be the same
%                   as the number of data cases. The weights must be
%                   nonnegative.
%   keepX         : Set this to true to retain model.X matrix (see
%                   description of model.X). (default value = false)
%   modelOld      : If here an already built ARES model is provided, no
%                   forward phase will be done. Instead this model will be
%                   taken directly to the backward phase and pruned. This
%                   is useful for fast selection of the "best" penalty
%                   trainParams.c value using Cross-Validation in arescvc
%                   function or for fast tuning of other parameters of
%                   backward phase (cubic, maxFinalFuncs).
%   verbose       : Set to false for no verbose. (default value = true)
%
% Output:
%   model         : The built ARES model – a structure with the following
%                   elements:
%     coefs       : Coefficient vector of the regression model (for the
%                   intercept term and each basis function).
%     knotdims	  : Cell array of indexes of used input variables for each
%                   knot in each basis function.
%     knotsites	  : Cell array of knot sites for each knot and used input
%                   variable in each basis function.
%     knotdirs	  : Cell array of directions (-1 or 1) of the hinge
%                   functions for each used input variable in each basis
%                   function.
%     parents     : Vector of indexes of direct parents for each basis
%                   function (0 if there is no direct parent or it is the
%                   intercept term).
%     trainParams : A structure of training parameters for the algorithm.
%     MSE         : Mean Squared Error of the model in the training data.
%     GCV         : Generalized Cross-Validation (GCV) of the model in the
%                   training data set. The value may also be Inf if model’s
%                   effective number of parameters is larger than or equal
%                   to n.
%     t1          : For piecewise-cubic models only. Matrix of knot sites
%                   for the additional knots on the left of the central
%                   knot.
%     t2          : For piecewise-cubic models only. Matrix of knot sites
%                   for the additional knots on the right of the central
%                   knot.
%     minX        : Vector of minimums for input variables (used for t1 and
%                   t2 placements as well as for model plotting).
%     maxX        : Vector of maximums for input variables (used for t1 and
%                   t2 placements as well as for model plotting).
%     endSpan     : The used value of endSpan.
%     X           : Matrix of values of basis functions applied to Xtr.
%                   Each column corresponds to a selected basis function.
%                   Each row corresponds to a row in Xtr. Multiplying X by
%                   coefs gives ARES prediction for Ytr. This variable is
%                   available only if parameter keepX is true.
%   time          : Algorithm execution time (in seconds)

% =========================================================================
% ARESLab: Adaptive Regression Splines toolbox for Matlab/Octave
% Author: Gints Jekabsons (gints.jekabsons@rtu.lv)
% URL: http://www.cs.rtu.lv/jekabsons/
%
% Copyright (C) 2009-2015  Gints Jekabsons
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <http://www.gnu.org/licenses/>.
% =========================================================================

% Please give a reference to the webpage in any publication describing
% research performed using the software e.g., like this:
% Jekabsons G. ARESLab: Adaptive Regression Splines toolbox for Matlab/
% Octave, 2015, available at http://www.cs.rtu.lv/jekabsons/

% Last update: June 8, 2015

if nargin < 2
    error('Too few input arguments.');
end

if (isempty(Xtr)) || (isempty(Ytr))
    error('Training data is empty.');
end
if (~isfloat(Xtr)) || (~isfloat(Ytr))
    error('Data type should be floating-point.');
end
[n, d] = size(Xtr); % number of data cases and number of input variables
if size(Ytr,1) ~= n
    error('The number of rows in Xtr and Ytr should be equal.');
end
if size(Ytr,2) ~= 1
    error('Ytr should have one column.');
end

if (nargin < 3) || (isempty(trainParams))
    trainParams = aresparams();
end
if trainParams.maxInteractions >= 2
    trainParams_actual_c = trainParams.c;
else
    trainParams_actual_c = 2*trainParams.c/3; % penalty coefficient for additive modelling
end
if (trainParams.cubic) && (trainParams.selfInteractions > 1)
    trainParams.selfInteractions = 1;
    disp('Warning: trainParams.selfInteractions value reverted to 1 due to piecewise-cubic setting.');
end
if trainParams.cubic
    doCubicFastLevel = trainParams.cubicFastLevel;
    if trainParams.cubicFastLevel > 0
        trainParams.cubic = false; % let's turn it off until the backward phase or the final model
    end
else
    doCubicFastLevel = -1; % no piecewise-cubic modelling
end
if (trainParams.endSpanAdjust < 1)
    trainParams.endSpanAdjust = 1;
    disp('Warning: trainParams.endSpanAdjust value too small. Reverted to 1.');
end

if (trainParams.fastK < 3)
    trainParams.fastK = 3;
    disp('Warning: trainParams.fastK value too small. Reverted to 3.');
end
if (trainParams.fastBeta < 0)
    trainParams.fastBeta = 0;
    disp('Warning: trainParams.fastBeta value too small. Reverted to 0.');
end
if (trainParams.fastH < 1)
    trainParams.fastH = 1;
    disp('Warning: trainParams.fastH value too small. Reverted to 1.');
end

if trainParams.useMinSpan == 0
    trainParams.useMinSpan = 1; % 1 and 0 is the same here (no minspan)
end

if (nargin < 4)
    weights = [];
else
    if (~isempty(weights)) && ...
       ((size(weights,1) ~= n) || (size(weights,2) ~= 1))
        error('weights vector is of wrong size.');
    end
end
wd = diag(weights);
if (nargin < 5) || isempty(keepX)
    keepX = false;
end
if nargin < 6
    modelOld = [];
end
if (nargin < 7) || isempty(verbose)
    verbose = true;
end

if trainParams.maxFuncs >= 0
    maxIters = floor((trainParams.maxFuncs - 1) / 2); % because basis functions are added two at a time
else
    mf = min(200, max(20, 2 * d)) + 1; % default number of basis functions
    maxIters = floor(mf / 2); % because basis functions are added two at a time
    if verbose, fprintf('Setting maxFuncs to %d\n', mf); end
end

if verbose, fprintf('Building ARES model...\n'); end
ws = warning('off');
tic;

YtrMean = mean(Ytr);
YtrVar = sum((Ytr - YtrMean) .^ 2); % Ytr variance
minX = min(Xtr);
maxX = max(Xtr);

if trainParams.useEndSpan < 0
    endSpan = getEndSpan(d); % automatic
else
    endSpan = trainParams.useEndSpan;
end

if isempty(modelOld)
    X = ones(n,1);
    err = 1; % normalized error for the constant model
    model.coefs = YtrMean;
    model.knotdims = {};
    model.knotsites = {};
    model.knotdirs = {};
    model.parents = [];
    model.trainParams = [];
    model.MSE = Inf;
    model.GCV = Inf;
else
    model = modelOld; % modelOld is the initial model
end

if endSpan*2 >= n
    disp('Warning: endSpan*2 >= n');
    if isempty(modelOld)
        model.MSE = YtrVar / n;
        model.GCV = gcv(model, model.MSE, n, trainParams_actual_c);
        if trainParams.cubic
            model.t1 = [];
            model.t2 = [];
        end
    end
else

    % FORWARD PHASE

    if isempty(modelOld) % no forward phase when modelOld is used

        if verbose, fprintf('Forward phase  .'); end

        % create sorted lists of data cases for knot placements
        [sortedXtr, sortedXtrInd] = sort(Xtr);
        if trainParams.useEndSpan ~= 0
            % throw away data cases at the ends of the intervals
            sortedXtr = sortedXtr(1+endSpan:end-endSpan,:);
            sortedXtrInd = sortedXtrInd(1+endSpan:end-endSpan,:);
        end

        if trainParams.cubic
            tmp_t1 = [];
            tmp_t2 = [];
        end
        basisFunctionList = {}; % will contain candidate basis functions
        numNewFuncs = 0; % how many basis functions added in the last iteration
        if (trainParams.newVarPenalty > 0)
            dimsInModel = []; % lists all input variables the model uses
        end

        if (trainParams.fastK < Inf)
            % we could preallocate space here but benchmarking shows that
            % there is not much to be gained from this
            fastParent = {};
            fastMinErrAdj = [];
            fastIterComputedErr = [];
            fastNumBasis = 0;
        end

        % the main loop of the forward phase
        for currIter = 1 : maxIters
            % create list of all possible daughter basis functions
            [basisFunctionList, idxStart1, idxEnd1, idxStart2, idxEnd2] = ...
                    createList(basisFunctionList, Xtr, sortedXtr, sortedXtrInd, ...
                               n, d, model, numNewFuncs, trainParams, endSpan);

            % stop the forward phase if basisFunctionList is empty
            if isempty(basisFunctionList)
                if trainParams.cubic
                    t1 = tmp_t1;
                    t2 = tmp_t2;
                end
                if verbose, fprintf('\nAdditional termination condition is met: no more basis functions to add.'); end
                break;
            end

            % preallocate space
            % (we could allocate less but this is simpler)
            tmpErr = inf(1,size(basisFunctionList,2));
            tmpCoefs = inf(length(model.coefs)+2, size(basisFunctionList,2));
            if trainParams.cubic
                Xtmp = zeros(n,size(X,2)+2);
            else
                Xtmp = [X zeros(n,2)];
            end

            if (trainParams.fastK < Inf)

                % initialize info about the two new parent basis functions
                if ~isempty(basisFunctionList)
                    if (idxStart1 > 0)
                        fastNumBasis = fastNumBasis + 1;
                        fastParent{fastNumBasis}.idxStart = idxStart1;
                        fastParent{fastNumBasis}.idxEnd = idxEnd1;
                        fastMinErrAdj(fastNumBasis) = -Inf;
                        fastIterComputedErr(fastNumBasis) = currIter;
                        fastParent{fastNumBasis}.iterComputedAllDims = -Inf;
                    end
                    if (idxStart2 > 0)
                        fastNumBasis = fastNumBasis + 1;
                        fastParent{fastNumBasis}.idxStart = idxStart2;
                        fastParent{fastNumBasis}.idxEnd = idxEnd2;
                        fastMinErrAdj(fastNumBasis) = -Inf;
                        fastIterComputedErr(fastNumBasis) = currIter;
                        fastParent{fastNumBasis}.iterComputedAllDims = -Inf;
                    end
                end

                % make a selection of parent basis functions to try
                lenR = length(fastParent);
                if lenR > trainParams.fastK
                    % ranking and prioritizing
                    [dummy, idxR] = sort(fastMinErrAdj, 2, 'descend'); % sort by err
                    idxR(idxR) = 1:lenR; % get ranks in the original order
                    idxInf = fastMinErrAdj == -Inf; % special case
                    idxR(idxInf) = idxR(idxInf) + 1E6; % so that -Inf is never outprioritized
                    priority = idxR + trainParams.fastBeta * (repmat(currIter, 1, lenR) - fastIterComputedErr); % calculate priorities
                    [dummy, idxP] = sort(priority, 2); % sort (with equal priorities, most recent will be first)
                    indToCalc = idxP(end:-1:end-trainParams.fastK+1); % indexes of parents to try
                else
                    indToCalc = 1 : lenR;
                end
                fastIterComputedErr(indToCalc) = currIter;

                bestParent = -1;
                bestErrAdj = Inf;
                % try the selected parent basis functions
                for ir = indToCalc
                    % let's see if only a preselected dimension should be checked
                    checkPreselectedDimOnly = currIter - fastParent{ir}.iterComputedAllDims < trainParams.fastH;
                    if (~checkPreselectedDimOnly)
                        fastParent{ir}.iterComputedAllDims = currIter;
                    end
                    idxStart = fastParent{ir}.idxStart;
                    idxEnd = fastParent{ir}.idxEnd;
                    % try all the reflected pairs (daughter basis functions) in the list
                    for i = idxStart : idxEnd
                        if  checkPreselectedDimOnly && (basisFunctionList{1,i}(end) ~= fastParent{ir}.bestDim)
                            %tmpErr(i) = Inf; % unnecessary because the array is already initialized with Inf
                            continue;
                        end
                        if trainParams.cubic
                            [t1, t2, dif] = findsideknots(model, basisFunctionList{1,i}, basisFunctionList{2,i}, ...
                                            d, minX, maxX, tmp_t1, tmp_t2);
                            Xtmp(:,1:end-2) = X;
                            % update basis functions with the updated side knots
                            for j = 1 : length(model.knotdims)
                                if dif(j)
                                    Xtmp(:,j+1) = createbasisfunction(Xtr, Xtmp, model.knotdims{j}, model.knotsites{j}, ...
                                                  model.knotdirs{j}, model.parents(j), minX, maxX, t1(j,:), t2(j,:));
                                end
                            end
                            % New basis function
                            dirs = basisFunctionList{3,i};
                            Xtmp(:,end-1) = createbasisfunction(Xtr, Xtmp, basisFunctionList{1,i}, basisFunctionList{2,i}, ...
                                            dirs, basisFunctionList{4,i}, minX, maxX, t1(end,:), t2(end,:));
                            ok1 = ~isnan(Xtmp(1,end-1));
                            % Reflected partner
                            dirs(end) = -dirs(end);
                            Xtmp(:,end) = createbasisfunction(Xtr, Xtmp, basisFunctionList{1,i}, basisFunctionList{2,i}, ...
                                          dirs, basisFunctionList{4,i}, minX, maxX, t1(end,:), t2(end,:));
                            ok2 = ~isnan(Xtmp(1,end));
                        else
                            % New basis function
                            dirs = basisFunctionList{3,i};
                            Xtmp(:,end-1) = createbasisfunction(Xtr, Xtmp, basisFunctionList{1,i}, ...
                                            basisFunctionList{2,i}, dirs, basisFunctionList{4,i}, minX, maxX);
                            ok1 = ~isnan(Xtmp(1,end-1));
                            % Reflected partner
                            dirs(end) = -dirs(end);
                            Xtmp(:,end) = createbasisfunction(Xtr, Xtmp, basisFunctionList{1,i}, ...
                                          basisFunctionList{2,i}, dirs, basisFunctionList{4,i}, minX, maxX);
                            ok2 = ~isnan(Xtmp(1,end));
                        end
                        if ok1 && ok2 % both basis functions created
                            [tmpCoefs(:,i), tmpErr(i)] = lreg(Xtmp, Ytr, weights, wd);
                        elseif ok1 || ok2 % one of the basis functions not created
                            if (ok1)
                                [coefs, tmpErr(i)] = lreg(Xtmp(:, 1:end-1), Ytr, weights, wd);
                            else
                                [coefs, tmpErr(i)] = lreg([Xtmp(:, 1:end-2) Xtmp(:, end)], Ytr, weights, wd);
                            end
                            tmpCoefs(:,i) = [coefs; NaN];
                        %else % no basis function created
                        %    tmpErr(i) = Inf; % unnecessary because the array is already initialized as Inf
                        end
                    end

                    % find the best pair of daughter basis functions from this parent
                    if ((trainParams.newVarPenalty > 0) && (currIter > 1))
                        adjust = ones(1, idxEnd - idxStart + 1);
                        for i = idxStart : idxEnd
                            if (~isempty(setdiff(basisFunctionList{1,i}, dimsInModel)))
                                adjust(i - idxStart + 1) = 1 + trainParams.newVarPenalty;
                            end
                        end
                        % the adjusted values are used for selection only,
                        % they are not used in any further calculations
                        [newErrAdj, ind] = min(tmpErr(idxStart:idxEnd) .* adjust);
                        ind = ind + idxStart - 1;
                        newErr = tmpErr(ind);
                    else
                        [newErr, ind] = min(tmpErr(idxStart:idxEnd));
                        newErrAdj = newErr;
                        ind = ind + idxStart - 1;
                    end
                    fastParent{ir}.bestDim = basisFunctionList{1,ind}(end);
                    fastParent{ir}.bestIdxInList = ind;
                    fastParent{ir}.bestErr = newErr;
                    fastMinErrAdj(ir) = newErrAdj;
                    % continue the search for best daughters from all parents
                    if bestErrAdj > newErrAdj
                        bestErrAdj = newErrAdj;
                        bestParent = ir;
                    end
                end
                % we have found the best pair of daughter basis functions
                ind = fastParent{bestParent}.bestIdxInList;
                newErr = fastParent{bestParent}.bestErr / YtrVar;
                % reset the parent so that full optimization is done in next iteration
                fastMinErrAdj(bestParent) = -Inf;
                %fastParent{bestParent}.bestDim = -1;
                fastParent{bestParent}.iterComputedAllDims = -Inf;

            else % else of "if (trainParams.fastK < Inf)"

                % try all the reflected pairs in the list
                for i = 1 : size(basisFunctionList,2)
                    if trainParams.cubic
                        [t1, t2, dif] = findsideknots(model, basisFunctionList{1,i}, basisFunctionList{2,i}, ...
                                        d, minX, maxX, tmp_t1, tmp_t2);
                        Xtmp(:,1:end-2) = X;
                        % update basis functions with the updated side knots
                        for j = 1 : length(model.knotdims)
                            if dif(j)
                                Xtmp(:,j+1) = createbasisfunction(Xtr, Xtmp, model.knotdims{j}, model.knotsites{j}, ...
                                              model.knotdirs{j}, model.parents(j), minX, maxX, t1(j,:), t2(j,:));
                            end
                        end
                        % New basis function
                        dirs = basisFunctionList{3,i};
                        Xtmp(:,end-1) = createbasisfunction(Xtr, Xtmp, basisFunctionList{1,i}, basisFunctionList{2,i}, ...
                                        dirs, basisFunctionList{4,i}, minX, maxX, t1(end,:), t2(end,:));
                        ok1 = ~isnan(Xtmp(1,end-1));
                        % Reflected partner
                        dirs(end) = -dirs(end);
                        Xtmp(:,end) = createbasisfunction(Xtr, Xtmp, basisFunctionList{1,i}, basisFunctionList{2,i}, ...
                                      dirs, basisFunctionList{4,i}, minX, maxX, t1(end,:), t2(end,:));
                        ok2 = ~isnan(Xtmp(1,end));
                    else
                        % New basis function
                        dirs = basisFunctionList{3,i};
                        Xtmp(:,end-1) = createbasisfunction(Xtr, Xtmp, basisFunctionList{1,i}, ...
                                        basisFunctionList{2,i}, dirs, basisFunctionList{4,i}, minX, maxX);
                        ok1 = ~isnan(Xtmp(1,end-1));
                        % Reflected partner
                        dirs(end) = -dirs(end);
                        Xtmp(:,end) = createbasisfunction(Xtr, Xtmp, basisFunctionList{1,i}, ...
                                      basisFunctionList{2,i}, dirs, basisFunctionList{4,i}, minX, maxX);
                        ok2 = ~isnan(Xtmp(1,end));
                    end
                    if ok1 && ok2 % both basis functions created
                        [tmpCoefs(:,i), tmpErr(i)] = lreg(Xtmp, Ytr, weights, wd);
                    elseif ok1 || ok2 % one of the basis functions not created
                        if (ok1)
                            [coefs, tmpErr(i)] = lreg(Xtmp(:, 1:end-1), Ytr, weights, wd);
                        else
                            [coefs, tmpErr(i)] = lreg([Xtmp(:, 1:end-2) Xtmp(:, end)], Ytr, weights, wd);
                        end
                        tmpCoefs(:,i) = [coefs; NaN];
                    %else % no basis function created
                    %    tmpErr(i) = Inf; % unnecessary because the array is already initialized as Inf
                    end
                end

                % find the best daughter basis function
                if ((trainParams.newVarPenalty > 0) && (currIter > 1))
                    adjust = ones(1,size(basisFunctionList,2));
                    for i = 1 : size(basisFunctionList,2)
                        if (~isempty(setdiff(basisFunctionList{1,i}, dimsInModel)))
                            adjust(i) = 1 + trainParams.newVarPenalty;
                        end
                    end
                    % the adjusted values are used for selection only,
                    % they are not used in any further calculations
                    [dummy, ind] = min(tmpErr .* adjust);
                    newErr = tmpErr(ind) / YtrVar;
                else
                    [newErr, ind] = min(tmpErr);
                    newErr = newErr / YtrVar;
                end

            end % end of "if (trainParams.fastK < Inf)"

            % stop the forward phase if no correct model was created or
            % if the decrease in error is below the threshold
            if (isnan(newErr)) || (err - newErr < trainParams.threshold)
                if trainParams.cubic
                    t1 = tmp_t1;
                    t2 = tmp_t2;
                end
                if verbose
                    if isnan(newErr)
                        fprintf('\nAdditional termination condition is met: no more models could be created.');
                    else
                        fprintf('\nAdditional termination condition is met: err/std improvement is below threshold.');
                    end
                end
                break;
            end

            if trainParams.cubic
                [t1, t2, dif] = findsideknots(model, basisFunctionList{1,ind}, basisFunctionList{2,ind}, ...
                              d, minX, maxX, tmp_t1, tmp_t2);
                % update basis functions with the updated side knots
                for j = 1 : length(model.knotdims)
                    if dif(j)
                        X(:,j+1) = createbasisfunction(Xtr, X, model.knotdims{j}, model.knotsites{j}, ...
                                   model.knotdirs{j}, model.parents(j), minX, maxX, t1(j,:), t2(j,:));
                    end
                end
                % Add the new basis function
                dirs = basisFunctionList{3, ind};
                Xn = createbasisfunction(Xtr, X, basisFunctionList{1,ind}, basisFunctionList{2,ind}, ...
                     dirs, basisFunctionList{4,ind}, minX, maxX, t1(end,:), t2(end,:));
                if isnan(Xn(1)), Xn = []; end
                % Add the reflected partner
                dirs(end) = -dirs(end);
                Xn2 = createbasisfunction(Xtr, X, basisFunctionList{1,ind}, basisFunctionList{2,ind}, ...
                      dirs, basisFunctionList{4,ind}, minX, maxX, t1(end,:), t2(end,:));
                if isnan(Xn2(1)), Xn2 = []; end
                X = [X Xn Xn2];
                if ~isempty(Xn) && ~isempty(Xn2) % both basis functions are created
                    t1(end+1,:) = t1(end,:);
                    t2(end+1,:) = t2(end,:);
                end
            else
                dirs = basisFunctionList{3, ind};
                % Add the new basis function
                Xn = createbasisfunction(Xtr, X, basisFunctionList{1,ind}, ...
                     basisFunctionList{2,ind}, dirs, basisFunctionList{4,ind}, minX, maxX);
                if isnan(Xn(1)), Xn = []; end
                % Add the reflected partner
                dirs(end) = -dirs(end);
                Xn2 = createbasisfunction(Xtr, X, basisFunctionList{1,ind}, ...
                      basisFunctionList{2,ind}, dirs, basisFunctionList{4,ind}, minX, maxX);
                if isnan(Xn2(1)), Xn2 = []; end
                X = [X Xn Xn2];
            end

            model.coefs = tmpCoefs(:,ind);

            % add the basis functions to the model
            numNewFuncs = 0;
            dirs = basisFunctionList{3, ind};
            if ~isempty(Xn)
                model.knotdims{end+1,1} = basisFunctionList{1, ind};
                model.knotsites{end+1,1} = basisFunctionList{2, ind};
                model.knotdirs{end+1,1} = dirs;
                model.parents(end+1,1) = basisFunctionList{4, ind};
                numNewFuncs = numNewFuncs + 1;
                if (trainParams.newVarPenalty > 0)
                    dimsInModel = union(dimsInModel, basisFunctionList{1, ind});
                end
            else
                model.coefs(end) = [];
            end
            if ~isempty(Xn2)
                dirs(end) = -dirs(end);
                model.knotdims{end+1,1} = basisFunctionList{1, ind};
                model.knotsites{end+1,1} = basisFunctionList{2, ind};
                model.knotdirs{end+1,1} = dirs;
                model.parents(end+1,1) = basisFunctionList{4, ind};
                numNewFuncs = numNewFuncs + 1;
                if (trainParams.newVarPenalty > 0)
                    dimsInModel = union(dimsInModel, basisFunctionList{1, ind});
                end
            else
                model.coefs(end) = [];
            end

            if verbose, fprintf('..'); end

            % stop the forward phase if newErr is too small or if the
            % number of model's basis functions (including intercept term)
            % in the next iteration is expected to be > n
            err = newErr;
            if (newErr < trainParams.threshold)
                if verbose
                    fprintf('\nAdditional termination condition is met: err/std is below threshold.');
                end
                break;
            end
            if (length(model.coefs) + 2 > n)
                if verbose
                    fprintf('\nAdditional termination condition is met: number of basis functions reached the number of data cases.');
                end
                break;
            end

            if trainParams.cubic
                tmp_t1 = t1;
                tmp_t2 = t2;
            end
            basisFunctionList(:,ind) = [];

            if (trainParams.fastK < Inf)
                % update references according to the index of parent basis function
                for ir = 1 : length(fastParent)
                    if fastParent{ir}.idxStart > ind
                        fastParent{ir}.idxStart = fastParent{ir}.idxStart - 1;
                    end
                    if fastParent{ir}.idxEnd >= ind
                        fastParent{ir}.idxEnd = fastParent{ir}.idxEnd - 1;
                    end
                    if fastParent{ir}.bestIdxInList > ind
                        fastParent{ir}.bestIdxInList = fastParent{ir}.bestIdxInList - 1;
                    end
                end
                for ir = 1 : length(fastParent)
                    if fastParent{ir}.idxStart > fastParent{ir}.idxEnd
                        fastParent(ir) = [];
                        fastMinErrAdj(ir) = [];
                        fastIterComputedErr(ir) = [];
                        fastNumBasis = fastNumBasis - 1;
                        break;
                    end
                end
            end
            
        end % end of the main loop

        if verbose, fprintf('\n'); end

    end % end of "isempty(modelOld)"

    if isempty(modelOld)
        if (doCubicFastLevel == 1) || ...
           ((doCubicFastLevel >= 2) && (~trainParams.prune)) % for this level, if there is no pruning, we force calculations for cubic
            % turn the cubic modelling on
            trainParams.cubic = true;
            [t1, t2] = findsideknots(model, [], [], d, minX, maxX, [], []);
            % update all the basis functions
            for i = 1 : length(model.knotdims)
                X(:,i+1) = createbasisfunction(Xtr, X, model.knotdims{i}, model.knotsites{i}, ...
                           model.knotdirs{i}, model.parents(i), minX, maxX, t1(i,:), t2(i,:));
            end
            [model.coefs, model.MSE] = lreg(X, Ytr, weights, wd);
            model.MSE = model.MSE / n;
        else
            model.MSE = err * YtrVar / n;
        end
        model.GCV = gcv(model, model.MSE, n, trainParams_actual_c);
        if trainParams.cubic
            model.t1 = t1;
            model.t2 = t2;
        end
    end

    % BACKWARD PHASE

    if trainParams.prune

        if verbose, fprintf('Backward phase .'); end

        if ~isempty(modelOld) % create basis functions from scratch when modelOld is used
            if (doCubicFastLevel == -1) || (doCubicFastLevel >= 2) % either no cubic or not yet cubic
                if isfield(modelOld, 'X')
                    X = modelOld.X;
                else
                    % create all basis functions (linear) from scratch
                    X = ones(n,length(model.knotdims)+1);
                    for i = 1 : length(model.knotdims)
                        X(:,i+1) = createbasisfunction(Xtr, X, model.knotdims{i}, model.knotsites{i}, ...
                                   model.knotdirs{i}, model.parents(i), minX, maxX);
                    end
                    [model.coefs, model.MSE] = lreg(X, Ytr, weights, wd);
                    model.MSE = model.MSE / n;
                end
            else % cubic modelling when doCubicFastLevel is set to 0 or 1
                trainParams.cubic = true; % set to true once again because the value in modelOld is lost
                t1 = model.t1;
                t2 = model.t2;
                if isfield(modelOld, 'X')
                    X = modelOld.X;
                else
                    % create all basis functions (cubic) from scratch
                    X = ones(n,length(model.knotdims)+1);
                    for i = 1 : length(model.knotdims)
                        X(:,i+1) = createbasisfunction(Xtr, X, model.knotdims{i}, model.knotsites{i}, ...
                                   model.knotdirs{i}, model.parents(i), minX, maxX, t1(i,:), t2(i,:));
                    end
                end
            end
            % recalculate GCV in case c has changed (e.g., if aresbuild is called from arescvc) or GCV was not yet calculated
            model.GCV = gcv(model, model.MSE, n, trainParams_actual_c);
        end

        models = {model};
        mses = model.MSE;
        gcvs = model.GCV;

        % the main loop of the backward phase
        for j = 1 : length(model.knotdims)
            tmpErr = inf(1, length(model.knotdims));
            tmpCoefs = inf(length(model.coefs)-1, length(model.knotdims));

            % try to delete model's basis functions one at a time
            for k = 1 : length(model.knotdims)
                Xtmp = X;
                Xtmp(:,k+1) = [];
                if trainParams.cubic
                    % create temporary t1, t2, and model with a deleted basis function
                    tmp_t1 = t1;
                    tmp_t1(k,:) = [];
                    tmp_t2 = t2;
                    tmp_t2(k,:) = [];
                    tmp_model.knotdims = model.knotdims;
                    tmp_model.knotdims(k) = [];
                    tmp_model.knotsites = model.knotsites;
                    tmp_model.knotsites(k) = [];
                    tmp_model.knotdirs = model.knotdirs;
                    tmp_model.knotdirs(k) = [];
                    tmp_model.parents = model.parents;
                    tmp_model.parents(k) = [];
                    tmp_model.parents = updateParents(tmp_model.parents, k);
                    [tmp_t1, tmp_t2, dif] = findsideknots(tmp_model, [], [], d, minX, maxX, tmp_t1, tmp_t2);
                    % update basis functions with the updated side knots
                    for i = 1 : length(tmp_model.knotdims)
                        if dif(i)
                            Xtmp(:,i+1) = createbasisfunction(Xtr, Xtmp, tmp_model.knotdims{i}, tmp_model.knotsites{i}, ...
                                          tmp_model.knotdirs{i}, tmp_model.parents(i), minX, maxX, tmp_t1(i,:), tmp_t2(i,:));
                        end
                    end
                end
                [coefs, tmpErr(k)] = lreg(Xtmp, Ytr, weights, wd);
                tmpCoefs(:,k) = coefs;
            end

            [dummy, ind] = min(tmpErr); % find out the best modification
            X(:,ind+1) = [];
            model.coefs = tmpCoefs(:,ind);
            model.knotdims(ind) = [];
            model.knotsites(ind) = [];
            model.knotdirs(ind) = [];
            model.parents(ind) = [];
            model.parents = updateParents(model.parents, ind);

            if trainParams.cubic
                t1(ind,:) = [];
                t2(ind,:) = [];
                [t1, t2, dif] = findsideknots(model, [], [], d, minX, maxX, t1, t2);
                % update basis functions with the updated side knots
                for i = 1 : length(model.knotdims)
                    if dif(i)
                        X(:,i+1) = createbasisfunction(Xtr, X, model.knotdims{i}, model.knotsites{i}, ...
                                   model.knotdirs{i}, model.parents(i), minX, maxX, t1(i,:), t2(i,:));
                    end
                end
                model.t1 = t1;
                model.t2 = t2;
            end

            models{end+1} = model;
            mses(end+1) = tmpErr(ind) / n;
            gcvs(end+1) = gcv(model, mses(end), n, trainParams_actual_c);

            if verbose, fprintf('.'); end
        end % end of the main loop

        % now choose the best pruned model
        if trainParams.maxFinalFuncs >= length(models{1}.coefs)
            [g, ind] = min(gcvs);
        elseif trainParams.maxFinalFuncs > 1
            [g, ind] = min(gcvs(end-trainParams.maxFinalFuncs+1:end));
            ind = ind + length(gcvs) - trainParams.maxFinalFuncs;
        else
            g = gcvs(end);
            ind = length(gcvs);
        end
        model = models{ind};

        if doCubicFastLevel >= 2
            % turn the cubic modelling on
            trainParams.cubic = true;
            [t1, t2] = findsideknots(model, [], [], d, minX, maxX, [], []);
            % update all the basis functions
            X = ones(n,length(model.coefs));
            for i = 1 : length(model.knotdims)
                X(:,i+1) = createbasisfunction(Xtr, X, model.knotdims{i}, model.knotsites{i}, ...
                           model.knotdirs{i}, model.parents(i), minX, maxX, t1(i,:), t2(i,:));
            end
            model.t1 = t1;
            model.t2 = t2;
            [model.coefs, model.MSE] = lreg(X, Ytr, weights, wd);
            model.MSE = model.MSE / n;
            model.GCV = gcv(model, model.MSE, n, trainParams_actual_c);
        else
            model.MSE = mses(ind);
            model.GCV = g;
            if keepX
                % recreate all basis functions from scratch just for keepX
                X = ones(n,length(model.coefs));
                if trainParams.cubic
                    for i = 1 : length(model.knotdims)
                        X(:,i+1) = createbasisfunction(Xtr, X, model.knotdims{i}, model.knotsites{i}, ...
                                   model.knotdirs{i}, model.parents(i), minX, maxX, model.t1(i,:), model.t2(i,:));
                    end
                else
                    for i = 1 : length(model.knotdims)
                        X(:,i+1) = createbasisfunction(Xtr, X, model.knotdims{i}, model.knotsites{i}, ...
                                   model.knotdirs{i}, model.parents(i), minX, maxX);
                    end
                end
            end
        end

        if verbose, fprintf('\n'); end

    end % end of "trainParams.prune"

end % end of "if endSpan*2 >= n"

model.trainParams = trainParams;
model.minX = minX;
model.maxX = maxX;
model.endSpan = endSpan;

if keepX
    model.X = X;
end

time = toc;
if verbose
    fprintf('Number of basis functions in the final model: %d\n', length(model.coefs));
    fprintf('Total effective number of parameters: %0.1f\n', ...
            length(model.coefs) + model.trainParams.c * length(model.knotdims) / 2);
    maxDeg = 0;
    if ~isempty(model.knotdims)
        for i = 1 : length(model.knotdims)
            if length(model.knotdims{i}) > maxDeg
                maxDeg = length(model.knotdims{i});
            end
        end
    end
    fprintf('Highest degree of interactions in the final model: %d\n', maxDeg);
    fprintf('Execution time: %0.2f seconds\n', time);
end
warning(ws);
return


%=========================  Auxiliary functions  ==========================

function g = gcv(model, MSE, n, c)
% Calculates GCV from model complexity, its Mean Squared Error, number of
% data cases n, and penalty coefficient c.
enp = length(model.coefs) + c * length(model.knotdims) / 2; % model's effective number of parameters
if enp >= n
    g = Inf;
else
    p = 1 - enp / n;
    g = MSE / (p * p);
end
return

function parents = updateParents(parents, deletedInd)
% Updates direct parent indexes after deletion of a basis function.
parents(parents == deletedInd) = 0;
tmp = parents > deletedInd;
parents(tmp) = parents(tmp) - 1;
return

function [basisFunctionList, idxStart1, idxEnd1, idxStart2, idxEnd2] = ...
createList(basisFunctionList_old, Xtr, sortedXtr, sortedXtrInd, n, d, ...
model, numNewFuncs, trainParams, endSpan)
% Takes the old list of basis functions and adds new ones according to the
% current model. If the old list is empty, adds only linear basis
% functions. If it is non-empty, adds only basis functions with
% interactions which result from the last numNewFuncs basis functions
% (typically 2, sometimes 1).
% For knot placement (and for calculation of minSpan) only those potential
% knot sites are considered for which the parent basis function is larger
% than zero.
% Input argument Xtr should contain all the training data cases; sortedXtr
% should contain all the Xtr cases (except first and last endSpan points)
% sorted in each column separately; sortedXtrInd should contain indexes of
% the sorted cases.

% Create linear basis functions

if (isempty(basisFunctionList_old)) && (numNewFuncs == 0)
    if trainParams.useMinSpan ~= 1
        % make a list of knot sites allowed by minSpan
        minSpan = getMinSpan(d, n, trainParams.useMinSpan);
        % symmetrically center the knot sites
        nAvail = n - endSpan * 2;
        if nAvail > minSpan % is there space for more than one knot?
            nDiv = floor(nAvail / minSpan);
            if nDiv == nAvail / minSpan
                offset = floor(minSpan / 2);
            else
                offset = floor((nAvail - nDiv * minSpan) / 2);
            end
        else
            offset = floor(nAvail / 2); % if space for only one knot, put it in center
        end
        allowed = mod(-offset:nAvail-1-offset, minSpan) == 0;
    end
    basisFunctionList = cell(4,0);
    counter = 0;
    for di = 1 : d % for each dimension
        if trainParams.useMinSpan == 1
            allowedSites = unique(sortedXtr(:,di))';
        else
            allowedSites = unique(sortedXtr(allowed,di))';
        end
        % add new unique basis functions to the list (either all or except
        % those which do not fall on the allowed knot sites)
        for x = allowedSites
            % we could use cell array of structs here but benchmarking
            % showed that this is faster
            counter = counter + 1;
            basisFunctionList{1, counter} = di; % knotdims
            basisFunctionList{2, counter} = x;  % knotsites
            basisFunctionList{3, counter} = 1;  % knotdirs
            basisFunctionList{4, counter} = 0;  % parent
        end
    end
    if (counter > 0)
        idxStart1 = 1;
        idxEnd1 = counter;
    else
        idxStart1 = -1;
        idxEnd1 = -1;
    end
    idxStart2 = -1;
    idxEnd2 = -1;
    return
end

if (trainParams.maxInteractions < 2) || (numNewFuncs < 1)
    basisFunctionList = basisFunctionList_old;
    idxStart1 = -1;
    idxEnd1 = -1;
    idxStart2 = -1;
    idxEnd2 = -1;
    return
end

% Create basis functions with interactions

% for basis functions with interactions we can make endSpan wider
if (trainParams.endSpanAdjust > 1)
    endSpanToUse = round(endSpan * trainParams.endSpanAdjust);
    if endSpanToUse * 2 >= n
        endSpanToUse = floor(n / 2) - 1; % force always at least one knot
    end
else
    endSpanToUse = endSpan;
end

basisFunctionList = basisFunctionList_old;
sizeOld = size(basisFunctionList_old,2);
counter = sizeOld;
start = length(model.knotdims) - (numNewFuncs-1);

idxStart1 = counter + 1;
idxEnd1 = -1;
idxStart2 = -1;

% loop through one or two last basis functions already in the model
for j = start : length(model.knotdims)
    if (j > start)
        if (counter >= idxStart1)
            idxEnd1 = counter;
        else
            idxStart1 = -1;
            idxEnd1 = -1;
        end
        idxStart2 = counter + 1;
    end
    if length(model.knotdims{j}) < trainParams.maxInteractions
        allowedDims = 1 : d;
        if trainParams.selfInteractions <= 1
            % will not consider already used dimensions
            allowedDims = setdiff(allowedDims, model.knotdims{j});
        else
            for i = 1 : d
                if length(find(model.knotdims{j} == i)) >= trainParams.selfInteractions
                    allowedDims = setdiff(allowedDims, i);
                end
            end
        end
        if isempty(allowedDims)
            continue
        end

        if trainParams.useMinSpan ~= 1

            % make a list of knot sites allowed by minSpan
            nonzero = listNonZero(Xtr, model.knotdims{j}, model.knotsites{j}, model.knotdirs{j});
            minSpan = getMinSpan(d, length(find(nonzero)), trainParams.useMinSpan);
            if ~isfinite(minSpan)
                continue
            end
            % symmetrically center the knot sites
            nAvail = n - endSpanToUse * 2;
            if nAvail > minSpan % is there space for more than one knot?
                nDiv = floor(nAvail / minSpan);
                if nDiv == nAvail / minSpan
                    offset = floor(minSpan / 2);
                else
                    offset = floor((nAvail - nDiv * minSpan) / 2);
                end
            else
                offset = floor(nAvail / 2); % if space for only one knot, put it in center
            end
            allowed = mod(-offset:nAvail-1-offset, minSpan) == 0;

            for di = allowedDims % for each dimension
                % add new unique basis functions to the list (all except
                % those which do not fall on the allowed knot sites and
                % except those for which the parent basis function is zero
                % on the knot site)
                if (trainParams.endSpanAdjust > 1)
                    add = endSpanToUse - endSpan;
                    allowed = allowed & nonzero(sortedXtrInd(1+add:end-add,di));
                else
                    allowed = allowed & nonzero(sortedXtrInd(:,di));
                end
                allowedSites = unique(sortedXtr(allowed,di))';
                for x = allowedSites
                    counter = counter + 1;
                    basisFunctionList{1, counter} = [model.knotdims{j} di];
                    basisFunctionList{2, counter} = [model.knotsites{j} x];
                    basisFunctionList{3, counter} = [model.knotdirs{j} 1];
                    basisFunctionList{4, counter} = j;
                end
            end

        else

            nonzero = listNonZero(Xtr, model.knotdims{j}, model.knotsites{j}, model.knotdirs{j});
            for di = allowedDims % for each dimension
                % add new unique basis functions to the list (all except
                % those for which the parent basis function is zero on
                % the knot site)
                if (trainParams.endSpanAdjust > 1)
                    add = endSpanToUse - endSpan;
                    allowedSites = unique(sortedXtr(nonzero(sortedXtrInd(1+add:end-add,di)),di))';
                else
                    allowedSites = unique(sortedXtr(nonzero(sortedXtrInd(:,di)),di))';
                end
                for x = allowedSites
                    counter = counter + 1;
                    basisFunctionList{1, counter} = [model.knotdims{j} di];
                    basisFunctionList{2, counter} = [model.knotsites{j} x];
                    basisFunctionList{3, counter} = [model.knotdirs{j} 1];
                    basisFunctionList{4, counter} = j;
                end
            end

        end

    end
end
if (sizeOld == size(basisFunctionList,2)) % size didn't increase
    idxStart1 = -1;
    idxEnd1 = -1;
    idxStart2 = -1;
    idxEnd2 = -1;
else
    if (idxStart1 > 0) && (idxEnd1 <= 0) % possible only if there is no second parent
        idxEnd1 = counter;
        idxEnd2 = -1;
    elseif (idxStart2 > 0) && (counter >= idxStart2)
        idxEnd2 = counter;
    else
        idxStart2 = -1;
        idxEnd2 = -1;
    end
end
return

function nonzero = listNonZero(Xtr, knotdims, knotsites, knotdirs)
% Lists nonzero (according to the parent basis function) sites where knots
% may be placed. (Line 5 of Algorithm 2 in Friedman 1991)
nonzero = true(1,size(Xtr,1));
for j = 1 : size(Xtr,1)
    for i = 1 : length(knotdims)
        z = Xtr(j,knotdims(i)) - knotsites(i);
        if ((z >= 0) && (knotdirs(i) < 0)) || ...
           ((z <= 0) && (knotdirs(i) > 0))
            nonzero(j) = false;
            break;
        end
    end
end
return

function s = getEndSpan(d)
% Calculation of endSpan so that potential knot sites that are too close to
% the ends of data intervals are not considered.
%s = floor(3 - log2(0.05/d));
s = floor(7.32193 + log(d) / 0.69315); % precomputed version
if s < 1, s = 1; end
return

function s = getMinSpan(d, nz, param)
% Calculation of minSpan so that only those potential knot sites are
% considered which are at least minSpan apart. This increases resistance to
% runs of correlated noise.
% nz is the number of potential knot sites where the parent basis function
% is nonzero.
if nz == 0
    s = Inf;
else
    if param < 0 % automatic
        %s = floor(-log2(-log(1-0.05)/(d*nz)) / 2.5);
        s = floor((2.9702 + log(d*nz)) / 1.7329); % precomputed version
    else
        s = param;
        if s > nz
            s = Inf;
        end
    end
    if s < 1, s = 1; end
end
return

function [coefs, err] = lreg(x, y, w, wd)
% Linear regression (unweighted and weighted)
if isempty(wd)
    coefs = (x' * x) \ (x' * y);
    err = sum((y-x*coefs).^2);
else
    x_wd = x' * wd;
    coefs = (x_wd * x) \ (x_wd * y);
    err = sum((y-x*coefs).^2.*w);
end
return
