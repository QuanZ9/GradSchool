clc;
clear all;
close all;

% fit yield curve on 2/1/2016
xi = [1/12 3/12 6/12 1 2 3 5 7 10 30];
yi = [0.1805 0.3027 0.4406 0.4666 0.7994 0.997 1.3644 1.7084 1.9494 2.7621];

% excluding 3Y
xi_3 = [1/12 3/12 6/12 1 2 5 7 10 30];
yi_3 = [0.1805 0.3027 0.4406 0.4666 0.7994 1.3644 1.7084 1.9494 2.7621];

% excluding 30Y
xi_30 = [1/12 3/12 6/12 1 2 3 5 7 10];
yi_30 = [0.1805 0.3027 0.4406 0.4666 0.7994 0.997 1.3644 1.7084 1.9494];

%% 1
x = 1/12: 1/12: 30;
y = akima(xi,yi,x);

% plot
scatter(xi, yi);
hold on;
plot(x,y, 'k');

%% 2
x = 3;
predict_y = akima(xi_3, yi_3, x)
y = 0.997

x1 = 1/12:1/12:30;
y1 = akima(xi_3, yi_3, x1);
figure;
hold on;
scatter(xi_3,yi_3);
scatter(x,y,[],'d');
plot(x1, y1, 'k')


%% 3
x = 30;
predict_y = akima(xi_30, yi_30, x)
y = 2.7621

x2 = 1/12:1/12:30;
y2 = akima(xi_30, yi_30, x2);
figure;
hold on;
scatter(xi_30,yi_30);
scatter(x,y,[],'d');
plot(x1, y2, 'k')