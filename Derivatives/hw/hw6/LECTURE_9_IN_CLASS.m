clc
clear all
close all


%% Merton Model

sigma = 0.20;   % volatility of stock return
r = 0.03;       % risk free return
S_0 = 100;     % today's price is normalized to be 100
T = 2;
K = 100;

% parameters for jump
lambda = 2; % average arrivals per year
mu_jump = 0;
sigma_jump = 0;
nu = -lambda; 

%% Pricing with BS formula
k = 0;
r_k = (r - nu + mu_jump*k/T + 0.5*(sigma_jump^2)*k/T);
sigma_k = sqrt( sigma^2 + (sigma_jump^2)*k/T);
lambda_prime = lambda*T;
prob_k = ((lambda_prime.^k).*exp(-lambda_prime))./factorial(k);

[Call_k, ~] = blsprice(S_0, K, r_k, T, sigma_k, 0);

Call_Price_of_Merton_through_BS = sum( prob_k.*Call_k );