import math
import numpy as np
import pandas as pd
import pdb
from pandas.tseries.offsets import MonthEnd
import read_data
import stock_industry
import sic_io
import matplotlib.pyplot as plt
from scipy.stats import wilcoxon
from sklearn.linear_model import LinearRegression


def test_alpha(df_port, ls_factors=['Mkt-RF', 'SMB', 'HML', 'RMW', 'CMA']):
    # run against ff5 or capm models to test for alpha
    df_rets = df_port / df_port.iloc[0] - 1.0
    df_rets.dropna(inplace=True)
    df_factors = read_data.read_ff_factors(read_data.s_5_factor, skiprows=3, nrows=639)
    ldt_dates = pd.to_datetime(df_rets.index)
    df_start = ldt_dates[0]
    dt_end = ldt_dates[-1]
    df_X = df_factors.loc[df_start: dt_end, ls_factors].fillna(method='ffill')
    df_X = df_X.reindex(ldt_dates, method='ffill')
    df_Y = df_rets - df_factors.loc[ldt_dates, 'RF'].fillna(method='ffill')
    scp_linreg = LinearRegression(fit_intercept=True)
    scp_linreg.fit(df_X, df_Y)
    df_intercept = df_Y - (scp_linreg.coef_ * df_X).sum(axis=1)
    f_wilcoxon_t, f_wilcoxon_p = wilcoxon(df_intercept)
    return (df_intercept.mean(), f_wilcoxon_p, scp_linreg.coef_)

def calc_stats(df_port):
    df_sp500 = read_data.read_sp500()
    df_rets = df_port / df_port.shift(1) - 1.0
    df_rets.dropna(inplace=True)
    ldt_dates = pd.to_datetime(df_rets.index)

    df_factors = read_data.read_ff_factors(read_data.s_5_factor, skiprows=3, nrows=639)
    dt_start = ldt_dates[0]
    dt_end = ldt_dates[-1]
    # risk premium
    df_rf = df_factors.loc[dt_start:dt_end, 'RF'].fillna(method='ffill')
    #import pdb; pdb.set_trace()
    df_rf = df_rf.reindex(ldt_dates, method='ffill')
    df_rets = df_rets - df_rf
    print 'monthly return: ', df_rets.mean()
    print 'annualized return: ', df_rets.mean() * 12.0
    print 'monthly sharpe: ', df_rets.mean() / df_rets.std()
    print "jensen's alpha: ", test_alpha(df_port, ls_factors=['Mkt-RF'])
    print 'Fama-French 5 factor alpha: ', test_alpha(df_port)

    df_market = df_factors.loc[dt_start:dt_end, 'Mkt-RF'].fillna(method='ffill')
    df_market = df_market.reindex(ldt_dates, method='ffill')
    print 'mkt ret: ', df_market.mean(), df_market.mean() * 12
    print 'mkt sharpe: ', df_market.mean() / df_market.std()

if __name__ == '__main__':
    # pdb.set_trace()
    # read preprocessed xlsx data
    # df_make = read_data.read_data(read_data.s_make_2007_path)
    # df_use = read_data.read_data(read_data.s_use_2007_path)
    df_make = read_data.read_make_92(read_data.s_make_1992_path)
    df_use = read_data.read_use_92(read_data.s_use_1992_path)

    # get common col/rows from two tables
    ss_mkidx = set(df_make.index).intersection(df_make.columns)
    ss_useidx = set(df_use.index).intersection(df_use.columns)
    # pdb.set_trace()
    ls_industries = list(ss_mkidx.intersection(ss_useidx))

    # get subset
    # TODO: aggregate the IO-codes with the same SIC/NAICS codes
    # remove the ones without SIC/NAICS codes
    # inject artificial industries
    # see appendix 6.1
    df_make = df_make.loc[ls_industries, ls_industries].fillna(0)
    df_use = df_use.loc[ls_industries, ls_industries].fillna(0)
    assert df_make.shape == df_use.shape


    normalize = lambda x: x / x.sum()
    # normalize make table by columns
    df_make = df_make.apply(normalize, axis=0)

    df_make = df_make.fillna(0)
    df_use = df_use.fillna(0)
    # calculate REVSHARE
    df_revshare = df_make.dot(df_use)

    # remove rows that sum up to 0
    ls_row_include = ~(df_revshare.sum(axis=1) == 0)
    ls_col_include = ~(df_revshare.sum(axis=0) == 0)
    ls_keep = df_revshare.index[ls_row_include & ls_col_include]
    df_revshare = df_revshare.loc[ls_keep, ls_keep]

    # normalize REVSHARE by rows to get CUST
    df_cust = df_revshare.apply(normalize, axis=1)

    # normalize REVESHARE by cols to get SUPP
    df_supp = df_revshare.apply(normalize, axis=0)

    # average cust and supp into COMB
    df_comb = (df_cust + df_supp) / 2
    df_comb = df_comb.fillna(0)
    # pdb.set_trace()
    # symmetrize the COMB by taking the
    # maximum of (i, j) and (j, i) entries
    na_comb = np.array(df_comb)
    for i_row in range(na_comb.shape[0]):
        for i_col in range(na_comb.shape[1]):
            f_max = max(na_comb[i_row, i_col], na_comb[i_col, i_row])
            na_comb[i_row, i_col] = f_max
            na_comb[i_col, i_row] = f_max

    df_comb = pd.DataFrame(na_comb,
                           index=df_comb.index,
                           columns=df_comb.columns)

    # Interpreting the COMB as an adjacency matrix
    # that defines the strength of links among nodes in a network
    # get principal eigenvector
    # pdb.set_trace()
    na_eigval, na_eigvec = np.linalg.eig(df_comb)
    df_centrality = pd.DataFrame(na_eigvec[:, 0], index=ls_keep)
    print("Mean", df_centrality[0].mean())
    print("Standard deviation", df_centrality[0].std())
    print("Minimum", df_centrality[0].min())
    print("5th percentile", df_centrality[0].quantile(0.05))
    print("10th percentile", df_centrality[0].quantile(0.1))
    print("25th percentile", df_centrality[0].quantile(0.25))
    print("50th percentile", df_centrality[0].quantile(0.5))
    print("75th percentile", df_centrality[0].quantile(0.75))
    print("90th percentile", df_centrality[0].quantile(0.90))
    print("95th percentile", df_centrality[0].quantile(0.95))
    print("Maximum", df_centrality[0].max())
    print("Number of Obs", df_centrality[0].shape[0])

    code_map = read_data.read_code_92(read_data.s_code_1992_path).set_index(0)[1].to_dict()

    sorted_centrality = df_centrality.sort(columns=0, ascending=True)
    least_central = [code_map[x] for x in sorted_centrality.index[0:22]]
    most_central = [code_map[x] for x in sorted_centrality.index[-21:]]
    print("LEAST central: ")
    for ind in least_central:
        print ind
	print
	print
    print("MOST central: ")
    for ind in most_central:
		print ind

    '''
    {links:[{"id": "Myriel", "group": 1}],
    nodes:[{"source": "Napoleon", "target": "Myriel", "value": 1}]}
    '''
    import pdb; pdb.set_trace()
    d_networks = {"links": [],
                  "nodes": []}
    df_quantiles = pd.qcut(sorted_centrality[0], 10, labels=False)
    #df_quantiles = df_quantiles[df_quantiles > 6]
    df_keep = pd.concat([sorted_centrality[0][0:22],sorted_centrality[0][-21:]],axis=0)
    #df_keep = df_quantiles
    for index in df_keep.index:
        row = {"name":code_map[index], "group":df_quantiles[index]}
        d_networks["nodes"].append(row)
    df_comb_ = df_comb.loc[df_keep.index, df_keep.index]

    mean = df_comb_.mean().mean()
    sd = df_comb_.std().mean()
    for i_idx in range(df_comb_.shape[0]):
        for j_idx in range(df_comb_.shape[1]):
            if i_idx != j_idx:
                if df_comb_.values[i_idx, j_idx] > (mean + 0.0 * sd):
                    row = {"source": i_idx, "target": j_idx, "value": df_comb_.values[i_idx, j_idx]*3}#df_comb.loc[source, target]}
                    d_networks["links"].append(row)
    import json;
    with open('data/networks.json', 'w') as outfile:
        json.dump(d_networks, outfile)
    pdb.set_trace()
    # need to map all io codes to sic codes from this point on
    # for each rebalance period:
    # find related industries for most central
    # find related industries for least central
    ls_central_sic = sorted_centrality.index[-21:]
    ls_peripheral_sic = sorted_centrality.index[0:22]
    df_industries = stock_industry.read_industry_port()
    # number of industries to trade each time
    i_number_trade = 10
    # number of related industries to use each time
    i_number_related = 20
    
    df_ind_return = df_industries / df_industries.shift(1) - 1.0
    
    o_mapper = sic_io.sic_io_mapping()

    def eval_port(df_industries, ls_sic):
        ls_sic_ = [s_sic for s_sic in ls_sic if s_sic in df_industries.columns]
        return df_industries.loc[:, ls_sic_].mean(axis=1)

    def generate_positions(df_return, ls_sic):
        d_positions = {}
        for dt_index, ts_row in df_return.iterrows():
            ts_related_performance = pd.Series(index=ls_sic)
            for s_ind in ls_sic:
                ls_related = stock_industry.get_related_industries(df_comb,
                                                                   o_mapper,
                                                                   s_ind,
                                                                   i_number_related)
                ts_related_return = ts_row[ls_related].dropna()
                ls_io_ind_const = o_mapper.io2sic(s_ind)
                ts_io_ind = eval_port(df_industries, ls_io_ind_const)
                if ts_io_ind.dropna().shape[0] == 0:
                    print 'warning: ts_to_id has all NaN values'
                else:
                    pass
                if s_ind not in df_industries.columns:
                    df_industries[s_ind] = ts_io_ind
                ts_related_performance[s_ind] = ts_related_return.mean()
            ts_related_performance.dropna(inplace=True)
            ts_related_performance = ts_related_performance.order()
            ls_long = ts_related_performance.index[:i_number_trade]
            ls_short = ts_related_performance.index[-i_number_trade:]

            # note that ls_keep can have length zero, for example at first period
            d_positions[dt_index] = (ls_long, ls_short)
        return d_positions
    d_central_positions = generate_positions(df_ind_return, ls_central_sic)
    d_peripheral_positions = generate_positions(df_ind_return, ls_peripheral_sic)
    # portfolio value of central industries
    df_central_portval = stock_industry.evaluate_positions(df_industries,
                                                           d_central_positions)
    # portfolio value of peripheral industries
    df_peripheral_portval = stock_industry.evaluate_positions(df_industries,
                                                           d_peripheral_positions)
    df_sp500 = read_data.read_sp500()
    df_sp500 = df_sp500 / df_sp500.iloc[0]

    f_excess_return = df_central_portval.iloc[-1] - df_peripheral_portval.iloc[-1]
    ldt_dates = pd.to_datetime(df_central_portval.index)

    print 'central stats: \n'
    #import pdb; pdb.set_trace()
    calc_stats(df_central_portval)
    #pdb.set_trace()
    print 'peripheral stats: \n'
    calc_stats(df_peripheral_portval)
    
    plt.plot(ldt_dates, df_central_portval.values.flatten(), label='central portfolio')
    plt.plot(ldt_dates, df_peripheral_portval.values.flatten(), label='peripheral portfolio')
    plt.plot(df_sp500, label='S&P 500')
    plt.legend(loc=2)
    plt.title('Central Portfolio vs Peripheral Portfolio vs Market')
    plt.savefig('result.png')
    
    import pdb; pdb.set_trace()