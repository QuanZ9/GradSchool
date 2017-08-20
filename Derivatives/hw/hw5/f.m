function [ y ] = f( x )
    y = normcdf(x, 0, 1) - 0.5*normcdf(x, 0, sqrt(0.5)) - 0.5 * normcdf(x, 0, sqrt(1.5));
end

