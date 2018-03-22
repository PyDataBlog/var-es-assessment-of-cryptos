'''
Stage 1 involves selected the major cryptos
based on a criteria of exceedance of market capitalization above $5bn
'''

# import needed libraries
import pandas as pd

# read historical market cap table
df = pd.read_html('https://coinmarketcap.com/historical/20180304/')

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
left_df.head()

# make a main df by combining the left and right dataframes
main_df = pd.concat([left_df, right_df], axis=1)

# select all with a market cryptos above $5 billion
selected_cryptos = main_df.loc[main_df['Market Cap'] >= 5000000000]

# Summation of Market Cap of selected cryptos
selected_cryptos['Market Cap'].sum()

# percentage of selected cryptos relative to all cryptos in circulation
str(374317470491 / selected_cryptos['Market Cap'].sum() * 100) + '%'

# locate the selected cryptos that meet the criteria
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
    link = f'https://coinmarketcap.com/currencies/{name}/historical-data/?start=20090101&end=20180304'
    
    all_dfs[name] = pd.read_html(link)[0]

    
# get only the date and close prices from the dict    
for keys, values in all_dfs.items():
    values = values[['Date', 'Close']]

# separate the data for each crypto 
bitcoin = all_dfs.get('bitcoin')[['Date', 'Close']]
ethereum = all_dfs.get('ethereum')[['Date', 'Close']]
ripple = all_dfs.get('ripple')[['Date', 'Close']]
bitcoin_cash = all_dfs.get('bitcoin-cash')[['Date', 'Close']]
litecoin = all_dfs.get('litecoin')[['Date', 'Close']]
neo = all_dfs.get('neo')[['Date', 'Close']]
cardano = all_dfs.get('cardano')[['Date', 'Close']]
stellar = all_dfs.get('stellar')[['Date', 'Close']]
eos = all_dfs.get('eos')[['Date', 'Close']]
monero = all_dfs.get('monero')[['Date', 'Close']]
iota = all_dfs.get('iota')[['Date', 'Close']]    

# combine closing price data for each crypto into a master dataframe
master_df_close = pd.concat([bitcoin, ethereum, ripple, 
                             bitcoin_cash, litecoin, neo,
                             cardano, stellar, eos, monero,
                             iota], axis=1, join='outer')

# rename columns
cols = ['Date','bitcoin', 'Date_eth','ethereum', 'Date_ripple','ripple', 
        'Date_bcash','bitcoin_cash', 'Date_ltc','litecoin',
        'Date_neo','neo', 'Date_card','cardano','Date_stellar','stellar',
        'Date_eos','eos', 'Date_mon','monero', 'Date_iota','iota']

master_df_close.columns = cols


# drop cryptos with few data points
final_df = master_df_close.drop(columns=['Date_bcash', 'bitcoin_cash', 
                              'Date_card', 'cardano',
                              'Date_stellar',
                              'Date_eos', 'eos',
                              'Date_eth', 'Date_ripple',
                              'Date_ltc', 'Date_neo',
                              'neo',
                              'Date_mon', 
                              'Date_iota', 'iota'
                             ], axis=1)

final_df.dropna(axis=0)

# save final results as csv file
final_df.to_csv('crypto.csv', index=False)