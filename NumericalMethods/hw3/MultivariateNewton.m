% miltivariate Newton's Method
s = 10.35;
k = [9, 9.5, 10, 10.5, 11];
p = [0.01, 0.02, 0.07, 0.28, 0.68];
sigma = [0.255, 0.2, 0.17, 0.183, 0.218];
x = s ./ k;
a_init = [1;2;1];
% find A
for i = 0:2
    for j = 0:2
        A(i+1,j+1) = sum(x.^(i+j));
    end
end
%find b
for i = 0:2
    b(i+1) = sum(sigma .* x.^i);
end
%Newton's Method
a0 = [0;0;0];
a = a_init;
while (norm(a0 - a) > 0.001)
    a0 = a;
    s = A\(-A * a + b');
    a = a + s;
end
a

fx = a(1) + a(2).*x + a(3) .* x.^2;
plot(x, fx)
hold on;
plot(x, sigma)
legend('y=f(x)','sigma')

