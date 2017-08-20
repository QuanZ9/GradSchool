clc;
clear all;
close all;

%% 1
mu = 0.05;
vol = 0.25;
r = 0.03;
S0 = 1000;
K_call = 1200;
T_call = 1;
K_put = 1600;
T_put = 3;

[call_delta, ~] = blsdelta(S0, K_call, r, T_call, vol);
[~,put_delta] = blsdelta(S0, K_put, r, T_put, vol);
call_gamma = blsgamma(S0, K_call, r, T_call, vol);
put_gamma = blsgamma(S0, K_put, r, T_put, vol);

[call_price,~] = blsprice(S0, K_call, r, T_call, vol);
[~,put_price] = blsprice(S0, K_put, r, T_put, vol);

% shares = [stock_shares, call_shares, put_shares]
shares = ([S0 call_price put_price; 
           1 call_delta put_delta; 
           0 call_gamma put_gamma; ] \ [0;-2000; -2])';
% plots
St = 500:50:1500;
CP = St.^2;
plot(St, CP);
hold on;
[new_call_price,~] = blsprice(St, K_call, r, T_call, vol);
[~,new_put_price] = blsprice(St, K_put, r, T_put, vol);
prices = [St' new_call_price' new_put_price'];
portfolio = CP' + prices * shares';
plot(St,portfolio)
legend('compensation', 'hedged portfolio')

%% 2
mu = 0.05;
vol = 0.25;
r = 0.03;
T = 0.5;
S0 = 100;
K = S0 * exp(vol * sqrt(T) * (-2:0.1:5));

payoff_now = max(K - S0, 0);

Number_of_Intervals = 500;
dt = 1/Number_of_Intervals; 
time = (0:dt:T); % time set
Km = (K *ones(length(K),length(time)))';
Stock_Price = nan(length(time),length(time)); 

Stock_Price(1,1) = S0;

for t = 2:length(time)
   Stock_Price(1:t-1,t) = Stock_Price(1:t-1,t-1)*exp( (r-0.5*(vol^2))*dt + vol * sqrt(dt) ); 
   Stock_Price(t,t) =  Stock_Price(t-1,t-1)*exp( (r-0.5*(vol^2))*dt - vol * sqrt(dt) );
end

% Backward Induction
American_Put_Price = nan(1, length(K));
for i = 1:length(K)
    American_Put_Value = nan(length(time),length(time));
    American_Put_Value(:,end) = max( K(i) - Stock_Price(:,end) , 0 )';
    for t = (length(time)-1):-1:1
        American_Put_Value(1:t,t) = max (K(i) - Stock_Price(1:t,t) , ...
            exp(-r*dt)*( 0.5* American_Put_Value(1:t,t+1) +  0.5* American_Put_Value(2:t+1,t+1) ) );
    end
    American_Put_Price(i) = American_Put_Value(1,1);
end
K_star = K(find(American_Put_Price <= payoff_now, 1, 'first'));