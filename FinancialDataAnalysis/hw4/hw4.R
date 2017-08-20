# compute market excess log return
mkt <- read.csv("E:\\a-study\\QCF\\2016Spring\\FinancialDataAnalysis\\hw3\\m_sp500ret_3mtcm.txt", header = T, sep = '\t', skip = 1)
mkt$log_rf <- log(mkt$X3mTCM/100 + 1)/12
mkt$ex_logret <- log(mkt$sp500+1) - mkt$log_rf
mkt <- subset(mkt, select=c("Date", "ex_logret", "log_rf"))

# compute stock excess log return
stock <- read.csv("E:\\a-study\\QCF\\2016Spring\\FinancialDataAnalysis\\hw3\\m_logret_10stocks.txt", header = T, sep = '\t')
stock$Date <- NULL
stock = na.omit(stock)
stock_ex = stock - mkt$log_rf

alphas <- c()
betas <- c()
betas1 <- c()
ci <- c()

for (i in 1:10){
	# regression
	linreg <- lm(stock_ex[,i] ~ mkt$ex_logret)
	alphas <- c(alphas, linreg$coefficients[1])
	betas <- c(betas, linreg$coefficients[2])	
	#print(summary(linreg))
	
	# confidence interval
	interval.beta <- confint(linreg, level=0.95)
	#print (interval.beta)
	ci <- cbind(ci, interval.beta)

	# regression without intercept
	linreg <- lm(stock_ex[,i] ~ mkt$ex_logret - 1)
	betas1 <- c(betas1, linreg$coefficients[1])
}

# bootstrap
bootcapm<-function(x,y,B=500){
	ind<-seq(1,length(x))
	bootCoeff<-matrix(0,B,3)
	for(b in 1:B){
		bootind<-sample(ind,replace=T)
		yb<-y[bootind]
		xb<-x[bootind]
		fitb<-lm(yb~xb)
		bootCoeff[b,]<-c(fitb$coef,mean(yb)/sd(yb))
	}
	return(bootCoeff)
}

alphas <- c()
betas <- c()
ci_alpha <- c()
ci_beta <- c()
std_alpha <- c()
std_beta <- c()

set.seed(12345)
for (i in 1:10){
	boot <- bootcapm(mkt$ex_logret, stock_ex[,i], 1000)
	alphas <- c(alphas, mean(boot[,1]))
	betas <- c(betas, mean(boot[,2]))
	ci_alpha <- c(ci_alpha, quantile(boot[,1], c(0.005, 0.995)))
	ci_beta <- c(ci_beta, quantile(boot[,2], c(0.005, 0.995)))
	std_alpha <- c(std_alpha, sd(boot[,1]))
	std_beta <- c(std_beta, sd(boot[,2]))
}
