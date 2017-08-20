%% 1.1
sample_size = 10^8;
a = log(normrnd(0,1,[1, sample_size]).^2);
digits(2);
E = mean(a);
sprintf('%0.5f', E)

%% 1.2
N_Max = 1000;
Number_of_Simulation = 30000;
N_under_consideration = [10 100 1000];

Uniform_Draw = rand(N_Max,Number_of_Simulation);
Binomial_Draw = 0.9 + 0.2*( Uniform_Draw > 0.5);

Sum_Binomial_Draw = cumsum( Binomial_Draw );
N = cumsum( ones(N_Max,1) );
N = N*ones(1,Number_of_Simulation);
sqrt_N = sqrt(N);

Boosted_Sample_Mean = sqrt_N .* (Sum_Binomial_Draw ./ N - 1);

figure(2)
subplot(4,1,1)
hist( Boosted_Sample_Mean( N_under_consideration(1),: ),100 );
title('N=10')
subplot(4,1,2)
hist( Boosted_Sample_Mean( N_under_consideration(2),: ),100 );
title('N=100')
subplot(4,1,3)
hist( Boosted_Sample_Mean( N_under_consideration(3),: ),100 );
title('N=1000')

%% 1.3
Number_of_Simulation = 30000;
T = [2 10 100 1000 10000];

result = zeros(length(T), length(Number_of_Simulation));
logResult = zeros(length(T), length(Number_of_Simulation));
for t=1:length(T)
    for s=1:Number_of_Simulation
        p = 1.0;
        for i=1:T(t)
            if rand() > 0.5
                p = p * exp(0.1 / sqrt(T(t)));
            else
                p = p * exp(-0.1 / sqrt(T(t)));
            end
        end
        result(t,s) = p;
        logResult(t,s) = log(p);
    end
end

figure;
subplot(3,2,1)
hist(result( 1,: ), 100);
title('ST, T=2')
subplot(3,2,2)
hist(result( 2,: ), 100);
title('ST, T=10')
subplot(3,2,3)
hist(result( 3,: ), 100);
title('ST, T=100')
subplot(3,2,4)
hist(result( 4,: ), 100);
title('ST, T=1000')
subplot(3,2,5)
hist(result( 5,: ), 100);
title('ST, T=10000')

figure;
subplot(3,2,1)
hist(logResult( 1,: ), 100);
title('log(ST), T=2')
subplot(3,2,2)
hist(logResult( 2,: ), 100);
title('log(ST), T=10')
subplot(3,2,3)
hist(logResult( 3,: ), 100);
title('log(ST), T=100')
subplot(3,2,4)
hist(logResult( 4,: ), 100);
title('log(ST), T=1000')
subplot(3,2,5)
hist(logResult( 5,: ), 100);
title('log(ST), T=10000')