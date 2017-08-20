function [ y ] = akima( xi,yi,x )
% AKIMA interpolation
% subscripts mapping
% -1 0 1 2 3 4 5 ...
%  1 2 3 4 5 6 7 ...
k = length(xi);
h = diff(xi);
d(3:k+1) = diff(yi) ./ h;
d(2) = 2*d(3) - d(4);
d(1) = 2*d(2) - d(3);
d(k+2) = 2*d(k+1) - d(k);
d(k+3) = 2*d(k+2) - d(k+1);
w = abs(diff(d));

for i = 3:k+2
    sp(i-2) = (w(i) * d(i-1) + w(i-2) * d(i)) ./ (w(i-2) + w(i));
end

a = zeros(k-1,4);
for i = 1:k-1
    A = [1 0 0 0
         1 h(i) h(i).^2 h(i).^3
         0 1 0 0
         0 1 2*h(i) 3*h(i).^2];
    b = [yi(i); yi(i+1); sp(i); sp(i+1)];
    a(i,:) = (A\b)';
end

y = zeros(1, length(x));
idx = x < xi(1);
y(idx) = a(1,1) + a(1,2).* (x(idx) - xi(1)) ...
                  + a(1,3).*(x(idx)- xi(1)).^2 + a(1,4).*(x(idx) - xi(1)).^3;
idx = x > xi(k);
y(idx) = a(k-1,1) + a(k-1,2).* (x(idx) - xi(k-1)) ...
                  + a(k-1,3).*(x(idx)- xi(k-1)).^2 + a(k-1,4).*(x(idx) - xi(k-1)).^3;
for i = 1:k-1
    idx = (x >= xi(i) & x <= xi(i+1));
    y(idx) = a(i,1) + a(i,2).* (x(idx) - xi(i)) ...
                  + a(i,3).*(x(idx)- xi(i)).^2 + a(i,4).*(x(idx) - xi(i)).^3;
end
