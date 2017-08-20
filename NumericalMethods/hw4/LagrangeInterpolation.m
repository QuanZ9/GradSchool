% Lagrange Interpolation
x = [-5:5];
gx = 1 ./ ( 1 + x.^2);
gxp = -2*x ./ (1 + x.^2).^2;
px = LagrangeFunction(x ,x, gx);

dx = 0.001;
for i=1:size(x,2)
   xp(2*i - 1) = x(i) - dx;
   xp(2*i) = x(i) + dx;
end

pxp = LagrangeFunction(xp, x, gx);

for i=1:size(x, 2)
    pp(i) = (pxp(2*i) - pxp(2*i - 1)) / dx / 2;
end
px
pp
gx
gxp

x1 = [-5.2:0.1:5.2];
px1 = LagrangeFunction(x1, x, gx);
plot(x1, px1)
hold on;
gx1 = 1 ./ (1 + x1.^2);
plot(x1, gx1)
legend('p(x)','g(x)')