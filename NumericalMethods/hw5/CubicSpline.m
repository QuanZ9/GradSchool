% cubic spline interpolation
% set values
x = [0.639, 0.648, 0.657, 0.666];
y = [0.019944, 0.006335, -0.007263, -0.020850];

n=length(x);
h=diff(x);
v = diff(y);

% solve for Mi
b0(1)=0;
b0(n)=0;
A(1,1) = 1;
A(n,n) = 1;
for i=2:n-1
    A(i,i) = 1/3 * (h(i-1) + h(i));
    A(i,i-1) = 1/6 * h(i-1);
    A(i,i+1) = 1/6 * h(i);
    b0(i)=(y(i+1) - y(i)) ./ h(i) - (y(i) - y(i-1)) ./ h(i-1);
end
m = A\b0'

% compute coefficients
a = y;
b = v ./ h - 1/2 * h .* m(1:n-1,1)' - 1/6 * h .* (diff(m))';
c = m / 2;
d = 1/6 * diff(m)' ./ h;

% xx1 = 0.639:0.001:0.648;
% xx2 = 0.648:0.001:0.657;
% xx3 = 0.657:0.001:0.666;
% yy1 = a(1) + b(1) .* (xx1-x(1)) + c(1) .* (xx1-x(1)).^2 + d(1).*(xx1-x(1)).^3;
% yy2 = a(2) + b(2) .* (xx2-x(2)) + c(2) .* (xx2-x(2)).^2 + d(2).*(xx2-x(2)).^3;
% yy3 = a(3) + b(3) .* (xx3-x(3)) + c(3) .* (xx3-x(3)).^2 + d(3).*(xx3-x(3)).^3;
% xx = [xx1,xx2,xx3];
% yy = [yy1,yy2,yy3];
% 
% plot(x,y,'o',xx,yy)

% compute the root of PHI(x) = 0 using Newton's Method
s_0 = 0;
s = 0.5;
while abs(s_0 - s) > 0.0001
    s_0 = s;
    fx = a(2) + b(2) .* (s-x(2)) + c(2) .* (s-x(2)).^2 + d(2).*(s-x(2)).^3;
    fxp = b(2) + 2*c(2).*(s - x(2)) + 3*d(2).*(s - x(2)).^2;
    s = s - fx ./ fxp;
end
s

us = (1-s) - (a(2) + b(2) .* (s-x(2)) + c(2) .* (s-x(2)).^2 + d(2).*(s-x(2)).^3);
usp = -1 - (b(2) + 2*c(2).*(s - x(2)) + 3*d(2).*(s - x(2)).^2);
usp2 = -(2*c(2) + 6*d(2).*(s - x(2)));

% plug into BS equation
r = 0.05;
q = 0.02;
sigma = 0.2;

bs = 0.5 * sigma^2 * s^2 * usp2 + (r - q) * s * usp - r * us