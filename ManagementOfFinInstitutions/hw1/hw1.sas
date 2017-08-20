/** HEADER  **/
OPTIONS ls=70;

LIBNAME qcf "P:\Management_of_Financial_Institutions\hw1\";


/** import .CSV file  **/
FILENAME CSV "P://Management_of_Financial_Institutions/hw1/q1_2012_all.csv";

%macro readCSV(inFile, outfile);

PROC IMPORT DATAFILE=&infile
		    OUT=&outfile
		    DBMS=CSV
		    REPLACE;
RUN;

%mend readCSV;

*2012 data;
%readCSV("P://Management_of_Financial_Institutions/hw1/q1_2012_all.csv", work.q1_2012);
%readCSV("P://Management_of_Financial_Institutions/hw1/q2_2012_all.csv", work.q2_2012);
%readCSV("P://Management_of_Financial_Institutions/hw1/q3_2012_all.csv", work.q3_2012);
%readCSV("P://Management_of_Financial_Institutions/hw1/q4_2012_all.csv", work.q4_2012);

*2013 data;
%readCSV("P://Management_of_Financial_Institutions/hw1/q1_2013_all.csv", work.q1_2013);
%readCSV("P://Management_of_Financial_Institutions/hw1/q2_2013_all.csv", work.q2_2013);
%readCSV("P://Management_of_Financial_Institutions/hw1/q3_2013_all.csv", work.q3_2013);
%readCSV("P://Management_of_Financial_Institutions/hw1/q4_2013_all.csv", work.q4_2013);

*2014 data;
%readCSV("P://Management_of_Financial_Institutions/hw1/q1_2014_all.csv", work.q1_2014);
%readCSV("P://Management_of_Financial_Institutions/hw1/q2_2014_all.csv", work.q2_2014);
%readCSV("P://Management_of_Financial_Institutions/hw1/q3_2014_all.csv", work.q3_2014);
%readCSV("P://Management_of_Financial_Institutions/hw1/q4_2014_all.csv", work.q4_2014);

*2015 data;
%readCSV("P://Management_of_Financial_Institutions/hw1/q1_2015_all.csv", work.q1_2015);
%readCSV("P://Management_of_Financial_Institutions/hw1/q2_2015_all.csv", work.q2_2015);

*combine all data;
data QCF.RAWDATA;
	set work.q1_2012 work.q2_2012 work.q3_2012 work.q4_2012
		work.q1_2013 work.q2_2013 work.q3_2013 work.q4_2013
		work.q1_2014 work.q2_2014 work.q3_2014 work.q4_2014
		work.q1_2015 work.q2_2015;
	rename LitVol__000_ = LitVol;
	rename orderVol__000_ = orderVol;
	rename hiddenVol__000_ = hiddenVol;
	rename tradeVolForHidden__000_ = tradeVolForHidden;
	rename oddLotVol__000_ = oddLotVol;
	rename tradeVolForOddLots__000_ = tradeVolForOddLots;
run;	
	

/**  calculate  metrics **/
DATA WORK.RAWDATA;
	set QCF.RAWDATA;
	Cancel_to_Trade=Cancels/LitTrades;
	Trade_to_Order_Volume=100*LitVol/OrderVol;
	Hidden_Rate=100*Hidden/TradesForHidden;
	Hidden_Volume=100*HiddenVol/TradeVolForHidden;
	Oddlot_Rate=100*OddLots/TradesForOddLots;
	Oddlot_Volume=100*OddLotVol/TradeVolForOddLots;
run;



/** seperate STOCKS and ETFS data  **/
DATA WORK.stocks;
	set WORK.RAWDATA;
	where Security='Stock';
run;


DATA WORK.ETFS;
	set WORK.RAWDATA;
	where Security='ETF';
run;



/**  descriptive stats  **/
proc means data=WORK.STOCKS(drop=Date) N MEAN P25 P50 P75 STDDEV;
run;

proc means data=WORK.ETFS(drop=Date) N MEAN P25 P50 P75 STDDEV;
run;



/** 100 sample stocks **/
* get unique names of stocks;
proc sort data=work.stocks(keep=security ticker) out=work.stock_names nodupkey;
*strata date;
by Ticker;
run;

* get 100 random samples;
proc surveyselect data=WORK.stock_names out=WORK.stocks100names method=srs n=100;
run;

* merge sample stocks' names with original data ;
proc sort data=work.stocks;
by security ticker;
run;

proc sort data=work.q1_2012;
by security ticker;
run;

* merge;
data work.stocks100;
merge work.stocks100names(in=a) work.q1_2012(in=b);
by security ticker;
if a & b;
run;

proc sort data=work.stocks100;
by date;
run;

proc sort data=work.stocks100;
	by Date;
run;

data work.stocks100;
	set work.stocks100;
	Date = input(put(DATE, 8.), yymmdd8.);
	FORMAT Date yymmdd8.;
	
	rename hidden = hidden_s;
	rename cancels = cancels_s;
	rename littrades = littrades_s;
	rename oddLots = oddLots_s;
	rename tradesforoddLots = tradesforoddlots_s;
	rename tradesforhidden = tradesforhidden_s;

	rename LitVol__000_ = LitVol_s;
	rename orderVol__000_ = orderVol_s;
	rename hiddenVol__000_ = hiddenVol_s;
	rename tradeVolForHidden__000_ = tradeVolForHidden_s;
	rename oddLotVol__000_ = oddLotVol_s;
	rename tradeVolForOddLots__000_ = tradeVolForOddLots_s;
run;

data work.stocks100;
	set work.stocks100;
	Cancel_to_Trade_s=Cancels_s/LitTrades_s;
	Trade_to_Order_Volume_s=100*LitVol_s/OrderVol_s;
	Hidden_Rate_s=100*Hidden_s/TradesForHidden_s;
	Hidden_Volume_s=100*HiddenVol_s/TradeVolForHidden_s;
	Oddlot_Rate_s=100*OddLots_s/TradesForOddLots_s;
	Oddlot_Volume_s=100*OddLotVol_s/TradeVolForOddLots_s;
run;



proc means noprint data=work.stocks100 MEAN;
	by Date;
	output out=work.stock_stats100_MEAN mean=;
run;

proc means noprint data=work.stocks100 p25;
	by Date;
	output out=work.stock_stats100_p25 p25=;
run;

proc means noprint data=work.stocks100 p50;
	by Date;
	output out=work.stock_stats100_p50 p50=;
run;

proc means noprint data=work.stocks100 p75;
	by Date;
	output out=work.stock_stats100_p75 p75=;
run;

proc means noprint data=work.stocks100 STD;
	by Date;
	output out=work.stock_stats100_std STD=;
run;


/** 100 sample etfs **/
* get unique names of etfs;
proc sort data=work.etfs(keep=security ticker) out=work.etf_names nodupkey;
by Ticker;
run;

* get 100 random samples;
proc surveyselect data=WORK.etf_names out=WORK.etfs100names method=srs sampsize=100;
run;

* merge sample etfs' names with original data ;
proc sort data=work.etfs;
by security ticker;
run;

* merge;
data work.etfs100;
merge work.etfs100names(in=a) work.q1_2012(in=b);
by security ticker;
if a & b;
run;

proc sort data=work.etfs100;
by date;
run;


data work.etfs100;
	set work.etfs100;
	Date = input(put(DATE, 8.), yymmdd8.);
	FORMAT Date yymmdd8.;
	rename LitVol__000_ = LitVol;
	rename orderVol__000_ = orderVol;
	rename hiddenVol__000_ = hiddenVol;
	rename tradeVolForHidden__000_ = tradeVolForHidden;
	rename oddLotVol__000_ = oddLotVol;
	rename tradeVolForOddLots__000_ = tradeVolForOddLots;
run;


data work.etfs100;
	set work.etfs100;
	Cancel_to_Trade=Cancels/LitTrades;
	Trade_to_Order_Volume=100*LitVol/OrderVol;
	Hidden_Rate=100*Hidden/TradesForHidden;
	Hidden_Volume=100*HiddenVol/TradeVolForHidden;
	Oddlot_Rate=100*OddLots/TradesForOddLots;
	Oddlot_Volume=100*OddLotVol/TradeVolForOddLots;
run;



proc means noprint data=work.etfs100 MEAN;
	by Date;
	output out=work.etfs_stats100_MEAN mean=;
run;

proc means noprint data=work.etfs100 p25;
	by Date;
	output out=work.etfs_stats100_p25 p25=;
run;

proc means noprint data=work.etfs100 p50;
	by Date;
	output out=work.etfs_stats100_p50 p50=;
run;

proc means noprint data=work.etfs100 p75;
	by Date;
	output out=work.etfs_stats100_p75 p75=;
run;

proc means noprint data=work.etfs100 STD;
	by Date;
	output out=work.etfs_stats100_std STD=;
run;



/**  handling stock100 and etfs100 data **/
data  work.stats100_mean;
	merge work.stock_stats100_mean work.etfs_stats100_mean;
	by date;
run;

data  work.stats100_p25;
	merge work.stock_stats100_p25 work.etfs_stats100_p25;
	by date;
run;

data  work.stats100_p50;
	merge work.stock_stats100_p50 work.etfs_stats100_p50;
	by date;
run;

data  work.stats100_p75;
	merge work.stock_stats100_p75 work.etfs_stats100_p75;
	by date;
run;

data  work.stats100_std;
	merge work.stock_stats100_std work.etfs_stats100_std;
	by date;
run;



/**  plot stocks sample  **/
ods rtf file = "P://Management_of_Financial_Institutions/hw1/test.rtf";
proc gplot data = work.stats100_mean;
	title "Mean of Sample Data";
	plot(litvol litvol_s)*date/overlay;
	plot(ordervol ordervol_s) * date/overlay;
	plot(hidden hidden_s) * date/overlay;
	plot(tradesforhidden tradesforhidden_s) * date/overlay;
	plot(hiddenvol hiddenvol_s) * date/overlay;
	plot(tradevolforhidden tradevolforhidden_s) * date/overlay;
	plot(cancels cancels_s) * date/overlay;
	plot(littrades littrades_s) * date/overlay;
	plot(oddlots oddlots_s) * date/overlay;
	plot(tradesforoddlots tradesforoddlots_s)*date/overlay;
	plot(oddlots oddlots_s) * date/overlay;
	plot(tradevolforoddlots tradevolforoddlots_s) * date/overlay;
	plot(cancel_to_trade cancel_to_trade_s) * date/overlay;
	plot(trade_to_order_volume trade_to_order_volume_s) * date/overlay;
	plot(hidden_rate hidden_rate_s) * date/overlay;
	plot(hidden_volume hidden_volume_s) * date/overlay;
	plot(oddlot_rate oddlot_rate_s) * date/overlay;
	plot(oddlot_volume oddlot_volume_s) * date/overlay;
run;

proc gplot data = work.stats100_p25;
	title "P25 of Sample Data";
	plot(litvol litvol_s)*date/overlay;
	plot(ordervol ordervol_s) * date/overlay;
	plot(hidden hidden_s) * date/overlay;
	plot(tradesforhidden tradesforhidden_s) * date/overlay;
	plot(hiddenvol hiddenvol_s) * date/overlay;
	plot(tradevolforhidden tradevolforhidden_s) * date/overlay;
	plot(cancels cancels_s) * date/overlay;
	plot(littrades littrades_s) * date/overlay;
	plot(oddlots oddlots_s) * date/overlay;
	plot(tradesforoddlots tradesforoddlots_s)*date/overlay;
	plot(oddlotVol oddlotVol_s) * date/overlay;
	plot(tradevolforoddlots tradevolforoddlots_s) * date/overlay;
	plot(cancel_to_trade cancel_to_trade_s) * date/overlay;
	plot(trade_to_order_volume trade_to_order_volume_s) * date/overlay;
	plot(hidden_rate hidden_rate_s) * date/overlay;
	plot(hidden_volume hidden_volume_s) * date/overlay;
	plot(oddlot_rate oddlot_rate_s) * date/overlay;
	plot(oddlot_volume oddlot_volume_s) * date/overlay;
run;

proc gplot data = work.stats100_p50;
	title "P50 of Sample Data";
	plot(litvol litvol_s)*date/overlay;
	plot(ordervol ordervol_s) * date/overlay;
	plot(hidden hidden_s) * date/overlay;
	plot(tradesforhidden tradesforhidden_s) * date/overlay;
	plot(hiddenvol hiddenvol_s) * date/overlay;
	plot(tradevolforhidden tradevolforhidden_s) * date/overlay;
	plot(cancels cancels_s) * date/overlay;
	plot(littrades littrades_s) * date/overlay;
	plot(oddlots oddlots_s) * date/overlay;
	plot(tradesforoddlots tradesforoddlots_s)*date/overlay;
	plot(oddlots oddlots_s) * date/overlay;
	plot(tradevolforoddlots tradevolforoddlots_s) * date/overlay;
	plot(cancel_to_trade cancel_to_trade_s) * date/overlay;
	plot(trade_to_order_volume trade_to_order_volume_s) * date/overlay;
	plot(hidden_rate hidden_rate_s) * date/overlay;
	plot(hidden_volume hidden_volume_s) * date/overlay;
	plot(oddlot_rate oddlot_rate_s) * date/overlay;
	plot(oddlot_volume oddlot_volume_s) * date/overlay;
run;

proc gplot data = work.stats100_p75;
	title "P75 of Sample Data";
	plot(litvol litvol_s)*date/overlay;
	plot(ordervol ordervol_s) * date/overlay;
	plot(hidden hidden_s) * date/overlay;
	plot(tradesforhidden tradesforhidden_s) * date/overlay;
	plot(hiddenvol hiddenvol_s) * date/overlay;
	plot(tradevolforhidden tradevolforhidden_s) * date/overlay;
	plot(cancels cancels_s) * date/overlay;
	plot(littrades littrades_s) * date/overlay;
	plot(oddlots oddlots_s) * date/overlay;
	plot(tradesforoddlots tradesforoddlots_s)*date/overlay;
	plot(oddlots oddlots_s) * date/overlay;
	plot(tradevolforoddlots tradevolforoddlots_s) * date/overlay;
	plot(cancel_to_trade cancel_to_trade_s) * date/overlay;
	plot(trade_to_order_volume trade_to_order_volume_s) * date/overlay;
	plot(hidden_rate hidden_rate_s) * date/overlay;
	plot(hidden_volume hidden_volume_s) * date/overlay;
	plot(oddlot_rate oddlot_rate_s) * date/overlay;
	plot(oddlot_volume oddlot_volume_s) * date/overlay;
run;


proc gplot data = work.stats100_std;
	title "SD of Sample Data";
	plot(litvol litvol_s)*date/overlay;
	plot(ordervol ordervol_s) * date/overlay;
	plot(hidden hidden_s) * date/overlay;
	plot(tradesforhidden tradesforhidden_s) * date/overlay;
	plot(hiddenvol hiddenvol_s) * date/overlay;
	plot(tradevolforhidden tradevolforhidden_s) * date/overlay;
	plot(cancels cancels_s) * date/overlay;
	plot(littrades littrades_s) * date/overlay;
	plot(oddlots oddlots_s) * date/overlay;
	plot(tradesforoddlots tradesforoddlots_s)*date/overlay;
	plot(oddlots oddlots_s) * date/overlay;
	plot(tradevolforoddlots tradevolforoddlots_s) * date/overlay;
	plot(cancel_to_trade cancel_to_trade_s) * date/overlay;
	plot(trade_to_order_volume trade_to_order_volume_s) * date/overlay;
	plot(hidden_rate hidden_rate_s) * date/overlay;
	plot(hidden_volume hidden_volume_s) * date/overlay;
	plot(oddlot_rate oddlot_rate_s) * date/overlay;
	plot(oddlot_volume oddlot_volume_s) * date/overlay;
run;


ods rtf close;

