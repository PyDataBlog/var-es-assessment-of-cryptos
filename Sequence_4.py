'''
Sequence 4 involves adding the data pulled from Yahoo Finance with
add_sp_df dataframe composed of cryptos and s&p 1200 data
'''
# import needed libraries
import pandas as pd

# read the two datasets
usd_df = pd.read_csv("USD_JPY_YAHOO.csv")
add_sp_df = pd.read_csv("add_sp_df.csv")

# select relevant usd_df columns
usd_df = usd_df[["Unnamed: 0", "JPY=X.Adjusted"]]

# rename usd_df columns
usd_df.columns = ["date", "usd_jpy"]

# set date column as a datetime object, use it as an index and drop it as a column
usd_df['date'] = pd.to_datetime(usd_df['date'])
usd_df.index = usd_df['date']
usd_df = usd_df['2015-08-07':'2018-03-04']
usd_df.drop('date', axis=1, inplace=True)

# add the two dataframes as columns
final_df = pd.concat([add_sp_df, usd_df.usd_jpy], axis=1, ignore_index=True)

# rename columns appropriately
fin_cols = ['bitcoin', 'ethereum', 'ripple', 'litecoin',
            'stellar', 'monero', 'sp_1200', 'usd_jpy'] 

final_df.columns = fin_cols

# save the final result as a final master csv
final_df.to_csv("final_master.csv")
