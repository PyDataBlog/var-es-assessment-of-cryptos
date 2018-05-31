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

monero_df <- df$monero

########### CALCULATION OF LOGARITHMIC RETURNS AS PERCENTAGE ##########################
monero_returns <- log(monero_df / lag(monero_df,-1)) * 100

#monero_returns_num <- coredata(monero_returns)


# GGPLOT Daily Returns
ggplot(data = monero_returns, mapping = aes(index(monero_returns), 
                                              coredata(monero_returns))) + 
  geom_line() +
  labs(title = "Daily Returns of monero",
       x = "Year", 
       y = "Daily Returns (%)") + 
  theme(plot.title = element_text(hjust = 0.5))

# Save Daily Returns plot
ggsave("Daily Returns of monero.png")

# GGPLOT Daily Returns Squared
ggplot(data = monero_returns, mapping = aes(index(monero_returns), 
                                              coredata(monero_returns)^2)) + 
  geom_line() +
  labs(title = "Daily Logarithmic Returns of monero",
       x = "Year", 
       y = "Daily Returns (%)") + 
  theme(plot.title = element_text(hjust = 0.5))

# Save Squared Daily Returns plot
ggsave("Daily Returns Squared of monero.png")

# GGPLOT Distribution of Daily Returns
ggplot(data = monero_returns, mapping = aes(x = coredata(monero_returns))) + 
  geom_histogram(fill = "black") +
  labs(title = "Distribution of monero Daily Returns",
       x = "Daily Return Values (%)", 
       y = "Frequency") + 
  theme(plot.title = element_text(hjust = 0.5))

# Save Histogram of Daily Returns
ggsave("Distribution of monero Daily Returns.png")

############ STATISTICAL PRETESTING OF DATASET FOR GARCH MODELLING SUITABILITY ###########

## 1 Statistical Summary

monero_ret_summary <- fBasics::basicStats(monero_returns, ci = 0.95)
monero_ret_summary <- as.data.frame(monero_ret_summary)

# Save Summary
write.csv(monero_ret_summary, "monero_Ret_Summary.csv")

## 2. Jarque-Bera test
capture.output(tseries::jarque.bera.test(monero_returns), 
               file = "monero_JB_Test.txt")


## 5. The ARCH test 
capture.output(FinTS::ArchTest(monero_returns, lags = 1), 
               file = "monero_ARCH1_Test.txt")

capture.output(FinTS::ArchTest(monero_returns, lags = 5), 
               file = "monero_ARCH5_Test.txt")

capture.output(FinTS::ArchTest(monero_returns, lags = 12), 
               file = "monero_ARCH12_Test.txt")

## 6. ADF test
capture.output(tseries::adf.test(monero_returns),
               file = "monero_ADF_Test.txt")


## 7. LB-2(12)  Ljung–Box test statistic for serial correlation on the squared residuals with 12 lags respectively
capture.output(Box.test (monero_returns, lag = 12, type = "Ljung-Box"),
               file = "monero_LB12_Test.txt")

capture.output(Box.test (monero_returns^2, lag = 12, type = "Ljung-Box"),
               file = "monero_LB12_Squared_Test.txt")




############################# MEAN MODEL ##########################################
# Get the best ARIMA model for the mean modelling of the GARCH model
capture.output(forecast::auto.arima(monero_returns, trace = TRUE,
                                    test = "kpss", ic = c("bic")),
               file = "monero_Best_ARMAorder.txt")

############################# SPECIFY GARCH MODEL #########################################
model_spec <- rugarch::ugarchspec(variance.model = list(model = "gjrGARCH",
                                                        garchOrder = c(1,1)),
                                  mean.model = list(armaOrder = c(2,0)), 
                                  distribution.model = "std")


############################# FIT GJR-GARCH MODEL #############################################
model_fit <- rugarch::ugarchfit(spec =  model_spec, data = monero_returns)

capture.output(model_fit, file = "monero_sGARCH_Model_Summary.txt")

#plot(model_fit, which="all")


#mean: mu
#constant: omega
#ARCH term: alpha1
#GARCH term: beta1
#Gamma: gamma1
# Indicator function?

############################## BACKTESTING OF MODEL##################################
model_roll <- rugarch::ugarchroll(spec = model_spec, data = monero_returns,
                                  n.ahead = 1,
                                  n.start = 150, refit.every = 30, 
                                  refit.window = "recursive"
                                  )


# save backtesting results
capture.output(report(model_roll, type = "VaR", VaR.alpha = 0.01, conf.level = 0.99),
               file = "monero_BackestConf99_results.txt")

capture.output(report(model_roll, type = "VaR", VaR.alpha = 0.01, conf.level = 0.975),
               file = "monero_BackestConf975_results.txt")

capture.output(report(model_roll, type = "VaR", VaR.alpha = 0.01, conf.level = 0.95),
               file = "monero_BackestConf95_results.txt")

# Success/Fail Ratio - Expected Exceed / Actual Exceed
# Unconditional Coverage - Proportion Of Failure (POF) Kupiece Test p-value
# Conditional Coverage - Christoffersen Test p-value

############################# BOOTSTRAPPING ##############################
standadized_residuals <- model_fit@fit$residuals / model_fit@fit$sigma



################ VAR ESTIMATION BASED ON VOLATILITY FORCEAST ##################




############################## EXPECTED SHORTFALL ESTIMATES ############

