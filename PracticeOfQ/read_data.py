import pandas as pd
import pdb
import numpy as np
from pandas.tseries.offsets import MonthEnd

s_make_1992_path = 'data/BEA/IOMAKE1992.TXT'
s_use_1992_path = 'data/BEA/IOUSE1992.TXT'
s_code_1992_path = 'data/BEA/IOCODE1992.TXT'

s_make_2007_path = 'data/BEA/IOMAKE2007.xlsx'
s_use_2007_path = 'data/BEA/IOUSE2007.xlsx'

crsp_path = 'data/CRSP_92to07.csv'
s_crap_price_path = 'data/CRSP_price.csv'

sic_io_path = 'data/BEA/Sic-IO.txt'
s_5_factor = 'data/F-F_Research_Data_5_Factors_2x3.CSV'

def read_make_92(filename):
    make_table = pd.read_csv(filename, sep='\t', header=None, names = ["industry", "commodity", "reference", "value"],
                                dtype={'industry':str, 'commodity':str, 'reference':np.int64, 'value':np.float64})
    return make_table[['industry', 'commodity', 'value']].pivot('industry', 'commodity', 'value')

def read_use_92(filename):
    # only [industry, commodity, value] are useful
    use_table = pd.read_csv(filename, sep='\t', header=None,
                                names = ["industry", "commodity", "reference", "value", "cost", "railroad", "truck",
                                         "water", "air", "pipeline", "gas", "wholesale", "retail"],
                                dtype={'industry':str, 'commodity':str, 'reference':np.int64, 'value':np.float64,
                                       'cost':np.float64, 'railroad':np.float64, 'truck':np.float64,'water':np.float64,
                                       'air':np.float64, 'pipeline':np.float64, 'gas':np.float64, 'wholesale':np.float64,
                                       'retail':np.float64})
    return use_table[['industry', 'commodity', 'value']].pivot('industry', 'commodity','value')

def read_code_92(filename):
	code_map = pd.read_csv(filename, sep='\t', header = None)
	return code_map


def read_data(filename):
	# 2007
    # pdb.set_trace()
    df_table = pd.read_excel(filename,
    						 sheetname='2007',
    						 header=0,
    						 index_col=0)
    return df_table

def read_data_io(filename):
	'''
	read data for 1992-like tables
	currently only works for make data, not use data
	'''
	# pdb.set_trace()
	df_temp = pd.read_csv(filename,
						  sep='	',
						  header=None,
						  usecols=[0, 1, 3],
						  index_col=[0, 1])
	df_table = df_temp.unstack(level=-1)
	df_table.columns = df_table.columns.droplevel()
	return df_table


# read CRSP data. Return a pandas dataframe
def read_crsp(filename):
	return pd.read_csv(filename, low_memory = False)

# read price data from CRSP
def read_price(s_path=s_crap_price_path):
    df = pd.read_csv(s_path, parse_dates=True).set_index('date')
    df.index = pd.to_datetime(df.index)
    return df

# read BEA's sic_io file and return a dict{key=IO_industry, value=SIC code}
# DON'T USE THIS FUNCTION!
# USE sic_io_mapping class to convert SIC and IO codes
def read_sic_io(filename):
	result = dict()
	# indicate if some data is on the next line
	line_finished = True

	f = open(filename)
	for line in f:
		if "78.0200" in line:
			break
		words = line.split()
		if len(words) == 0:
			continue
		if line_finished:
			# special cases
			if words[0] == "71.0100" or words[0] == "71.0202":
				continue

			# if it's a new line of io code
			if "." in words[0] and words[0][-1] != ".":
				# read io code
				io_code = words[0].replace(".", "")
				if len(io_code) < 6:
					io_code = "0" + io_code
				if io_code not in result.keys():
					result[io_code] = []
				# read sic code
				for word in words[1:]:
					# *019 or *0259 or 0131 or 024,*019
					if word[0] == "*" or word[0].isdigit():
						result[io_code].extend(parse_sic(word))

				if not words[-1][-1].isdigit() and not words[-1][-1] == ")":
					line_finished = False
				else:
					# print io_code, result[io_code]
					pass
			else:
				# print line
				pass
		else:
			# if the second last character is not digit, this line does not have sic data
			if not words[-1][-2].isdigit() and not words[-1][-1].isdigit():
				continue

			for word in words:
				if word[0] == "*" or word[0].isdigit():
					result[io_code].extend(parse_sic(word))

			# if the last character is digit, the line is over
			if words[-1][-1].isdigit() or words[-1][-1] == ")":
				line_finished = True
				# print io_code, result[io_code]
			else:
				line_finished = False

	return result

# sic code in Sic-IO.txt counld be *123 2951 *16-17. Return a list of sic codes
def parse_sic(raw_sic):
	result = []
	sub_list = raw_sic.split(",")
	for sic in sub_list:
		if len(sic) == 0:
			continue
		sic = sic.replace(",", "")
		sic = sic.replace("*", "")
		if "-" in sic:
			temp = sic.split("-")
			begin = temp[0]
			end = temp[1]
			if len(begin) == 1:
				continue
			# *15-16
			elif len(begin) == 2:
				begin_ = int(begin)*100
				end_ = int(end)*100 + 99
				for i in range(begin_, end_+1):
					result.append(str(i))
			# 071-2 or 103-4
			elif len(begin) == 3:
				begin_ = int(begin)*10
				end_ = int(begin[:-1] + end)*10 + 9
				for i in range(begin_, end_+1):
					if i < 1000:
						result.append("0" + str(i))
					else:
						result.append(str(i))
			# 0171-2
			elif len(begin) == 4:
				begin_ = int(begin[-1])
				end_ = int(end)
				for i in range(begin_, end_+1):
					result.append(begin[:-1] + str(i))

		else:
			if len(sic) == 4:
				result.append(sic)
			else:
				if len(sic) == 3:
					for i in range(0,10):
						result.append(sic + str(i))
				elif len(sic) == 2:
					for i in range(0, 100):
						if i < 10:
							result.append(sic + "0" + str(i))
						else:
							result.append(sic + str(i))
	return result	
	
def read_sp500():
	df = pd.read_csv('data/sp500.csv', parse_dates=True).set_index('Date')['Adj Close']
	df.index = pd.to_datetime(df.index)
	return df.sort_index()

def read_ff_factors(s_path=s_5_factor, **kwargs):
	'''
	read factor/ portfolio data from Ken French's website
	:param s_path: a string containing to path to data file
	:param kwargs: additional arguments for pd.read_csv: skiprows, nrows
	:return: a pandas DataFrame containing time series data
	'''
	df_data = pd.read_csv(s_path, **kwargs)
	to_datetime = lambda x: pd.to_datetime(str(x), format='%Y%m') + MonthEnd(1)
	df_data.ix[:, 0] = df_data.ix[:, 0].apply(to_datetime)
	df_data.columns = [s_col.strip() for s_col in df_data.columns]
	return df_data.set_index(df_data.columns[0]) / 100.0



if __name__ == '__main__':
    print read_data(s_make_2007_path).shape
    print read_data_io(s_use_1992_path)
	
	# make_table = read_make_92("data/BEA/IOMAKE1992.TXT")
    # print make_table.head()
    # use_table = read_use_92("data/BEA/IOUSE1992.TXT")
    # print use_table.head()
