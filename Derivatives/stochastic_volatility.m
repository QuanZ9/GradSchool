clc
clear all
close all

S_0 = 100;
v_0 = 0.3^2;
rho = -0.3;
K = 100;
T = 1;
r = 0.03;
kappa = 10;
xi = 0.9;
sigma = 0.3;

dt = 1/1000;
time = dt:dt:T;
N = 10000;
dW_1 = sqrt(dt)*randn(length(time), N);
dW_2 = sqrt(dt)*randn(length(time), N);

dW_S = dW_1;
dW_V = rho*dW_1 + sqrt(1-rho^2)*dW_2;

Volatility_Process = nan(length(time)+1, N);
Volatility_Process(1,:)=v_0*ones(1,N);

for t=1:length(time)  % from time 0 to T-dt
    v_t = Volatility_Process(t,:);
    if (min(v_t) < 0)
        t, min(v_t)
        pause;
    end
    dv_t = kappa*(sigma^2 - v_t)*dt + xi*sqrt(v_t).*dW_V(t,:);
    Volatility_Process(t+1,:) = v_t + dv_t;
end

% plot(Volatility_Process(:, 1:2))

V = Volatility_Process(1:end-1,:);
dlogS = (r-0.5*V)*dt + sqrt(V) .* dW_S;

Augmented = [log(S_0) * ones(1,N)
            dlogS];
logS = cumsum(Augmented);
S = exp(logS);
S_T = S(end, :);

Call_Payoff = max( S_T - K, 0);
Call_Price = exp(-r*T) * mean(Call_Payoff);