%% 1
Number_of_Sample_Paths = 10000; % As this value goes to infinity, binomial converges to brownian 
Number_of_Intervals_Over_Unit_Time = 1000; % As this value goes to infinity, binomial converges to brownian 
dt = 1/Number_of_Intervals_Over_Unit_Time; 

sigma = 0.2; % volatility of the underlying asset
r = 0.03; % risk free return
mu = 0.05; % risk free return
T = 2; % time to maturity
S = 100; % price of the underlying asset 
K = 120;

time = (dt:dt:T); % time set
Binomial_Random_Draws = -1 + 2*(rand(length(time),Number_of_Sample_Paths) > 0.5); % binomal of 1,-1 with equal probability
dW = sqrt(dt)*Binomial_Random_Draws;

N_Simulation = 10000;

Number_of_Intervals_Choice = 250; % we split 1 year into multiple periods in this vector
Expected_Payoff_Under_Q = nan(length(Number_of_Intervals_Choice),1); % We want to check the simulation pricing converges to BS pricing
Call_Price = nan(length(Number_of_Intervals_Choice),1); % We want to check the simulation pricing converges to BS pricing

for i = 1:length(Number_of_Intervals_Choice)
    Initial_Log_Stock_Price = log(S)*ones(1,N_Simulation);
    Log_Stock_Price_Diff = (r-0.5*(sigma^2))*dt*ones( length(time),N_Simulation ) ... % drift term approximation
                           + sigma*dW ; % Brownian term approximation
    
    temp = [Initial_Log_Stock_Price; Log_Stock_Price_Diff]; % first row is log(S_0) and the rest is d(log(S_t))
    Log_Stock_Price = cumsum(temp);
    Stock_Price = exp(Log_Stock_Price);
    
    S_T = Stock_Price(end,:); % last row
    Realized_Payoff = max( S_T - K , 0 );
    Expected_Payoff_Under_Q(i) = mean(Realized_Payoff,2); % averaging for each row
    Call_Price(i) = exp(-r*T)*Expected_Payoff_Under_Q(i);
end
Call_Price


%% 2
Expected_Payoff_Under_Q = nan(length(Number_of_Intervals_Choice),1); % We want to check the simulation pricing converges to BS pricing
Call_Price = nan(length(Number_of_Intervals_Choice),1); % We want to check the simulation pricing converges to BS pricing
dW = normrnd(0, sqrt(dt), [length(time),Number_of_Sample_Paths]);
for i = 1:length(Number_of_Intervals_Choice)
    Initial_Log_Stock_Price = log(S)*ones(1,N_Simulation);
    Log_Stock_Price_Diff = (r-0.5*(sigma^2))*dt*ones( length(time),N_Simulation ) ... % drift term approximation
                           + sigma*dW ; % Brownian term approximation
    
    temp = [Initial_Log_Stock_Price; Log_Stock_Price_Diff]; % first row is log(S_0) and the rest is d(log(S_t))
    Log_Stock_Price = cumsum(temp);
    Stock_Price = exp(Log_Stock_Price);
    
    S_T = Stock_Price(end,:); % last row
    Realized_Payoff = max( S_T - K , 0 );
    Expected_Payoff_Under_Q(i) = mean(Realized_Payoff,2); % averaging for each row
    Call_Price(i) = exp(-r*T)*Expected_Payoff_Under_Q(i);
end
Call_Price

%% 3 
[BS_CALL_PRICE] = blsprice(S,K,r,T,sigma,0)