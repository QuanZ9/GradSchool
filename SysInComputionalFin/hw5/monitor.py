##***** Homework problem 2. Real-time market price monitoring  *****
import urllib2  # works fine with Python 2.7.9 (not 3.4.+)
import json
import time
import os, re, csv
import numpy as np
import pandas as pd
import sys


def fetchPreMarket(symbol, exchange):
    link = "http://finance.google.com/finance/info?client=ig&q="
    url = link+"%s:%s" %(exchange, symbol)
    u = urllib2.urlopen(url)
    content = u.read()
    data = json.loads(content[3:])
    info = data[0]
    t = str(info["elt"]) # time stamp
    l = float(info["l"].replace(",","")) #  close price (previous trading day)
    p = float(info["el"].replace(",","")) #  stock price in pre-market (after-hours)
    return (t,l,p)

def fetchRegularMarket(symbol, exchange):
    link = "http://finance.google.com/finance/info?client=ig&q="
    url = link+"%s:%s" %(exchange, symbol)
    # url = link+"NASDAQ:AAPL,NASDAQ:JNJ,NASDAQ:SALT"
    u = urllib2.urlopen(url)
    content = u.read()
    data = json.loads(content[3:])
    info = data[0]
    t = str(info["lt"]) # time stamp
    l = float(info["pcls_fix"].replace(",","")) #  close price (previous trading day)
    p = float(info["l_cur"].replace(",","")) #  stock price in regular-market
    return (t,l,p)

def fetchGF(googleticker):
    url="http://www.google.com/finance?&q="
    txt=urllib2.urlopen(url+googleticker).read()
    k=re.search('id="ref_(.*?)">(.*?)<',txt)
    if k:
        tmp=k.group(2)
        q=tmp.replace(',','')
    else:
        q="Nothing found for: "+googleticker
    return q


def combine(ticker):
    quote=fetchGF(ticker) # use the core-engine function
    t=time.localtime()    # grasp the moment of time
    output=[t.tm_year,t.tm_mon,t.tm_mday,t.tm_hour,t. tm_min,t.tm_sec,ticker,quote]  # build a list
    return output


def getRTtickerQuote(tickers, t, fname, freq):
    with open(fname,'a') as f:
        writer=csv.writer(f,dialect="excel") #,delimiter=" ")
        while t.tm_hour<=16:
            if t.tm_hour==16:
                while(t.tm_min<01):
                    data=combine(ticker)
                    print(data)
                    writer.writerow(data) # save data in the file
                    time.sleep(freq)
                else:
                    break
            else:
                for ticker in tickers:
                    data=combine(ticker)
                    print(data)
                    writer.writerow(data) # save data in the file
                    time.sleep(freq)
    f.close()


def getRTportQuote(ticker_list, t, fname, freq):
    with open(fname,'a') as f:
        writer = csv.writer(f,dialect="excel") #,delimiter=" ")
        print t.tm_hour
        while t.tm_hour <= 9:
            if t.tm_hour == 9:
                while t.tm_min < 31 :
                    data = combine(ticker)
                    print(data)
                    writer.writerow(data) # save data in the file
                    time.sleep(freq)
                else:break
            else:
                for ticker in ticker_list:
                    data=combine(ticker)
                    print(data)
                    writer.writerow(data) # save data in the file
                    time.sleep(freq)
    f.close()

if __name__ == "__main__":
    # display time corresponding to your location
    print(time.ctime())
    print
    # Set local time zone to NYC
    os.environ['TZ']='America/New_York'
    t=time.localtime() # string
    print(time.ctime())
    tickers = {"AAPL":"NASDAQ","JNJ":"NYSE", "IBM":"NASDAQ", "GOOG":"NASDAQ", "AA":"NYSE",
               "PFE":"NYSE","SUNE":"NYSE","GE":"NASDAQ","RCMP":"NASDAQ","NQGM":"NASDAQ"}
    zeros = [0] * len(tickers)
    p0 = dict(zip(tickers, zeros))
    # tickers = {"AAPL":"NASDAQ"}
    outFile = open("stockData.csv", 'w')
    outFile.write("Time,Ticker,PreClose,Price,PrcChange,Return\n")
    outFile.close()
    pre_data = pd.DataFrame(columns=tickers.keys())
    while True:

        ct = time.localtime()
        pre_data.loc[len(pre_data)] = 0
        for ticker in tickers:
            # print ticker, tickers[ticker]
            outFile = open(ticker + ".csv", 'a')
            try:
                if (ct.tm_hour == 9 and ct.tm_min <= 30)or (ct.tm_hour < 9 and ct.tm_hour>=6):
                    # get pre market data
                    print "pre market"
                    t, l, p = fetchPreMarket(ticker, tickers[ticker])
                    pre_data.iloc[len(pre_data)-1][ticker] = p
                elif ct.tm_hour >= 9 and ct.tm_hour < 16:
                    # get regular market data
                    t, l, p = fetchRegularMarket(ticker, tickers[ticker])
                    pre_data.iloc[len(pre_data)-1][ticker] = p
                elif ct.tm_hour == 16 and ct.tm_min < 30:
                    # get after hour market data
                    print "after hour market"
                    t, l, p = fetchPreMarket(ticker, tickers[ticker])

                if p != p0[ticker]:
                    p0[ticker] = p
                    outFile.write("%s,%s,%.2f,%.2f,%+.2f,%+.2f%%\n" % (t.replace(",", ""),ticker, l, p, p-l,(p/l-1)*100.))
                    # print("%s\t%s\t%.2f\t%.2f\t%+.2f\t%+.2f%%" % (t,ticker, l, p, p-l,(p/l-1)*100.))
            except:
                print ticker, sys.exc_info()
                pass
            outFile.close()
            if ct.tm_hour == 9 and ct.tm_min == 30:
                # when regular market begins, calculate root-mean-square volatility
                pre_data = pre_data/pre_data[0]
                ratio = pre_data[:-2].std(axis = 0)/pre_data[:-2].mean(axix = 0)
                print ratio

        time.sleep(60)
