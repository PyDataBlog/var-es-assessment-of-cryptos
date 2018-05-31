'''
Stage 1 involves selected the major cryptos
based on a criteria of exceedance of market capitalization above $4bn

Don't forget to set the folder in which this script is held in 
as the current working folder before running the script
'''

# import needed libraries
import pandas as pd
pd.options.mode.chained_assignment = None 

# read historical market cap table
df = pd.read_html('https://coinmarketcap.com/historical/20180429/')

# first item is the market cap table
df = df[0]
df.head()

# unneeded columns
df.drop(['#', 'Circulating Supply', 'Volume (24h)',
         '% 1h', '% 24h', '% 7d'
        ], axis=1, inplace=True)

# drop minor cryptos
df = df.iloc[:30]

'''
Split the DF into two separate dfs in or to apply a function to the columns with numbers
'''

# make a right side of the final table by converting all string figures into floats
right_df = df[df.columns[2:4]].replace('[\$,]', '', regex=True).astype(float)

# make a left side of final table
left_df = df.loc[0:30, ['Name', 'Symbol']]

# make a main df by combining the left and right dataframes
main_df = pd.concat([left_df, right_df], axis=1)

# select all with a market cryptos above $4 billion
selected_cryptos = main_df.loc[main_df['Market Cap'] >= 4000000000]

# drop the ticker tags on the names
no_ticker = selected_cryptos.Name.str.replace('^\w\w\w+\s', '')
selected_cryptos.loc[:, 'Name'] = no_ticker

# rename properly bitcoin-cash
selected_cryptos.loc[3, 'Name'] = 'Bitcoin-cash'

# a list of crypto names
crypto_names = list(selected_cryptos['Name'].str.lower())

# a dictionary to store all the crypto data
all_dfs = dict()

# loop through the crypto_names list and get the data from coinmarketcap.com
for name in crypto_names:
    link = f'https://coinmarketcap.com/currencies/{name}/historical-data/?start=20090101&end=20180501'
    
    all_dfs[name] = pd.read_html(link)[0]

# get only the date and close prices from the dict    
for keys, values in all_dfs.items():
    values = values[['Date', 'Close**']]

# separate the data for each crypto 
bitcoin = all_dfs.get('bitcoin')[['Date', 'Close**']]
ethereum = all_dfs.get('ethereum')[['Date', 'Close**']]
ripple = all_dfs.get('ripple')[['Date', 'Close**']]
bitcoin_cash = all_dfs.get('bitcoin-cash')[['Date', 'Close**']]
eos = all_dfs.get('eos')[['Date', 'Close**']]
cardano = all_dfs.get('cardano')[['Date', 'Close**']]
litecoin = all_dfs.get('litecoin')[['Date', 'Close**']]
stellar = all_dfs.get('stellar')[['Date', 'Close**']]
iota = all_dfs.get('iota')[['Date', 'Close**']]
tron = all_dfs.get('tron')[['Date', 'Close**']]
neo = all_dfs.get('neo')[['Date', 'Close**']]
monero = all_dfs.get('monero')[['Date', 'Close**']]

# combine closing price data for each crypto into a master dataframe
master_df_close = pd.concat([bitcoin, ethereum, ripple, 
                             bitcoin_cash, eos, cardano,
                             litecoin, stellar, iota, tron,
                             neo, monero], axis=1, join='outer')

# rename columns
cols = ['Date','bitcoin', 'Date_eth','ethereum', 'Date_ripple','ripple', 
        'Date_bcash','bitcoin_cash', 'Date_eos','eos',
        'Date_cardano','cardano', 'Date_litecoin','litecoin','Date_stellar','stellar',
        'Date_iota','iota', 'Date_tron','tron', 'Date_neo','neo', 'Date_monero', 'monero']

master_df_close.columns = cols

# drop cryptos with few data points
final_df = master_df_close.drop(columns=['Date_bcash', 'bitcoin_cash', 
                              'Date_cardano', 'cardano',
                              'Date_eos', 'eos',
                              'Date_iota', 'iota', 
                              'Date_tron', 'tron',
                              'Date_eth', 'Date_ripple',
                              'Date_litecoin', 'Date_stellar',
                              'Date_neo', 'neo', 'Date_monero'
                             ], axis=1)

crypto_df = final_df.dropna(axis=0)

# set date column from crypto data as datetime, 
#set it as index and sort the index in an ascending order
crypto_df['Date'] = pd.to_datetime(crypto_df['Date'])
crypto_df.set_index('Date', drop=True, inplace=True)
crypto_df.sort_index(inplace=True)

# subset the period under consideration
final_df = crypto_df['2015-08-07':'2018-04-30']

# rename index as 'date'
final_df.index.rename("date", inplace=True)

# save output file as master dataset
final_df.to_csv("master_dataset.csv", index=True)

