% Dynamic hedging
clc
close all
clear all

mu = 0.05;
vol = 0.25;
r = 0.03;
T = 2;
S0 = 1000;
Days_Per_Year = 250;
dt = 1 / Days_Per_Year;

%% 1 Price Decomposition
K_star = exp(r*T)*S0;
Bond_Price = exp(-r*T)*K_star.^2;
Futures_Price = 0;

dK = 100;
From_K_star_to_a_large_number = (K_star:dK:5*K_star);
[Call_Price, ~] = blsprice(S0, From_K_star_to_a_large_number, r, T, vol, 0);
Call_portion = sum( 2 .* Call_Price * dK);

From_a_small_number_to_K_star = (dK:dK:K_star);
[~, Put_Price] = blsprice(S0, From_a_small_number_to_K_star, r, T, vol, 0);
Put_portion = sum( 2 .* Put_Price * dK);

Price_decompostition = Bond_Price + Futures_Price + Call_portion + Put_portion

%% 2
Call_K = 1200;
Put_K = 1600;
Call_T = 1;
Put_T = 3;
subT = 0.5;
Time = 0:dt:subT;

% generate stock price
dW = sqrt(dt)*randn(length(Time)-1, 1); 
Initial_Stock_Price = log(S0);
Log_Stcok_Price_Diff = ( r - 0.5*(vol^2) )*dt*ones(length(Time)-1, 1) ... % drift term
                       + vol*dW;
temp = [Initial_Stock_Price; Log_Stcok_Price_Diff]; % first row is log(S_0) and the rest is d(log(S_t))
Log_Stock_Price = cumsum(temp);
Stock_Price = exp(Log_Stock_Price);

Call_Time_To_Maturity = (Call_T - Time)';
Put_Time_To_Maturity = (Put_T - Time)';
% call and put price over time
[Call_Price, ~] = blsprice(Stock_Price, Call_K, r, Call_Time_To_Maturity, vol);
[~, Put_Price] = blsprice(Stock_Price, Put_K, r, Put_Time_To_Maturity, vol);
% call and put delta over time
[Call_Delta, ~] = blsdelta(Stock_Price, Call_K, r, Call_Time_To_Maturity, vol);
[~, Put_Delta] = blsdelta(Stock_Price, Put_K, r, Put_Time_To_Maturity, vol);
% call and put gamma over time
Call_Gamma = blsgamma(Stock_Price, Call_K, r, Call_Time_To_Maturity, vol);
Put_Gamma = blsgamma(Stock_Price, Put_K, r, Put_Time_To_Maturity, vol);

i = 1;
% compute compensation price, delta and gamma over time
for t = 0:dt:subT
    Spot_Stock_Price = Stock_Price(i);
    % cash flow decomposition
    K_star = exp(r*(T-t)) * Spot_Stock_Price;
    bond_price = exp(-r*(T-t))*(K_star.^2);
    bond_delta = 0;
    bond_gamma = 0;
    futures_price = 0;
    futures_delta = 2 * K_star;
    futures_gamma = 0;
    dK = 1;
    % call portion 
    From_K_star_to_a_large_number = (K_star:dK:5*K_star);
    [C_Price, ~] = blsprice(Spot_Stock_Price, From_K_star_to_a_large_number, r, T-t, vol, 0);
    [C_delta, ~] = blsdelta(Spot_Stock_Price, From_K_star_to_a_large_number, r, T-t, vol, 0);
    C_gamma = blsgamma(Spot_Stock_Price, From_K_star_to_a_large_number, r, T-t, vol, 0);
    C_portion = sum( 2 .* C_Price * dK);
    C_portion_delta = sum( 2 .* C_delta * dK);
    C_portion_gamma = sum( 2 .* C_gamma * dK);
    % put portion
    From_a_small_number_to_K_star = (dK:dK:K_star);
    [~, P_Price] = blsprice(Spot_Stock_Price, From_a_small_number_to_K_star, r, T-t, vol, 0);
    [~, P_delta] = blsdelta(Spot_Stock_Price, From_a_small_number_to_K_star, r, T-t, vol, 0);
    P_gamma = blsgamma(Spot_Stock_Price, From_a_small_number_to_K_star, r, T-t, vol, 0);
    P_portion = sum( 2 .* P_Price * dK);
    P_portion_delta = sum( 2 .* P_delta * dK);
    P_portion_gamma = sum( 2 .* P_gamma * dK);
    % compasation price, delta and gamma
    Compensation_Price(i) = bond_price + futures_price + C_portion + P_portion;
    Compensation_Delta(i) = bond_delta + futures_delta + C_portion_delta + P_portion_delta;
    Compensation_Gamma(i) = bond_gamma + futures_gamma + C_portion_gamma + P_portion_gamma;
    i = i + 1;
end

i = 1;
% hedging portfolio
port_value(1) = 0;
for t = 0:dt:(subT-dt)
    Spot_Stock_Price = Stock_Price(i);
    % call option in hedging portfolio
    spot_call_price = Call_Price(i);
    spot_call_delta = Call_Delta(i);
    spot_call_gamma = Call_Gamma(i);
    % put option in hedging portfolio
    spot_put_price = Put_Price(i);
    spot_put_delta = Put_Delta(i);
    spot_put_gamma = Put_Gamma(i);
    % shares = [stock_shares, call_shares, put_shares]
    A = [Spot_Stock_Price  spot_call_price  spot_put_price;
               1           spot_call_delta  spot_put_delta;
               0           spot_call_gamma  spot_put_gamma;];
    B = [port_value(i);
        -Compensation_Delta(i);
        -Compensation_Gamma(i)];
    shares = (A \ B)';
    port_value(i+1) = [Stock_Price(i+1) Call_Price(i+1) Put_Price(i+1)] * shares';
    i = i + 1;
end

plot(Time, port_value + Compensation_Price)