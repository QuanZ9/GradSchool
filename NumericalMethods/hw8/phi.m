% function phi(x)
function [ ux ] = phi( xi_1, xi, xi1,x )
    ux = zeros(1,length(x));
    for i = 1:length(x)
        if x(i) < xi_1 || x(i) > xi1
            ux(i) = 0;
        elseif x(i) < xi
            ux(i) = (x(i) - xi_1) ./ (xi - xi_1);
        else
            ux(i) = (xi1 - x(i)) ./ (xi1 - xi);
        end
    end
end

