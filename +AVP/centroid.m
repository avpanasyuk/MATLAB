function c = centroid(x, centerI, width, vector)
%> calculates centroid of VECTOR around index CENTERI +- WIDTH using weights X
%> if VECTOR is not defined returns centroid INDEX

if width >= centerI, width = centerI - 1; end
if width >= numel(x) - centerI - 1, width = numel(x) - centerI; end

centerX = x(centerI-width:centerI + width);
if exist('vector','var')
    centerV = vector(centerI-width:centerI + width);
else
    centerV = [-width:width]+centerI;
end
c = sum(centerX(:).*centerV(:))/sum(centerX);
end