%% quiz 3
%% 1 a) False  b) True

%% 2
clc
clear all
close all
r = 0.03;
sigma = 0.2;
S = 100; % initial stock price
N_Simulation = 3000;
T = 2; % time to maturity
Number_of_Intervals = 20; % As this value goes to infinity, binomial converges to brownian 
dt = 1/Number_of_Intervals; 
time = (dt:dt:T); % time set
K = 100*exp(0.03*2);
 
% Stock Price Process Simulation
dW = sqrt(dt)*randn(length(time),N_Simulation);

Initial_Log_Stock_Price = log(S)*ones(1,N_Simulation);
Log_Stock_Price_Diff = (r-0.5*(sigma^2))*dt*ones( length(time),N_Simulation ) ... % drift term approximation
                       + sigma*dW ; % Brownian term approximation
 
temp = [Initial_Log_Stock_Price; Log_Stock_Price_Diff]; % first row is log(S_0) and the rest is d(log(S_t))
Log_Stock_Price = cumsum(temp);
Stock_Price = exp(Log_Stock_Price);

% knock in
Put_payoff = nan(1, N_Simulation);
Future_payoff = nan(1, N_Simulation);
Realized_Payoff = nan(1, N_Simulation);
for i = 1:N_Simulation
    % below 90
    if min(Stock_Price(:,i)) < 90
        Put_payoff(i) = 0;
    else
        Put_payoff(i) = max( K - Stock_Price(end,i), 0);
    end
    
    % above 120
    if max(Stock_Price(:, i)) > 120
        Future_payoff(i) = -5 * (Stock_Price(end,i) - 100*exp(0.03*2));
    else
        Future_payoff(i) = 0;
    end
    Realized_Payoff(i) = Put_payoff(i) + Future_payoff(i);
end
Realized_Payoff = Realized_Payoff * exp(-r*T);
KIKO_Price = mean(Realized_Payoff,2) % averaging