% return the value of lagrange function at x0. Given a series of points(x, y)
function [ p ] = LagrangeFunction( x0, x, y)
for k = 1:size(x0, 2)
    p(k) = 0;
    for i = 1:size(y, 2)
        temp = 1;
        for j = 1:size(x, 2)
            if i ~= j
                temp = temp * (x0(k) - x(j)) / (x(i) - x(j));
            end;
        end;
        p(k) = p(k) + y(i) * temp;
    end
end
end

