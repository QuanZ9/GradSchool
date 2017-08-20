Libname L_DSF "Q:\Data-ReadOnly\CRSP";
Libname hw6 "P:\Management_of_Financial_Institutions\hw6";
%Let dsfR = L_DSF.dsf;


%let Opath = P:\Management_of_Financial_Institutions\hw6\output\;

/******************************************************/
/**                     Macros                       **/
/******************************************************/
%macro print(dataset);
proc print data = &dataset(obs=100);
run;
%mend;

*compute VaR and ES from yearS to yearE. Output with suffix;
%macro varEs(yearS, yearE, suffix);
%let init_cash = 500000;
*compute stock return;
data temp;
	set dsf(where=(year(DATE) between &yearS and &yearE));
	retain port_val &init_cash;
	by PERMNO;
	port_val = port_val * (1+ret);
	if first.PERMNO then do;
		port_val = &init_cash*(1+ret);
	end;
run;
*compute portfolio value;
proc sort data = temp;
by DATE;
run;
proc means data = temp noprint;
by DATE;
var port_val;
output out = portfolio(keep = DATE port_val) sum=;
run;
data portfolio;
	set portfolio;
	port_ret = dif(port_val) / lag(port_val);
	port_change = dif(port_val);
run;
*compute VaR;
title "VaR between &yearS - &yearE";
proc sort data = portfolio;
by descending port_ret;
run;
proc means data = portfolio p5;
var port_ret;
output out = ret_var_&suffix.(keep = retVar) p5= retVar;
run;
*compute $VaR;
title "$VaR between &yearS - &yearE";
proc sort data = portfolio;
by descending port_change;
run;
proc means data = portfolio p5;
var port_change;
output out = val_var_&suffix.(keep=valVar) p5=valVar;
run;
*compute ES;
title "ES between &yearS - &yearE";
data ret_var_&suffix;
	set ret_var_&suffix;
	call symput('returnVar',trim(left(retVar)));
run;
data subPort;
	set portfolio;
	if port_ret < &returnVar;
run;
proc means data = subPort mean;
var port_ret;
output out = es_&suffix mean=;
run;
%mend;


/*******************************************************/
/**                 6.0 Prepare data                  **/
/*******************************************************/
*subset dsf;
/*data hw6.dsf;*/
/*	set &dsfR(keep = PERMNO RET DATE);*/
/*	where (PERMNO = 12490 or PERMNO = 12060);*/
/*run;*/

data dsf;
	set hw6.dsf;
run;

ods rtf file = "&Opath/assignment6.rtf";
/******************************************************/
/**         6.1 VaR $VaR ES 2001-2006                **/
/******************************************************/
%varEs(2001,2006, 1);


/****************************************************/
/**         6.2  VaR $VaR ES 2001-2009             **/
/****************************************************/
%varEs(2001,2009, 2);


/****************************************************/
/**         6.3 volatility forecast                **/
/****************************************************/
data train;
	set dsf(where=(year(DATE) between 1996 and 2000));
	ret2 = ret*ret;
run;
proc sort data = train;
by PERMNO;
run;
*compute initial variance;
proc means data = train noprint;
by PERMNO;
var ret;
output out = init(keep=PERMNO std_dev mean_ret) stddev=std_dev mean = mean_ret;
run;
data init;
	set init;
	variance = std_dev*std_dev;
run;
data test;
	set dsf(where=(year(DATE) between 2001 and 2009));
	ret2 = ret*ret;
run;

data test;
	merge test init;
	by PERMNO;
run;
*predict volatility;
data P3;
	set test;
	by PERMNO;
	retain predict_Vol;
	predict_Vol = 0.94*predict_Vol + 0.06*lag(ret2);
	if first.PERMNO then do;
		predict_Vol = 0.94*variance + 0.06*mean_ret*mean_ret;
	end;
run;

*plot;
title "predict volatility";
proc sgplot data = P3;
	by PERMNO;
	series x=DATE y = predict_Vol;
run;


/****************************************************/
/**            6.4 6.5 GARCH model                 **/
/****************************************************/
*solve garch model;
title "GARCH model";
proc autoreg data=train outest = P4;
	model ret2 = / garch=(q=1,p=1) maxit=50;
	by PERMNO;
run;

*compute time series;
data temp;
	merge P4(keep = PERMNO _AH_0 _AH_1 _GH_1) P3 init;
	by PERMNO;
run;
data P5;
	set temp;
	by PERMNO;
	retain garch_vol;
	garch_vol = _AH_0 + _GH_1 * garch_vol + _AH_1 * lag(ret2);
	if first.PERMNO then garch_vol = _AH_0 + _GH_1 * variance + _AH_1 * mean_ret*mean_ret;
run;
*plot;
proc sgplot data = P5;
	by PERMNO;
	series x = DATE y = garch_vol;
	series x = DATE y = predict_Vol;
run;

ods rtf close;
