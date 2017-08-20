clc;
close all;
clear all;
sigma = 0.3;   % volatility of stock return
r = 0.03;       % risk free return
S_0 = 100;
K=100;
T=1;


lambda = 0.1; 
lambda_prime=lambda*T;
nu = -1*lambda;

% zero jump case

r_0 = (r-nu); 
sigma_0 = sigma; 
[~,put_0] = blsprice(S_0,K,r_0,T,sigma_0,0);
prob_0 = (lambda_prime)^0*exp(-lambda_prime)/factorial(0);

% non zero jump case

put_1 = K;
prob_1 = 1-prob_0; 

put_price = prob_0*put_0 + prob_1*put_1