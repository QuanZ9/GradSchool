function Gaps = Implied_Volatilty_Distance_Heston( parameters_to_be_estimated , parameters_plugged , Moneyness , Time_to_Maturity , Implied_Volatility_Observed , ...
    dW_1 , dW_2, Number_of_Periods_Over_UnitTime , Number_of_SamplePaths )


sigma = 0.2 + 0.2*exp(parameters_to_be_estimated(1))/(1+exp(parameters_to_be_estimated(1)));
sigma
xi = 0.8 + 0.2*exp(parameters_to_be_estimated(2))/(1+exp(parameters_to_be_estimated(2))); 
xi

r = parameters_plugged(1);       % risk free return
S_0 = parameters_plugged(2);     % today's price is normalized to be 100
v_0 = parameters_plugged(3);
T = parameters_plugged(4); 
rho = parameters_plugged(5);
kappa = parameters_plugged(6);
% 
dt = 1/Number_of_Periods_Over_UnitTime;
Time = (dt:dt:T);

Heston_Price = nan( length(Moneyness),length(Time_to_Maturity) );

% simulating independent Brownian


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

Heston_Price(:,:) = Temp_Keep_Heston_Price;


Heston_Price_Average = Heston_Price;
Implied_Volatility_Matrix_Constructed = nan(length(Moneyness),length(Time_to_Maturity));

for k = 1:length(Moneyness)
    
    for t = 1:length(Time_to_Maturity)
        
        T = Time_to_Maturity(t);
        K = S_0*exp(Moneyness(k)*sigma*sqrt(T));
               
        imp_vol = blsimpv( S_0, K, r, T, Heston_Price_Average(k,t) , .8, 0, [], {'Put'});
        Implied_Volatility_Matrix_Constructed(k,t) = imp_vol;       
        
    end
    
end

Gaps = sum(sum( abs(Implied_Volatility_Matrix_Constructed - Implied_Volatility_Observed) ));
Gaps
end
