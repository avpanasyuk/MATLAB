function m5pout(model, showNumCases, precision, plotTree, plotFontSize)
% m5pout
% Outputs M5' tree in a human-readable form.
%
% Call:
%   m5pout(model, showNumCases, precision, plotTree, plotFontSize)
%
% All the arguments, except the first one, of this function are optional.
% Empty values are also accepted (the corresponding default values will be
% used).
%
% Input:
%   model         : M5' model.
%   showNumCases  : Whether to show the number of training observations
%                   corresponding to each leaf (default value = true).
%   precision     : Number of digits in the model coefficients, split
%                   values etc. (default value = 15).
%   plotTree      : Whether to plot the tree instead of printing it
%                   (default value = false). In the plotted tree, upper
%                   child of a node corresponds to outcome 'true' and lower
%                   child to 'false'.
%   plotFontSize  : Font size for text in the plot (default value = 8).
%
% Remarks:
% 1. If the training data has categorical variables, the corresponding
% synthetic variables will be shown.
% 2. The outputted tree will not reflect smoothing. Smoothing is performed
% only while predicting output values (in m5ppredict function).

% =========================================================================
% M5PrimeLab: M5' regression tree and model tree toolbox for Matlab/Octave
% Author: Gints Jekabsons (gints.jekabsons@rtu.lv)
% URL: http://www.cs.rtu.lv/jekabsons/
%
% Copyright (C) 2010-2015  Gints Jekabsons
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

% Last update: July 11, 2015

if nargin < 1
    error('Too few input arguments.');
end
if (nargin < 2) || isempty(showNumCases)
    showNumCases = true;
end
if (nargin < 3) || isempty(precision)
    precision = 15;
end
if (nargin < 4) || isempty(plotTree)
    plotTree = false;
end
if (nargin < 5) || isempty(plotFontSize)
    plotFontSize = 8;
end

% Show synthetic variables
if any(model.binCat.binCat > 2)
    disp('Synthetic variables:');
    indCounter = 0;
    binCatCounter = 0;
    for i = 1 : length(model.binCat.binCat)
        if model.binCat.binCat(i) > 2
            binCatCounter = binCatCounter + 1;
            for j = 1 : length(model.binCat.catVals{binCatCounter})-1
                indCounter = indCounter + 1;
                str = num2str(model.binCat.catVals{binCatCounter}(j+1:end)', [' %.' num2str(precision) 'g,']);
                disp(['z' num2str(indCounter) ' = 1 if x' num2str(i) ' is in {' str(1:end-1) '} else = 0']);
            end
        else
            indCounter = indCounter + 1;
            disp(['z' num2str(indCounter) ' = x' num2str(i)]);
        end
    end
    zx = 'z';
else
    zx = 'x';
end

if model.trainParams.smoothing
    disp('Warning: The tree does not reflect smoothing.');
end
if isfield(model.binCat, 'minVals')
    minVals = model.binCat.minVals;
else
    minVals = [];
end
if ~plotTree
    disp('The tree:');
    numRules = output(model.tree, model.trainParams.modelTree, model.binCat.binCatNew, ...
                      minVals, 0, 0, zx, showNumCases, precision);
    disp(['Number of rules in the tree: ' num2str(numRules)]);
else
    figure('color', [1,1,1]);
    axis off;
    hold on;
    len = []; % number of nodes in a column
    analyzeChildren(model.tree, 1);
    pos = zeros(max(len), length(len)); % positions of nodes in columns
    for i = 1 : length(len)
        num = len(i);
        step = 1 / (num + 1);
        where = 1:-step:0;
        pos(1:num,i) = where(2:end-1);
    end
    idx = zeros(1, length(len)); % index of current positions in columns
    p = ['%.' num2str(precision) 'g'];
    plotChildren(model.tree, 0, 1, model.trainParams.modelTree, model.binCat.binCatNew, plotFontSize);
end

    function analyzeChildren(node, depth)
        if length(len) >= depth
            len(depth) = len(depth) + 1;
        else
            len(depth) = 1;
        end
        if strcmp(node.type, 'LEAF')
            return;
        end
        if (~isempty(node.left))
            analyzeChildren(node.left, depth + 1);
        end
        if (~isempty(node.right))
            analyzeChildren(node.right, depth + 1);
        end
    end

    function plotChildren(node, x, depth, modelTree, binCatNew, plotFontSize)
        idx(depth) = idx(depth) + 1;
        myY = pos(idx(depth), depth);
        
        if strcmp(node.type, 'LEAF')
            if ~modelTree
                str = ['y = ' num2str(node.value,p)];
            else
                % show regression model
                str = ['y = ' num2str(node.model.coefs(1),p)];
                for i = 1 : length(node.model.attrInd)
                    if node.model.coefs(i+1) >= 0
                        str = [str ' +'];
                    else
                        str = [str ' '];
                    end
                    str = [str num2str(node.model.coefs(i+1),p) '*' zx num2str(node.model.attrInd(i))];
                end
            end
            if showNumCases
                str = [str ' (' num2str(length(node.caseInd)) ')'];
            end
            plot(x + 15, myY, 'w'); % just so that text doesn't go outside image
            text(x - 0.5, myY - 0.02, str, 'FontSize', plotFontSize);
            return;
        end
        
        if binCatNew(node.splitAttribute) % a binary variable (might be synthetic)
            str = ([zx num2str(node.splitAttribute) ' == ' num2str(minVals(node.splitAttribute),p)]);
        else % a continuous variable
            str = ([zx num2str(node.splitAttribute) ' <= ' num2str(node.splitLocation)]);
        end
        text(x - 0.5, myY + 0.03, str, 'FontSize', plotFontSize, 'FontWeight', 'Bold');
        newX = x + 10;
        if (~isempty(node.left))
            newY = pos(idx(depth + 1) + 1, depth + 1);
            plot([x;newX], [myY;newY], 'k-o');
            plotChildren(node.left, newX, depth + 1, modelTree, binCatNew, plotFontSize);
        end
        if (~isempty(node.right))
            newY = pos(idx(depth + 1) + 1, depth + 1);
            plot([x;newX], [myY;newY], 'k-o');
            plotChildren(node.right, newX, depth + 1, modelTree, binCatNew, plotFontSize);
        end
    end

end

function numRules = output(node, modelTree, binCatNew, minVals, offset, numR, zx, showNumCases, precision)
p = ['%.' num2str(precision) 'g'];
if strcmp(node.type, 'INTERIOR')
    if binCatNew(node.splitAttribute) % a binary variable (might be synthetic)
        disp([repmat(' ',1,offset) 'if ' zx num2str(node.splitAttribute) ' == ' num2str(minVals(node.splitAttribute),p)]);
    else % a continuous variable
        disp([repmat(' ',1,offset) 'if ' zx num2str(node.splitAttribute) ' <= ' num2str(node.splitLocation)]);
    end
    numRules = output(node.left, modelTree, binCatNew, minVals, offset + 1, numR, zx, showNumCases, precision);
    disp([repmat(' ',1,offset) 'else']);
    numRules = output(node.right, modelTree, binCatNew, minVals, offset + 1, numRules, zx, showNumCases, precision);
    %disp([repmat(' ',1,offset) 'end']);
else
    if ~modelTree
        str = [repmat(' ',1,offset) 'y = ' num2str(node.value,p)];
    else
        % show regression model
        str = [repmat(' ',1,offset) 'y = ' num2str(node.model.coefs(1),p)];
        for i = 1 : length(node.model.attrInd)
            if node.model.coefs(i+1) >= 0
                str = [str ' +'];
            else
                str = [str ' '];
            end
            str = [str num2str(node.model.coefs(i+1),p) '*' zx num2str(node.model.attrInd(i))];
        end
    end
    if showNumCases
        str = [str ' (' num2str(length(node.caseInd)) ')'];
    end
    disp(str);
    numRules = numR + 1;
end
end
