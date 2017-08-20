clc
clear all
close all

%% Implied Volatility Surface from Black Scholes Model

% Parameters for call option

sigma = 0.25;   % volatility of the underlying asset
r = 0.03;       % risk free return
S_0 = 100;     % today's price is normalized to be 100

Moneyness = (-2:.2:1);
Time_to_Maturity = (0.1:0.2:2);

Implied_Volatility_Matrix = nan(length(Moneyness),length(Time_to_Maturity));

for k = 1:length(Moneyness)
    
    for t = 1:length(Time_to_Maturity)        
       
        T = Time_to_Maturity(t);
        K = S_0*exp(Moneyness(k)*sigma*sqrt(T));
        
        [call_price, not_used] = blsprice( S_0, K, r, T, sigma, 0);
        imp_vol = blsimpv( S_0, K, r, T, call_price, .5, 0, [], {'Call'});
        Implied_Volatility_Matrix(k,t) = imp_vol;       
        
    end
    
end

figure(1)
surf(Time_to_Maturity,Moneyness,Implied_Volatility_Matrix)
axis([ Time_to_Maturity(1) Time_to_Maturity(end) Moneyness(1) Moneyness(end) 0 0.5])
xlabel('Time to Maturity')
ylabel('Moneyness')
zlabel('Implied Volatility')
title('BS Model Implied Volatility')

%% Heston Model Pricing
% parameters in Q of Heston model

sigma = 0.30;   % long run volatility in Q
r = 0.03;       % risk free return
S_0 = 100;     % today's price is normalized to be 100
parallel_flag = 0;

% Similar parameters to his original paper : Look page 336 of RFS(1993)
v_0 = 0.30^2; % todays volatiliy in Q and P
T = 2; 
rho = -0.3; % correlation beween shock to price and shock to volatility
kappa = 10; % speed of adjustment
xi = 0.9; % volatility of volatility 

Number_of_Periods_Over_UnitTime = 1000;
dt = 1/Number_of_Periods_Over_UnitTime;
Time = (dt:dt:T);

Number_of_SamplePaths = 10000;
Number_of_OuterLoop = 10;
Heston_Price = nan( length(Moneyness),length(Time_to_Maturity),Number_of_OuterLoop );

if parallel_flag == 1
    
    
    parfor outloopi = 1:Number_of_OuterLoop

        outloopi
        % simulating independent Brownian
        temp = sqrt(dt) * (-1+2*(rand( length(Time) , 2*Number_of_SamplePaths) > 0.5));
        dW_1 = temp(:,1:Number_of_SamplePaths);
        dW_2 = temp(:,(Number_of_SamplePaths+1):2*Number_of_SamplePaths);

        dW_S = dW_1;
        dW_V = rho*dW_1 + sqrt(1-rho^2)*dW_2;

        % Volatility Process Simulation
        Volatility_Process = nan( length(Time)+1 , Number_of_SamplePaths );
        Volatility_Process(1,:) = v_0; % initializing the volatility

        for t = 1:length(Time)

            v_t = Volatility_Process(t,:);
            dv_t = kappa*( sigma^2 - v_t )*dt + xi*sqrt(v_t).*dW_V(t,:);
            Volatility_Process(t+1,:) = v_t+dv_t;

        end

        V = Volatility_Process(1:end-1,:); 
        % In computing dlog(S_0) = log(S_dt) - log(S_0) , 
        % use the information of v_0, not v_dt
        dLog_S = (r - 0.5*V)*dt + sqrt(V).*dW_S;

        % Converting dLogS into the Stock Price Process
        LogS = cumsum( [log(S_0)*ones(1,Number_of_SamplePaths);dLog_S] );
        Stock_Price_Process = exp(LogS);
        Stock_Price_Process = Stock_Price_Process(2:end,:); % first row is time dt, not time zero

        % Compute the Heston Price and Convert the price into Implied Volatility
        Temp_Keep_Heston_Price = nan(length(Moneyness),length(Time_to_Maturity));

        for k = 1:length(Moneyness)

            for t = 1:length(Time_to_Maturity)

                T = Time_to_Maturity(t);
                K = S_0*exp(Moneyness(k)*sigma*sqrt(T));
                Time_Location = round(T/dt);

                S_T = Stock_Price_Process(Time_Location,:);
                Put_Payoff = max(K - S_T,0);
                Temp_Keep_Heston_Price(k,t) = exp(-r*T)*mean(Put_Payoff,2);

            end

        end

        Heston_Price(:,:,outloopi) = Temp_Keep_Heston_Price;

    end

    
else
    
    for outloopi = 1:Number_of_OuterLoop

        outloopi
        % simulating independent Brownian
        temp = sqrt(dt) * (-1+2*(rand( length(Time) , 2*Number_of_SamplePaths) > 0.5));
        dW_1 = temp(:,1:Number_of_SamplePaths);
        dW_2 = temp(:,(Number_of_SamplePaths+1):2*Number_of_SamplePaths);

        dW_S = dW_1;
        dW_V = rho*dW_1 + sqrt(1-rho^2)*dW_2;

        % Volatility Process Simulation
        Volatility_Process = nan( length(Time)+1 , Number_of_SamplePaths );
        Volatility_Process(1,:) = v_0; % initializing the volatility

        for t = 1:length(Time)

            v_t = Volatility_Process(t,:);
            dv_t = kappa*( sigma^2 - v_t)*dt + xi*sqrt(v_t).*dW_V(t,:);

            Volatility_Process(t+1,:) = v_t+dv_t;

        end

        V = Volatility_Process(1:end-1,:); 

        dLog_S = (r - 0.5*V)*dt + sqrt(V).*dW_S;

        % Converting dLogS into the Stock Price Process
        LogS = cumsum( [log(S_0)*ones(1,Number_of_SamplePaths);dLog_S] );
        Stock_Price_Process = exp(LogS);
        Stock_Price_Process = Stock_Price_Process(2:end,:); % first row is time dt, not time zero

        % Compute the Heston Price and Convert the price into Implied Volatility
        Temp_Keep_Heston_Price = nan(length(Moneyness),length(Time_to_Maturity));

        for k = 1:length(Moneyness)

            for t = 1:length(Time_to_Maturity)

                T = Time_to_Maturity(t);
                K = S_0*exp(Moneyness(k)*sigma*sqrt(T));
                Time_Location = round(T/dt);

                S_T = Stock_Price_Process(Time_Location,:);
                Put_Payoff = max(K - S_T,0);
                Temp_Keep_Heston_Price(k,t) = exp(-r*T)*mean(Put_Payoff,2);

            end

        end

        Heston_Price(:,:,outloopi) = Temp_Keep_Heston_Price;

    end
end

Heston_Price_Average = mean(Heston_Price,3);
Implied_Volatility_Matrix_Heston = nan(length(Moneyness),length(Time_to_Maturity));

for k = 1:length(Moneyness)
    
    for t = 1:length(Time_to_Maturity)
        
        T = Time_to_Maturity(t);
        K = S_0*exp(Moneyness(k)*sigma*sqrt(T));
               
        imp_vol = blsimpv( S_0, K, r, T, Heston_Price_Average(k,t) , .8, 0, [], {'Put'});
        Implied_Volatility_Matrix_Heston(k,t) = imp_vol;       
        
    end
    
end

figure(2)
surf(Time_to_Maturity,Moneyness,Implied_Volatility_Matrix_Heston)
%axis([ Time_to_Maturity(1) Time_to_Maturity(end) Moneyness(1) Moneyness(end) 0 .8])
xlabel('Time to Maturity')
ylabel('Moneyness')
zlabel('Implied Volatility')
title('Heston Model Implied Volatility')
% keyboard
%% Model Calibration
% Estimating the parameters of the model

big = 10^10;
options = optimset('MaxFunEvals',big,'MaxIter',big); % I guess estimating nine values is burdensome. So, we need to increase the maximum number of function evaluations so that we can achieve the optimized value.

parameters_plugged = [r S_0 v_0 T rho kappa];

Number_of_Periods_Over_UnitTime = 1000;
dt = 1/Number_of_Periods_Over_UnitTime;
Time = (dt:dt:T);
Number_of_SamplePaths = 10000;

temp = sqrt(dt) * (-1+2*(rand( length(Time) , 2*Number_of_SamplePaths) > 0.5));
dW_1 = temp(:,1:Number_of_SamplePaths);
dW_2 = temp(:,(Number_of_SamplePaths+1):2*Number_of_SamplePaths);

f = @(x)Implied_Volatilty_Distance_Heston( x , parameters_plugged , Moneyness , Time_to_Maturity , Implied_Volatility_Matrix_Heston, ... 
... % Implied_Volatility_Matrix_Heston is TARGET  
    dW_1 , dW_2 , Number_of_Periods_Over_UnitTime , Number_of_SamplePaths );
initial = [0 0];
[sol,fval,exitflag,output,grad,hessian] = fminunc(f,initial,options);
sigma_hat = 0.2 + 0.2*exp(sol(1))/(1+exp(sol(1)));
xi_hat = 0.8 + 0.2 * exp(sol(2))/(1+exp(sol(2)));