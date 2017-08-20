x = 0:0.01:4.5;

% y0 = 1
y0 = x.^0;
fx = (x - 1) .* (x - 2) .* (x - 3) .* (x - 4);
fpx = 4*x.^3 - 30*x.^2 + 70*x - 50;
fp2x = 12*x.^2 - 60*x + 70;
% yn = gn'
y1 = abs(1 - 0.8 * fpx);
y2 = abs(1 + 1.1 * fpx);
y3 = abs((4*x.^3 - 30*x.^2 + 70*x)/50);
y4 = abs(0.5 * ((-4*x.^3 + 30*x.^2 + 50) ./ 35).^(-0.5));
y5 = abs(1 - (fpx.^2 - fx .* fp2x) ./ fpx.^2);


% plot
plot(x, y0);
hold on;
plot(x, y1);

figure;
plot(x, y0);
hold on;
plot(x, y2);

figure;
plot(x, y0);
hold on;
plot(x, y3);

figure;
plot(x, y0);
hold on;
plot(x, y4);

figure;
plot(x, y0);
hold on;
plot(x, y5);

