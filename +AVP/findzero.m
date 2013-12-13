function X1 = findzero(fun, range, tol)
    X = range;
    z = arrayfun(fun, X);
    if sign(z(1)) == sign(z(2)),
        error,'Values at the ends of RANGE should cross zero!'
    end
    while 1,
        X1 = X(1) - (X(2) - X(1))/(z(2)-z(1))*z(1);
        if min(abs(X - X1)) < tol, break, end
        Z1 = fun(X1);
        if sign(Z1) == sign(z(1))
            X = [X1; X(2)];
            z = [Z1; z(2)];
        else
            X = [X(1); X1];
            z = [z(1); Z1];
        end
    end
end

    
        
    