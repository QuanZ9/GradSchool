/***********************/
/**   Assignment 3    **/
/**   Quan Zhou       **/
/***********************/

options ls = 70 nodate nocenter;
*set data and lib path;
%Let path = Q:\Data-ReadOnly\CRSP;
%let Opath = P:\Management_of_Financial_Institutions\hw3;
Libname hw3 "&path";
%let DSF = hw3.dsf;
%let DSI = hw3.dsi;
%let year_s = 2005;
%let year_e = 2014;


/***************************************************/
/**                macros                         **/
/***************************************************/

*compute stats;
%macro comp_stats(dataset, vars);
proc means data = &dataset;
	var &vars;
	output out = &dataset._mean mean= ;
	output out = &dataset._std std = ;
	output out = &dataset._p25 p25 = ;
	output out = &dataset._p50 p50 = ;
	output out = &dataset._p75 p75 = ;
	output out = &dataset._max max = ;
	output out = &dataset._min min = ;
run;
%mend;

*plot;
%macro plotdate(dataset, var1, var2= . );
proc sgplot data = &dataset;
	%do i = 1 %to %sysfunc(countw(&var1));
		%let fvariable = %qscan(&var1, &i, %str(" "));
		series x=date y=&fvariable;
	%end;
	if &var2 ne . do;
	%do i = 1 %to %sysfunc(countw(&var2));
		%let fvariable = %qscan(&var2, &i, %str(" "));
		series x=date y=&fvariable / y2axis;
	%end;
	end;
run;
%mend;


*plot quintile;
%macro plotquintile(dataset, vars);
%do i = 1 %to %sysfunc(countw(&vars));
	%let fvariable = %qscan(&vars, &i, %str(" "));
	title1 "&fvariable";
	proc sgplot data = &dataset;
		series x = date y = &fvariable / group = q;
	run;
%end;
%mend;

*compute quintile;
%macro quintile(orig, new, var, quintvar);
proc univariate noprint data=&orig;
  var &var;
  output out=quintile pctlpts=20 40 60 80 pctlpre=pct;
run;

data _null_;
	set quintile;
	call symput('q1',pct20) ;
	call symput('q2',pct40) ;
	call symput('q3',pct60) ;
	call symput('q4',pct80) ;
run;

data &new;
	set &orig;
       if &var =. then &quintvar = .;
  else if &var le &q1 then &quintvar=1;
  else if &var le &q2 then &quintvar=2;
  else if &var le &q3 then &quintvar=3;
  else if &var le &q4 then &quintvar=4;
  else &quintvar=5;
run;
%mend quintile;


/****************************************************/
/**         1. read and subset DSF                 **/
/****************************************************/
ods rtf file="&Opath/assignment3.rtf";
*set variables;
%let variables = CUSIP PERMNO PERMCO ISSUNO HEXCD HSICCD DATE RET PRC ASK BID VOL;
%let stat_var = RET PRC SPREAD VOL;

*subset the rawData to 2005 - 2014;
data subSet;
	set &DSF;
	where year(DATE) between &year_s and &year_e;
run;

*set ask-bid spread and price;
data subSet;
	set subSet(keep = &variables);
	SPREAD = ASK - BID;
	PRC = abs(PRC);
	
	label spread = "Bid-Ask Spread";
run;

/***************************************************/
/**        3. compute desciptive statistics       **/
/***************************************************/

*compute descriptive statistics;
title "descriptive statistics of DSF";
%comp_stats(subSet, &stat_var);


/****************************************************/
/**        4. plot time-series patterns            **/
/****************************************************/

*get daily average and plot;
proc sort data = subSet;
by DATE;
run;

proc means data = subSet noprint;
by DATE;
output out = daily mean = ;
run;
title "time series patterns of DSF";
%plotdata(daily, ret);
%plotdata(daily, prc);
%plotdata(daily, spread);
%plotdata(daily, vol);


/*********************************************************/
/**       5. download and read VIX data                 **/
/*********************************************************/

*get VIX data;
filename VIX_url url "https://www.cboe.com/publish/scheduledtask/mktdata/datahouse/vixcurrent.csv";
data VIX;
	infile VIX_url dlm = "," firstobs = 3;
	length date_t $10;
	input date_t $ vix_open vix_high vix_low vix_close;
run;
data VIX;
	set VIX;
	date = input (date_t, mmddyy10.);
	format date mmddyy10.;
	drop date_t;
run;

data VIX;
	set VIX;
	retain vix_change;
	vix_change = vix_close - vix_open;
run;


/**************************************************************/
/** 6. plot and correlate variables with VIS and delta VIX   **/
/**************************************************************/
data daily;
	merge VIX(in = a) daily(in = b);
	by date;
	if a&b;
run;

*plot vix and delta vix with variables in question1;
title "VIX and DSF";
%plotdata(daily, ret, var2 = vix_close vix_change);
%plotdata(daily, prc, var2 = vix_close vix_change);
%plotdata(daily, spread, var2 = vix_close vix_change);
%plotdata(daily, vol, var2 = vix_close vix_change);

*correlation between q1 variables and VIX and delta VIX;
proc corr data = daily;
var &stat_var;
with vix_close vix_change;
run;

proc delete data = daily (gennum = all);
run;


/*****************************************************************/
/**                   7.  CAPM                                  **/
/*****************************************************************/

*get market return;
data subset_dsi;
	set &DSI(keep = date sprtrn);
	where year(DATE) between &year_s and &year_e;
run;

*merge market return and CRSP data;
data subSet2;
	merge subset_dsi subSet;
	by date;
run;

proc sort data = subSet2;
by PERMNO;
run;

*find beta for each stock by linear regression;
proc reg data = subSet2 noprint outest = reg;
	by PERMNO;
	model ret = sprtrn;
run;

data reg;
	set reg;
	rename sprtrn = beta;
	rename intercept = alpha;
	drop _type_ _model_;
run;


*compute volatility;
*get market volatility;
proc means data = subset_dsi noprint;
var sprtrn;
output out = dsi_std std = spstd;
label spstd = "SP500_standart_deviation";
run;

proc means data = subSet2 noprint;
var ret sprtrn prc vol;
by PERMNO;
output out = subSet2_company std= mean= p50= /autoname ;
run;

data company;
	merge subSet2_company(rename = (ret_stddev=risk sprtrn_stddev=mkt_risk) keep=ret_stddev sprtrn_stddev PERMNO) reg(keep=beta PERMNO);
	by PERMNO;
	retain idio_risk;
	idio_risk = sqrt(risk*risk - beta * beta * mkt_risk * mkt_risk);
	mkt_risk_b = beta * mkt_risk;
	drop _type_ _freq_ _depvar_ _rmse_ ret;
run;

*systematic volatility quintile portfolios;
proc sort data = company;
	by mkt_risk_b;
run;

%quintile(company, quintile, mkt_risk_b, q);

proc sort data=quintile;
by PERMNO;
run;

data quintilePort;
	merge quintile(keep=PERMNO q) subset2(keep = PERMNO ret vol date);
	by PERMNO;
run;

proc sort data = quintilePort;
	by q date;
run;

proc means data=quintilePort noprint;
var ret vol;
where q ne .;
by q date;
output out = quintileStat mean= p50=/autoname;
run;

title "systematic volatility quintile portfolios";
%plotquintile(quintileStat, ret_mean ret_p50 vol_mean vol_p50);

*idiosyncratic volatility quintile portfolios;
proc sort data = company;
	by idio_risk;
run;

%quintile(company, quintile, idio_risk, q);

proc sort data=quintile;
by PERMNO;
run;

data quintilePort;
	merge quintile(keep=PERMNO q) subset2(keep = PERMNO ret vol date);
	by PERMNO;
run;

proc sort data = quintilePort;
	by q date;
run;

proc means data=quintilePort noprint;
var ret vol;
where q ne .;
by q date;
output out = quintileStat mean= p50=/autoname;
run;
title "idiosyncratic volatility quintile portfolios";
%plotquintile(quintileStat, ret_mean ret_p50 vol_mean vol_p50);

ods rtf close;
