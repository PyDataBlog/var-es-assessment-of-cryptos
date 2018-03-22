'''
This sequence involves combine the separate datasets 
(cryptos, sp_500, russell_200) as the final dataset for analysis
'''
# import libraries
import pandas as pd

# read the two indices files
sp_df = pd.read_csv("sp_500.csv")
russel_df = pd.read_csv("russel_2000.csv")

# subset date and adjusted closing prices columns
sp_df = sp_df[["Unnamed: 0", "GSPC.Adjusted"]]
russel_df = russel_df[["Unnamed: 0", "RUT.Adjusted"]]

# rename columns
sp_df.columns = ["date", "GSPC"]
russel_df.columns = ["date", "RUT"]

# set date columns as datetime objects
sp_df["date"] = pd.to_datetime(sp_df["date"])
russel_df["date"] = pd.to_datetime(russel_df["date"])

# make an indices dataframe
indices = pd.concat([sp_df, russel_df], axis=1, ignore_index=True)

# rename indices column
indices.columns = ['date', 'GSPC', 'rut_date', 'RUT']

# subset needed columns in indices dataframe
indices = indices[['date', 'GSPC', 'RUT']]

# set date column as an index and drop the date column after
indices.index = indices['date']
indices.drop('date', axis=1, inplace=True)

# read crypto dataframe generated
final_df = pd.read_csv("crypto.csv")

# rename date column
final_df.rename({'Date': 'date'}, axis=1, inplace=True)

# set date column from crypto data as datetime, set it as index and sort the index in an ascending order
final_df['date'] = pd.to_datetime(final_df['date'])
final_df.set_index('date', drop=True, inplace=True)
final_df.sort_index(inplace=True)

# subset the period under consideration
final_df = final_df['2015-08-07':'2018-03-04']

# combine the indices dataframe and the crypto dataframe
master_df = pd.concat([final_df, indices], axis=1)

# save combined dataframe as master_dataset csv
master_df.to_csv("master_dataset.csv", index=True)

# drop NAs from master dataframe (weekend data) as stocks don't trade on weekends but cryptos do
no_weekend_df = master_df.dropna(axis=0)

# save non_weekend dataframes
no_weekend_df.to_csv("master_dataset_no_weekend.csv", index=True)