% find the min sqaured error
s = 10.35;
k = [9, 9.5, 10, 10.5, 11];
p = [0.01, 0.02, 0.07, 0.28, 0.68];
sigma = [0.255, 0.2, 0.17, 0.183, 0.218];
x = s ./ k;

Ap=[ones(1,5);x;x.^2];
c = (Ap * Ap') \ (Ap * sigma');
c
fx = c(1) + c(2).*x + c(3) .* x.^2;
plot(x, fx)
hold on;
plot(x, sigma)
legend('y=f(x)','sigma')
