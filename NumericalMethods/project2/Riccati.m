clc
clear all
close all

% boundary conditions
uX = 0;
RX = 0;
wX = uX;

% parameters
X = 17;
N = 170000;
r = 0.05;
q = 0.02;
sigma = 0.2;
K = 100;

% compute R, w iteratively
R = zeros(1,N);
w = zeros(1,N);
v = zeros(1,N);
phi = zeros(1,N);
dx = X/N;
x = dx:dx:X;
% sigma = sigma .* x.^0.1;
sigma = sigma * ones(1, N);

% set boundary condition
R(N) = RX;
w(N) = wX;
for i = N-1:-1:1
    % aR^2 + bR + c = 0
    a = r./sigma(i).^2./x(i).^2;
    b = -1./dx - (r-q)./sigma(i).^2./x(i);
    c = R(i+1)./dx - (r-q).*R(i+1)./sigma(i+1).^2./x(i+1) + r.*R(i+1).^2./sigma(i+1).^2./x(i+1).^2 - 1;
    R(i) = (-b - sqrt(b.^2 - 4.*a.*c)) ./ a ./ 2;
    % a * w(n) = b * w(n+1)
    a = 1./dx - r.*R(i)./sigma(i).^2./x(i).^2;
    b = 1./dx + r.*R(i+1)./sigma(i+1).^2./x(i+1).^2;
    w(i) = b .* w(i+1) ./ a;
    % compute phi(x)
    phi(i) = -R(i) + w(i) - (1 - x(i));
%     pause;
end

% find S0 s.t. phi(S) is almost 0
S0 = 0;
i0 = 0;
for i = 2:1:N
    if (phi(i-1) * phi(i) < 0)
        if (abs(phi(i-1)) < abs(phi(i)))
            S0 = x(i-1);
            i0 = i-1;
        else
            S0 = x(i);
            i0 = i;
        end
    end
end

% compute v from S0 to X
v(i0) = -1;
for i = i0:1:N-1
    % a .* v(n) = b .* v(n+1) + c
    a = 1./dx + (r .* R(i) - (r-q).*x(i))./sigma(i).^2./x(i).^2;
    b = 1./dx - (r .* R(i+1) - (r-q).*x(i+1))./sigma(i+1).^2./x(i+1).^2;
    c = -r.*w(i+1)./sigma(i+1).^2./x(i+1).^2 - r.*w(i)./sigma(i).^2./x(i).^2;
    v(i+1) = (a .* v(i) - c) ./ b;
end
u = R .* v + w;
% % plot u(x)
% plot(x(i0:N), u(i0:N));
% hold on;
% plot(x(1:1/dx), 1-x(1:1/dx), '--');
% legend('u(x)', '1-x');
% % 
% % plot P(s)
% figure;
% plot(x(i0:N)*K, u(i0:N)*K);
% hold on;
% plot(x(1:1/dx)*K, (1-x(1:1/dx))*K, '--');
% legend('P(S)', 'K-S');


% u_star = 0.1576933168 * x.^(-1.850781059);
% SE = (u(i0:N) - u_star(i0:N)).^2;
% MSE = sum(SE) / (N-i0);
% figure;
% plot(x(i0:N), SE);
% legend('squared error of u(x)');


