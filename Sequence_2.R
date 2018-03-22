# Sequence 2 involves pulling data from Yahoo! Finance with R

##################################### GET RUSSEL_200 FROM YAHOO ###########################
library(quantmod)

startDate = as.Date("2015-08-07") 
endDate = as.Date("2018-03-04")


getSymbols("^RUT", src = "yahoo",
           from=startDate, to=endDate)

df = as.data.frame(RUT)

write.csv(df, file = "russel_2000.csv", row.names = TRUE)

##################################### GET SP_500 FROM YAHOO ###########################
library(quantmod)

startDate = as.Date("2015-08-07") 
endDate = as.Date("2018-03-04")


getSymbols("^GSPC", src = "yahoo",
           from=startDate, to=endDate)

df = as.data.frame(GSPC)

write.csv(df, file = "sp_500.csv", row.names = TRUE)
