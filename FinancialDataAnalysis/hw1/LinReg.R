# read data
data.full <- read.csv("E:\\a-study\\QCF\\2016Spring\\FinancialDataAnalysis\\hw1\\w_logret_3automanu.csv", header = FALSE)
data.full <- data.full * 100

# summary
summary(data.full)

# linear regression on the entire dataset
lm.full <-lm(V3~V1+V2, data = data.full)
summary(lm.full)
par(mfrow=c(2,2))	
plot(lm.full, which=c(1:4))

#remove outliers
data.sub <- data.full[c(-311, -334, -402, -644),]
lm.sub <- lm(V3~V1+V2, data = data.sub)
summary(lm.sub)
par(mfrow=c(2,2))
plot(lm.sub, which=c(1:4))


# linear regression between GM and FORD
lm.ford <- lm(V3~V2, data = data.sub)
summary(lm.ford)
par(mfrow=c(2,2))
plot(lm.ford, which=c(1:4))
