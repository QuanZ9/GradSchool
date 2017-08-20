library(nFactors)

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

# factor analysis without rotation
for (i in 1:10){
	fa <- factanal(stock_ex, i, rotation="none")
	print(fa)
}

#factor analysis with rotation
for (i in 1:10){
	fa.rotate <- factanal(stock_ex, i, rotation="varimax")
	print(fa.rotate)
}

fa<- factanal(stock_ex, 3, rotation="none")
print(fa)
fa.rotate <- factanal(stock_ex, 3, rotation="varimax")
print(fa.rotate)

# scree test
ev <- eigen(cor(stock_ex)) # get eigenvalues
ap <- parallel(subject=nrow(stock_ex),var=ncol(stock_ex),
  rep=100,cent=.05)
nS <- nScree(x=ev$values, aparallel=ap$eigen$qevpea)
plotnScree(nS)

###############################################################
# model validation
idx <- seq(1,156)
idx.t0 <- 86
data.before <- mkt$ex_logret*I(idx < idx.t0)

for (i in 1:10){
	data.test <- cbind(stock_ex[i], data.before, mkt$ex_logret)
	linreg <- lm(data.test[,1] ~ data.test[,2] + data.test[,3])
	print(summary(linreg))
}

# find optimal t0
for (i in 1:10){
   	minError <- 999999
   	for (j in 1:156){
		data.before <- mkt$ex_logret*I(idx < j)
		data.after <- mkt$ex_logret*I(idx >= j)
      	data.test <- cbind(stock_ex[i], data.before, data.after)
      	linreg <- lm(data.test[,1] ~ data.test[,2] + data.test[,3])

		error <- sum((linreg$residuals)^2)
		if (error < minError){
          		minError <- error
          		t0 <- j
		}
   	}
	print(t0)
}	