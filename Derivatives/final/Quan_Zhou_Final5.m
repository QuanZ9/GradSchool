clc
clear all
close all

S_0 = 1000;
T = 2;
% compensation is a call option with K=900, T=2
Compensation_Delta = 0.8*1000;
Compensation_Gamma = 0.1*1000;


% use stock, Call(T=1) and Put(T=3) to hedge the risk
Call_Price = 30;
Call_Delta = 0.1;
Call_Gamma = 0.3;
Put_Price = 100;
Put_Delta = -0.9;
Put_Gamma = 0.2;

% b = [initial value; portfolio delta; portfolio gamma]
b = [0; -Compensation_Delta; -Compensation_Gamma];

A = [S_0 Call_Price Put_Price;
     1 Call_Delta Put_Delta;
     0 Call_Gamma Put_Gamma];
% shares = [stock_shares call_shares put_shares]
shares = A\b;