# Sequence 4 involves pulling usd/jpy exchange rates from Yahoo! Finance

# R Code to pull data from Yahoo Finance

library(quantmod)

startDate <- as.Date("2015-08-07") 
endDate <- as.Date("2018-03-04")


getSymbols("JPY=X", src = "yahoo",
          from=startDate, to=endDate
          )

df <- as.data.frame(`JPY=X`)

write.csv(df, file = "USD_JPY_YAHOO.csv", row.names = TRUE)