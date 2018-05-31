################## IMPORT NEEDED LIBRARIES ###########################################
library(quantmod)
library(zoo)
library(ggplot2)
library(FinTS)
library(e1071)
library(tseries)
library(forecast)
library(rugarch)

########## LOADING OF DATASET #######################################################
df <- read.csv.zoo("master_dataset.csv")

ethereum_df <- df$ethereum

########### CALCULATION OF LOGARITHMIC RETURNS AS PERCENTAGE ##########################
ethereum_returns <- log(ethereum_df / lag(ethereum_df,-1)) * 100

#ethereum_returns_num <- coredata(ethereum_returns)


# GGPLOT Daily Returns
ggplot(data = ethereum_returns, mapping = aes(index(ethereum_returns), 
                                             coredata(ethereum_returns))) + 
  geom_line() +
  labs(title = "Daily Returns of ethereum",
       x = "Year", 
       y = "Daily Returns (%)") + 
  theme(plot.title = element_text(hjust = 0.5))

# Save Daily Returns plot
ggsave("Daily Returns of ethereum.png")

# GGPLOT Daily Returns Squared
ggplot(data = ethereum_returns, mapping = aes(index(ethereum_returns), 
                                             coredata(ethereum_returns)^2)) + 
  geom_line() +
  labs(title = "Daily Logarithmic Returns of ethereum",
       x = "Year", 
       y = "Daily Returns (%)") + 
  theme(plot.title = element_text(hjust = 0.5))

# Save Squared Daily Returns plot
ggsave("Daily Returns Squared of ethereum.png")

# GGPLOT Distribution of Daily Returns
ggplot(data = ethereum_returns, mapping = aes(x = coredata(ethereum_returns))) + 
  geom_histogram(fill = "black") +
  labs(title = "Distribution of ethereum Daily Returns",
       x = "Daily Return Values (%)", 
       y = "Frequency") + 
  theme(plot.title = element_text(hjust = 0.5))

# Save Histogram of Daily Returns
ggsave("Distribution of ethereum Daily Returns.png")

############ STATISTICAL PRETESTING OF DATASET FOR GARCH MODELLING SUITABILITY ###########

## 1 Statistical Summary

ethereum_ret_summary <- fBasics::basicStats(ethereum_returns, ci = 0.95)
ethereum_ret_summary <- as.data.frame(ethereum_ret_summary)

# Save Summary
write.csv(ethereum_ret_summary, "ethereum_Ret_Summary.csv")

## 2. Jarque-Bera test
capture.output(tseries::jarque.bera.test(ethereum_returns), 
               file = "ethereum_JB_Test.txt")


## 5. The ARCH test 
capture.output(FinTS::ArchTest(ethereum_returns, lags = 1), 
               file = "ethereum_ARCH1_Test.txt")

capture.output(FinTS::ArchTest(ethereum_returns, lags = 5), 
               file = "ethereum_ARCH5_Test.txt")

capture.output(FinTS::ArchTest(ethereum_returns, lags = 12), 
               file = "ethereum_ARCH12_Test.txt")

## 6. ADF test
capture.output(tseries::adf.test(ethereum_returns),
               file = "ethereum_ADF_Test.txt")


## 7. LB-2(12)  Ljung–Box test statistic for serial correlation on the squared residuals with 12 lags respectively
capture.output(Box.test (ethereum_returns, lag = 12, type = "Ljung-Box"),
               file = "ethereum_LB12_Test.txt")

capture.output(Box.test (ethereum_returns^2, lag = 12, type = "Ljung-Box"),
               file = "ethereum_LB12_Squared_Test.txt")




############################# MEAN MODEL ##########################################
# Get the best ARIMA model for the mean modelling of the GARCH model
capture.output(forecast::auto.arima(ethereum_returns, trace = TRUE,
                                    test = "kpss", ic = c("bic")),
               file = "ethereum_Best_ARMAorder.txt")

############################# SPECIFY GARCH MODEL #########################################
model_spec <- rugarch::ugarchspec(variance.model = list(model = "sGARCH",
                                                        garchOrder = c(1,1)),
                                  mean.model = list(armaOrder = c(2,0)), 
                                  distribution.model = "std")


############################# FIT GJR-GARCH MODEL #############################################
model_fit <- rugarch::ugarchfit(spec =  model_spec, data = ethereum_returns)

capture.output(model_fit, file = "ethereum_sGARCH_Model_Summary.txt")

#plot(model_fit, which="all")


#mean: mu
#constant: omega
#ARCH term: alpha1
#GARCH term: beta1
#Gamma: gamma1
# Indicator function?

############################## BACKTESTING OF MODEL##################################
model_roll <- rugarch::ugarchroll(spec = model_spec, data = ethereum_returns,
                                  n.ahead = 1,
                                  n.start = 150, refit.every = 30, 
                                  refit.window = "recursive"
                                  )


# save backtesting results
capture.output(report(model_roll, type = "VaR", VaR.alpha = 0.01, conf.level = 0.99),
               file = "ethereum_BackestConf99_results.txt")

capture.output(report(model_roll, type = "VaR", VaR.alpha = 0.01, conf.level = 0.975),
               file = "ethereum_BackestConf975_results.txt")

capture.output(report(model_roll, type = "VaR", VaR.alpha = 0.01, conf.level = 0.95),
               file = "ethereum_BackestConf95_results.txt")

# Success/Fail Ratio - Expected Exceed / Actual Exceed
# Unconditional Coverage - Proportion Of Failure (POF) Kupiece Test p-value
# Conditional Coverage - Christoffersen Test p-value

############################# BOOTSTRAPPING ##############################
standadized_residuals <- model_fit@fit$residuals / model_fit@fit$sigma

capture.output(Box.test (standadized_residuals, lag = 12, type = "Ljung-Box"),
               file = "standardized_LB12_Test.txt")

capture.output(Box.test (standadized_residuals^2, lag = 12, type = "Ljung-Box"),
               file = "standardized_LB12_Squared_Test.txt")

standadized_residuals <- standadized_residuals[2:997]

set.seed(123)
myz <- matrix(sample(standadized_residuals, size = 1000000, replace = TRUE), nrow = 10)

sim1<- ugarchsim(model_fit, n.sim = 10, m.sim = 100000, startMethod = "sample", 
                 custom.dist = list(name = "sample", distfit = myz, type = "myz"),
                 rseed = 10)

sims <- sim1@simulation$seriesSim

hypo_rets <- colSums(sims)

VaR_010 <- quantile(hypo_rets, p = 0.10)
ES_010 <- mean(hypo_rets[hypo_rets < VaR_010])

VaR_005 <- quantile(hypo_rets, p = 0.05)
ES_005 <- mean(hypo_rets[hypo_rets < VaR_005])

VaR_025 <- quantile(hypo_rets, p = 0.025)
ES_025 <- mean(hypo_rets[hypo_rets < VaR_025])

VaR_001 <- quantile(hypo_rets, p = 0.01)
ES_001 <- mean(hypo_rets[hypo_rets < VaR_001])

############################ VAR AND ES ESTIMATES ###################################

write(VaR_010, file = "VaR_01.txt")
write(ES_010, file = "ES_010.txt")

write(VaR_005, file = "VaR_005.txt")
write(ES_005, file = "ES_005.txt")

write(VaR_025, file = "VaR_025.txt")
write(ES_025, file = "ES_025.txt")

write(VaR_001, file = "VaR_001.txt")
write(ES_001, file = "ES_001.txt")
