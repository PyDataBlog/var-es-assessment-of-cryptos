'''
Sequence 2 involves adding the s&p 1200 data 
the crypto dataset
'''

# import libraries
import pandas as pd

# read crypto csv file generated from sequence 1
crypto_df = pd.read_csv('crypto.csv')

# set date as the datetime object
crypto_df['Date'] = pd.to_datetime(crypto_df['Date'])

# set date of crypto dataset as an index & drop the Date column afer using it an index
crypto_df.index = crypto_df.Date
crypto_df.drop('Date', axis=1, inplace=True)

# read s&p 1200 index csv gathered from 
sp_df = pd.read_csv('S&P_1200.csv')

# rename columns
cols = ['Date', 'S&P_1200']
sp_df.columns = cols

# set date as an index & drop the Date column afer using it an index
sp_df['Date'] = pd.to_datetime(sp_df['Date'])
sp_df.index = sp_df['Date']
sp_df.drop('Date', axis=1, inplace=True)

# slice s&p 1200 dataframe according to the date range of crypto dataframe
sp_df = sp_df['2015-08-07':'2018-03-04']

# add the sp dataframe to the crypto dataframe and 
add_sp_df = pd.concat([crypto_df, sp_df], axis=1, ignore_index=True)

# rename appriopriate columns
add_sp_df_colums = ['bitcoin', 'ethereum', 'ripple', 'litecoin',
                    'stellar', 'monero', 'sp_1200']

add_sp_df.columns = add_sp_df_colums

# save add_sp_df as a csv
add_sp_df.to_csv("add_sp_df.csv", index=False)
