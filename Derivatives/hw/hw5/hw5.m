%% 1
% x = [-3:0.1:3];
% ya = 0.5 * normcdf(x, 0, sqrt(0.5)) + 0.5 * normcdf(x, 0, sqrt(1.5));
% yb = normcdf(x, 0, 1);
% x_star = fsolve(@f, 2);
% plot(x, ya, 'r');
% hold on;
% plot(x, yb, 'b');

%% 2
K = 100;
T = 1;
r = 0.03;
vol = 0.3;
S = 50:1:150;
[Call_Price, ~] = blsprice(S, K, r, T, vol);
[Call_Delta, ~] = blsdelta(S, K, r, T, vol);
elasticity = Call_Delta .* S ./ Call_Price;

plot(S, elasticity);
