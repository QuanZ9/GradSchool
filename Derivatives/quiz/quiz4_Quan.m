%% 1
% True False

%% 2
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

Call_K = 1200;
Call_T = 1;
subT = 0.5;
Time = 0:dt:subT;

% generate stock price
dW = sqrt(dt)*randn(length(Time)-1, 1); 
Initial_Stock_Price = log(S0);
Log_Stcok_Price_Diff = ( r - 0.5*(vol^2) )*dt*ones(length(Time)-1, 1) + vol * dW;
temp = [Initial_Stock_Price; Log_Stcok_Price_Diff];
Log_Stock_Price = cumsum(temp);
Stock_Price = exp(Log_Stock_Price);

Call_Time_To_Maturity = (Call_T - Time)';
% call  price over time
[Call_Price, ~] = blsprice(Stock_Price, Call_K, r, Call_Time_To_Maturity, vol);
% call delta over time
[Call_Delta, ~] = blsdelta(Stock_Price, Call_K, r, Call_Time_To_Maturity, vol);



i = 1;
% compute compensation price, delta and gamma over time
for t = 0:dt:subT
    Spot_Stock_Price = Stock_Price(i);
%     % cash flow decomposition
%     K_star = exp(r*(T-t)) * Spot_Stock_Price;
%     bond_price = exp(-r*(T-t))*(K_star - 900)*1000;
%     bond_delta = 0;
%     futures_price = 0;
%     futures_delta = 1000;
%     dK = 10;
%     % call portion 
%     From_K_star_to_a_large_number = (K_star:dK:5*K_star);
%     [C_Price, ~] = blsprice(Spot_Stock_Price, From_K_star_to_a_large_number, r, T-t, vol, 0);
%     [C_delta, ~] = blsdelta(Spot_Stock_Price, From_K_star_to_a_large_number, r, T-t, vol, 0);
%     C_portion = 0;
%     C_portion_delta = 0;
%     % put portion
%     From_a_small_number_to_K_star = (dK:dK:K_star);
%     [~, P_Price] = blsprice(Spot_Stock_Price, From_a_small_number_to_K_star, r, T-t, vol, 0);
%     [~, P_delta] = blsdelta(Spot_Stock_Price, From_a_small_number_to_K_star, r, T-t, vol, 0);
%     P_portion = 0;
%     P_portion_delta = 0;
%     % compasation price, delta and gamma
% %     Compensation_Price(i) = bond_price + futures_price + C_portion + P_portion;
% %     Compensation_Delta(i) = bond_delta + futures_delta + C_portion_delta + P_portion_delta;
    [Compensation_Price(i),~] = blsprice(Spot_Stock_Price, 900, r, T-t, vol);
    [Compensation_Delta(i),~] = blsdelta(Spot_Stock_Price, 900, r, T-t, vol);
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
    % shares = [stock_shares, call_shares]
    A = [Spot_Stock_Price  spot_call_price;
               1           spot_call_delta;];
    B = [port_value(i);
        -Compensation_Delta(i) * 1000;];
    shares = (A \ B)';
    port_value(i+1) = [Stock_Price(i+1) Call_Price(i+1)] * shares';
    i = i + 1;
end

plot(Time, port_value + Compensation_Price * 1000)