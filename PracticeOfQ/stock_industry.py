import pandas as pd
import numpy as np
import pdb
import cPickle
import read_data
import sic_io

s_stock_dict_path = 'data/stock_dict.pickle'
s_industry_port = 'data/industry_portfolios.csv'
# generate a dictionary that matches stocks to industries based on SIC
# the CRSP dataframe should at least contain the following columns:
# [PERMNO date CUSIP SICCD]

# return a dict{key=industry, value = dict{key = dates, value = list of CUSIP}}
def get_stocks_dict(crsp_df):
    result = dict()
    for index, data in crsp_df.iterrows():
        industry = data['SICCD']
        date = data['date']
        cusip = data['CUSIP']
        if industry not in result.keys():
            result[industry] = dict()
            result[industry][date] = [cusip]
        else:
            if date not in result[industry].keys():
                result[industry][date] = [cusip]
            else:
                result[industry][date].append(cusip)
    print result.keys()[0]
    result.pop(result.keys()[0])
    with open(s_stock_dict_path, 'wb') as f_output:
        cPickle.dump(result, f_output)

def read_stocks_dict(filename):
    with open(filename, 'rb') as f_input:
        d_result = cPickle.load(f_input)
        return d_result

def get_related_industries(df_comb, sic_io, s_industry, i_number_of_ind=None):
    df = df_comb[s_industry][df_comb[s_industry] != 0].sort(ascending = False, inplace = False)
    result_io = []
    result_sic = []
    if i_number_of_ind is None:
        result_io =  df.index.tolist()
    else:
        result_io = df.index.tolist()[:i_number_of_ind]

    for i in result_io:
        sic = sic_io.io2sic(i)
        if sic == None:
            if i != "780500" and i != "790300":
                print i
                pdb.set_trace()
        else:
            result_sic.extend(sic)

    return result_sic

def save_price_from_crsp():
    df = pd.read_csv(s_crsp_path, low_memory=False)
    df['date'] = df['date'].apply(str)
    df['date'] = pd.to_datetime(df['date'])
    df['close'] = df[['BID', 'ASK']].mean(axis=1)
    df = df.set_index(['date', 'CUSIP']).loc[:, 'close']
    df = df.unstack(level=-1)
    assert ~df.index.duplicated().any()
    assert ~df.columns.duplicated().any()
    df.to_csv(s_crsp_price_path)

def calc_industry_port(d_const):
    prices = read_data.read_price()
    prices.fillna(method='ffill', inplace=True)
    i_len, i_width = prices.shape
    # initialize dataframe
    df_result = pd.DataFrame(columns=d_const.keys(),
                             index=prices.index)
    df_result.index.name = 'date'
    for s_ind, d_ind_const in d_const.iteritems():
        ldt_dates = pd.to_datetime([str(date) for date
                                    in d_ind_const.keys()]).order()
        li_dates = sorted(d_ind_const.keys())
        assert len(ldt_dates) <= i_len
        ldf_port = []
        for i_index in range(len(ldt_dates) - 1):
            dt_start = ldt_dates[i_index]
            if i_index == 0:
                df_result.loc[dt_start, s_ind] = 1.0
            dt_end = ldt_dates[i_index + 1]
            ls_start = d_ind_const[li_dates[i_index]]
            ls_end = d_ind_const[li_dates[i_index + 1]]
            ls_survive = list(set(ls_start) & set(ls_end))
            df_prices = prices.loc[dt_start: dt_end, ls_survive]
            ts_port_val = (df_prices / df_prices.iloc[0]).mean(axis=1)
            # generate 1-based return
            ts_port_ret1 = ts_port_val / ts_port_val.shift(1)
            df_result.loc[dt_end, s_ind] = ts_port_ret1[-1]

    df_result.fillna(method='ffill', inplace=True)
    df_result = df_result.cumprod()
    df_result.to_csv(s_industry_port)


def evaluate_positions(df_industries, d_positions):
    '''
    :param df_industries: cumulative return of industries
    :param d_positions: {date: list of sym}
    '''
    df_rets1 = df_industries / df_industries.shift(1)
    ldt_dates = sorted(d_positions.keys())
    ts_long = pd.Series(index=ldt_dates)
    ts_short = ts_long.copy()

    ts_long.iloc[0] = 1.0
    ts_short.iloc[0] = 1.0
    for i in range(len(ts_long) - 1):
        dt_entry = ts_long.index[i]
        ls_long, ls_short = d_positions[dt_entry]

        dt_exit = ts_long.index[i + 1]
        ts_long_ret = df_rets1.loc[dt_exit, ls_long]
        ts_short_ret = df_rets1.loc[dt_exit, ls_short]
        f_mean_long = ts_long_ret.mean()
        f_mean_short = ts_short_ret.mean()
        ts_long[dt_exit] = f_mean_long
        ts_short[dt_exit] = f_mean_short
    ts_long.fillna(1.0, inplace=True)
    ts_short.fillna(1.0, inplace=True)
    ts_port = (ts_long - ts_short) / 2.0 + 1.0
    ts_result = ts_port.cumprod()
    return ts_result

def read_industry_port(s_path=s_industry_port):
    return pd.read_csv(s_path, parse_dates=True).set_index('date')

def gen_networks(ls_central, ls_peripheral, df_comb):
    
    pass

if __name__ == '__main__':
    #crsp_df = read_data.read_crsp(read_data.crsp_path)
    # crsp_df = read_data.read_crsp('data/temp.csv')
    #print crsp_df.head()
    #get_stocks_dict(crsp_df)
    #si = read_stocks_dict(s_stock_dict_path)
    #calc_industry_port(si)
    print read_industry_port().head()
