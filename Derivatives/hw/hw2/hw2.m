clc
clear all
close all

%% 1
sigma = 0.2; % volatility of the underlying asset
r = 0.03; % risk free return
mu = 0.05; % risk free return
T = 2; % time to maturity
S = 100; % price of the underlying asset 
K = 100;

Number_of_Sample_Paths = 10000; % As this value goes to infinity, binomial converges to brownian 
Number_of_Intervals_Over_Unit_Time = 250; % As this value goes to infinity, binomial converges to brownian 
dt = 1/Number_of_Intervals_Over_Unit_Time; 

time = (dt:dt:T); % time set
Binomial_Random_Draws = -1 + 2*(rand(length(time),Number_of_Sample_Paths) > 0.5); % binomal of 1,-1 with equal probability
dW = sqrt(dt)*Binomial_Random_Draws;

Initial_Log_Stock_Price = log(S)*ones(1,Number_of_Sample_Paths);
Stock_Price_Diff = (r-0.5*(sigma^2))*dt*ones( length(time),Number_of_Sample_Paths ) ... % drift term approximation
                           + sigma*dW ; % Brownian term approximation
    
ix = [Initial_Log_Stock_Price; Stock_Price_Diff]; % first row is log(S_0) and the rest is d(log(S_t))
Log_Stock_Price = cumsum(ix);
Stock_Price = exp(Log_Stock_Price);

S_max = max(Stock_Price); % max price
Realized_Payoff = max( S_max - K , 0 );
Expected_Payoff_Under_Q = mean(Realized_Payoff,2); % averaging for each row
Call_Price = exp(-r*T)*Expected_Payoff_Under_Q

%% 2
S_T = nan(1, Number_of_Sample_Paths);
for i = 1:Number_of_Sample_Paths
    ix = find(Stock_Price(:,i) >= 110, 1, 'first');
    if ~isempty(ix)
        Realized_Payoff(i) = mean(Stock_Price(1:ix, i))*exp(-r*ix(1)*dt);
    else
        Realized_Payoff(i) = mean(Stock_Price(:,i))*exp(-r*T);
    end
end
Call_Price = mean(Realized_Payoff,2) % averaging for each row
