% strip outliers on edges by throwing away given percent of outlying point
function [c MinEdge MaxEdge]=enhance(a,percent),
    [n,xout] = hist(double(a(:)),sqrt(length(a)));
    cumn = cumsum(n);
    good_points = find(cumn > cumn(end)*percent & cumn < cumn(end)*(1-percent));
    MinEdge = xout(min(good_points)); MaxEdge = xout(max(good_points));
    c = a;
    TooBig = find(c > MaxEdge); c(TooBig) = MaxEdge;
    TooSmall = find(c < MinEdge); c(TooSmall) = MinEdge;
end

    
    
    