""" Homework problem 1. Options data recording"""
import datetime as dt
import pandas as pd
import numpy as np
from pandas.io.data import Options
import h5py as h5


# ticker_list.csv contains a list of tickers on nyse and nasdaq stock exchanges
tickers = pd.Series.from_csv('ticker_list.csv')
num_ticks = tickers.size
#  used to print status
months = {1: 'Jan', 2: 'Feb', 3: 'Mar', 4: 'Apr', 5: 'May', 6: 'Jun', 7: 'Jul', 8: 'Aug', 9: 'Sep', 10: 'Oct', 11: 'Nov', 12: 'Dec'}
now = dt.datetime.now()  # Get current time
c_month = months[now.month]  # Get current month
c_day = str(now.day)  # Get current day
c_year = str(now.year)  # Get current year
f = h5.File('./options_db.h5', 'w')  # open database file
year = f.require_group(c_year)  # Make hdf5 group for year
month = year.require_group(c_month)  # Make hdf5 group for month
day = month.require_group(c_day)  # Make hdf5 group for day
num = 0
for i in tickers.index:
    option = Options(i,'yahoo') # NOTE: the following line needs to be corrected to retrieve the options price data
    # raw_puts, raw_calls = option.get_options_data(expiry=PANDAS_DATE)
    raw_puts = option.get_put_data().reset_index()
    raw_calls = option.get_call_data().reset_index()

    # raw_calls = option.get_forward_data(months=3, call=1, put=0, near=1, above_below=6)
    # raw_puts = option.get_forward_data(months=3, call=0, put=1, near=1, above_below=6)
    if raw_calls.values.any():  # Check if any calls were returned
        try:  # Try to add item to file.
        #  This block (and below for puts) does the following:
        #   - Get unique expiry dates
        #   - make hdf5 group for ticker
        #   - Get options data for each expiry
        #   - Put each set of expiry data in unique hdf5 dataset
            expiries = raw_calls["Expiry"].unique().astype(str)
            tick = day.require_group(i)
            for ex in expiries:
                data = raw_calls[raw_calls["Expiry"] == ex]
                i_calls = data[["Strike", 'Last', 'Vol']]
                i_calls.Vol = i_calls.Vol.replace(',', '')
                ex_m_y = ex[:2] + ex[-3:]
                call_ds = tick.require_dataset('C' + i + ex_m_y, i_calls.shape, float)
                call_ds[...] = i_calls.astype(np.float32)
        except:  # If it doesn't work just pass
            print "call pass"
            pass
    if raw_puts.values.any():  # Check if any puts were returned
        try:
            expiries = raw_puts["Expiry"].unique().astype(str)
            tick = day.require_group(i)
            for ex in expiries:
                data = raw_puts[raw_puts["Expiry"] == ex]
                i_puts = data[['Strike', 'Last', 'Vol']]
                i_puts.Vol = i_puts.Vol.replace(',', '')
                ex_m_y = ex[:2] + ex[-3:]
                put_ds = tick.require_dataset('P' + i + ex_m_y, i_puts.shape, float)
                put_ds[...] = i_puts.astype(np.float32)
        except:
            print "put pass"
            pass
    # status update
    num += 1
    if num % 500 == 0:
        print "just finished %s of %s" % (str(num), str(num_ticks))
f.close()  # Close file
# ###***** end of python code ****