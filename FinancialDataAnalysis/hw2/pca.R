# pca
data.full <- read.csv("E:\\a-study\\QCF\\2016Spring\\FinancialDataAnalysis\\hw2\\d_logret_12stocks.txt", header = T, sep = '\t')
names(data.full)[names(data.full) == "X."] <- "DATE"
data <- data.full
data[1] <- NULL
head(data)
round(cor(data), 2)

data.pca <- prcomp(data, center = TRUE, scale. = TRUE)
summary(data.pca)
biplot(data.pca)

print(eigen(cov(data)))


