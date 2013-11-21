function m = findmin(fun,range,tol),
    X = [range(1);mean(range);range(2)];
    while 1,
        Y = arrayfun(fun,X);
        %[fun(X(1));fun(X(range));fun(X(3))];
        Mx = [X.^2 X ones(size(X))];
        Coeffs = Mx\Y;
        m = -Coeffs(2)/2/Coeffs(1)
        if min(abs(m - X)) < tol, break, end
        % found new minimum, see what x should be out
        [idle n] = max(abs(X-m));
        X = [X(find(X ~= X(n)));m];
    end
end
    
    