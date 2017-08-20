/** HEADER  **/
OPTIONS ls=70;

LIBNAME qcf "P:\Management_of_Financial_Institutions\hw2\";

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

*s&p500;
%readCSV("P://Management_of_Financial_Institutions/hw2/SP500daily_return.csv", work.SP500);

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

/** format date  **/
data work.rawdata;
	set work.rawdata;
	Date = input(put(DATE, 8.), yymmdd8.);
	FORMAT Date yymmdd8.;
run;


data work.sp500;
	set work.sp500;
	Date = input(put(DATE, 8.), yymmdd8.);
	FORMAT Date yymmdd8.;
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
proc means data=work.stocks median;
	by Date;
	output out=work.stock_median median=;
run;

proc means data=work.etfs median;
	by Date;
	output out=work.etf_median median=;
run;



/** sort the data by Date  **/
proc sort data=work.stocks;
	by Date;
run;

proc sort data=work.etfs;
	by Date;
run;

proc sort data=work.sp500;
	by Date;
run;


/** merge MIDAS data with S&P500  **/
data stock_SP500;
	merge work.stock_median work.sp500;
	by Date;
run;

data etf_SP500;
	merge work.etf_median work.sp500;
	by Date;
run;



ods rtf file = "P://Management_of_Financial_Institutions/hw2/assignment2.rtf";

/** compute correlations  **/
title "correlation of stocks and SP500";
proc corr data=stock_SP500;

	var litvol ordervol hidden tradesforhidden hiddenvol tradevolforhidden cancels littrades oddlots 
		tradesforoddlots oddlotVol tradevolforoddlots cancel_to_trade trade_to_order_volume hidden_rate 
		hidden_volume oddlot_rate oddlot_volume sprtrn;
	with sprtrn;
run;

title "correlation of etfs and SP500";
proc corr data=etf_SP500;
	var litvol ordervol hidden tradesforhidden hiddenvol tradevolforhidden cancels littrades oddlots 
		tradesforoddlots oddlotVol tradevolforoddlots cancel_to_trade trade_to_order_volume hidden_rate 
		hidden_volume oddlot_rate oddlot_volume sprtrn;
	with sprtrn;
run;

/**  plot  **/

proc gplot data = work.stock_sp500;
	title "stock_median and SP500_return";
	symbol interpol=spline;
	plot(litvol)*date;
	 	plot2(sprtrn)*date;
	plot(ordervol) * date;
		plot2(sprtrn)*date;
	plot(hidden) * date;
		plot2(sprtrn)*date;
	plot(tradesforhidden) * date;
		plot2(sprtrn)*date;
	plot(hiddenvol) * date;
		plot2(sprtrn)*date;
	plot(tradevolforhidden) * date;
		plot2(sprtrn)*date;
	plot(cancels) * date;
		plot2(sprtrn)*date;
	plot(littrades) * date;
		plot2(sprtrn)*date;
	plot(oddlots) * date;
		plot2(sprtrn)*date;
	plot(tradesforoddlots)*date;
		plot2(sprtrn)*date;
	plot(oddlotVol) * date;
		plot2(sprtrn)*date;
	plot(tradevolforoddlots) * date;
		plot2(sprtrn)*date;
	plot(cancel_to_trade) * date;
		plot2(sprtrn)*date;
	plot(trade_to_order_volume) * date;
		plot2(sprtrn)*date;
	plot(hidden_rate) * date;
		plot2(sprtrn)*date;
	plot(hidden_volume) * date;
		plot2(sprtrn)*date;
	plot(oddlot_rate) * date;
		plot2(sprtrn)*date;
	plot(oddlot_volume) * date;
		plot2(sprtrn)*date;
run;


proc gplot data = work.etf_sp500;
	title "etf_median and SP500_return";
	symbol interpol=spline;
	plot(litvol)*date;
	 	plot2(sprtrn)*date;
	plot(ordervol) * date;
		plot2(sprtrn)*date;
	plot(hidden) * date;
		plot2(sprtrn)*date;
	plot(tradesforhidden) * date;
		plot2(sprtrn)*date;
	plot(hiddenvol) * date;
		plot2(sprtrn)*date;
	plot(tradevolforhidden) * date;
		plot2(sprtrn)*date;
	plot(cancels) * date;
		plot2(sprtrn)*date;
	plot(littrades) * date;
		plot2(sprtrn)*date;
	plot(oddlots) * date;
		plot2(sprtrn)*date;
	plot(tradesforoddlots)*date;
		plot2(sprtrn)*date;
	plot(oddlotVol) * date;
		plot2(sprtrn)*date;
	plot(tradevolforoddlots) * date;
		plot2(sprtrn)*date;
	plot(cancel_to_trade) * date;
		plot2(sprtrn)*date;
	plot(trade_to_order_volume) * date;
		plot2(sprtrn)*date;
	plot(hidden_rate) * date;
		plot2(sprtrn)*date;
	plot(hidden_volume) * date;
		plot2(sprtrn)*date;
	plot(oddlot_rate) * date;
		plot2(sprtrn)*date;
	plot(oddlot_volume) * date;
		plot2(sprtrn)*date;
run;

ods rtf close;

