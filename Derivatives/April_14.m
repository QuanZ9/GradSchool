clc
clear all
close all

r = 0.03;
sigma = 0.3;
lambda = 10; % jump arrival

% jump size
mu_J = 0;
sigma_J = 0.5;

nu = (exp( mu_J + 0.5 * sigma_J^2) - 1) * lambda;

S_0 = 100;

T = 1;
dt = 0.001;
time = (dt:dt:T);
N_sim = 1;

dW = sqrt(dt)*randn(length(time), N_sim);
dN = ( rand(length(time), N_sim) < lambda * dt); % jump arrival
logJ = mu_J + sigma_J*randn(length(time), N_sim);

dlogS = (r - 0.5 * sigma^2 - nu) * dt + sigma*dW + logJ.*dN;

Aug = [log(S_0)*(ones(1, N_sim))
        dlogS];
logS = cumsum(Aug);
S = exp(logS);

plot(S)



