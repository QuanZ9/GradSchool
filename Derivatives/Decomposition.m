clc
clear all
close all

% set the parameters of BS world

r = 0.03;
sigma = 0.3;
T = 1;
S_0 = 100;

%% Pricing with simulation
N_simulation = 10000;
dt = 0.05;
time = (dt:dt:T);
dW = sqrt(dt) * randn(length(time), N_simulation);

dlogS = (r - 0.5 * sigma^2)*dt + sigma * dW;
Augmented = [log(S_0)*ones(1, N_simulation)
             dlogS];
logS = cumsum(Augmented);
logS_T = logS(end,:);

price_simulation_method = exp(-r*T)*mean(logS_T);

%% cash flow decomposition and pricing
K_star = exp(r*T)*S_0;
Bond_Price = exp(-r*T)*log(K_star);
Futures_Price = 0;

dK = 0.1;
From_K_star_to_a_large_number = (K_star:dK:5*K_star);
[Call_Price, ~] = blsprice(S_0, From_K_star_to_a_large_number, r, T, sigma, 0);
Call_portion = sum( (-1 ./ (From_K_star_to_a_large_number .^ 2)) .* Call_Price * dK);

From_a_samll_number_to_K_star = (dK:dK:K_star);
[~, Put_Price] = blsprice(S_0, From_a_samll_number_to_K_star, r, T, sigma, 0);
Put_portion = sum( (-1 ./ (From_a_samll_number_to_K_star .^ 2)) .* Put_Price * dK);

Price_decompostition = Bond_Price + Futures_Price + Call_portion + Put_portion;

