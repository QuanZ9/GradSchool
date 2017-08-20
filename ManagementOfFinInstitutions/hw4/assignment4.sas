Libname L_FUNDA "Q:\Data-ReadOnly\COMP";
Libname L_DSF "Q:\Data-ReadOnly\CRSP";
%Let fundaR = L_FUNDA.funda;
%Let dsfR = L_DSF.dsf;

%let Opath = P:\Management_of_Financial_Institutions\hw4\output\;

%let yearS = 1970;
%let yearE = 2014;

/******************************************************/
/**                     Macros                       **/
/******************************************************/
%macro compstats(dataset, var);
proc means data = &dataset n mean std min max p25 p50 p75 noprint;
	var &var;
	output out = &dataset._mean mean=;
	output out = &dataset._std std=;
	output out = &dataset._min min=;
	output out = &dataset._max max=;
	output out = &dataset._p25 p25=;
	output out = &dataset._p50 p50=;
	output out = &dataset._p75 p75=;
	by year;
run;

*format output;
title2 "mean";
%tabular(&dataset._mean, &var, mean);
title2 "p25";
%tabular(&dataset._p25, &var, p25);
title2 "p50";
%tabular(&dataset._p50, &var, p50);
title2 "p75";
%tabular(&dataset._p75, &var, p75);
title2 "standard deviation";
%tabular(&dataset._p75, &var, std);
title2 "min";
%tabular(&dataset._p75, &var, min);
title2 "max";
%tabular(&dataset._p75, &var, max);
%mend;

*macro for format output;
%macro tabular(dataset, variables, statsType);
*%replaceMissing(&dataset);
proc tabulate data = &dataset;
	var _freq_ &variables;
	class year;
	table _freq_ = 'Number of Oservations' &variables, year="Year --- &statsType"*mean='';
run;
%mend;

*plot data;
%macro plotdata(dataset, var, var2 = .);
proc sgplot data = &dataset;
	%do i = 1 %to %sysfunc(countw(&var));
		%let v = %qscan(&var, &i, %str(" "));
		series x=year y=&v;
		
	%end;
	%if &var2 ne . %then %do;
		series x=year y=&var2 / y2axis;
	%end;
run;
%mend;

%macro plotstats(dataset, var, stats);
%do i = 1 %to %sysfunc(countw(&stats));
	%let stat = %scan(&stats, &i, %str(" "));
	title "&stat of DD for two measures over time";
	proc sgplot data = &dataset._&stat;
		%do j = 1 %to %sysfunc(countw(&var));
			%let v = %scan(&var, &j, %str(" "));
			series x=year y=&v;
		%end;
	run;
%end;
%mend;

%macro solve(dataset);
%if %sysfunc(exist(solve)) %then %do;
	proc delete data = solve (gennum = all);
	run;
%end;


%do i = &yearS %to &yearE;
	proc model data = &dataset(where =(year = &i)) out = tmp noprint converge = 0.001;
		exogenous E F sigmAE AnnRet r;
		endogenous sigmV V;

		eq.e1 = V * CDF('Normal', (log(V/F) + r) / sigmV + 0.5 * sigmV) - exp(-r) * F * CDF('Normal', (log(V/F) + r) / sigmV - 0.5 * sigmV) - E;
		eq.e2 = V/E * CDF('Normal', (log(V/F) + r) / sigmV + 0.5 * sigmV) * sigmV - sigmAE;
		solve sigmV V;
		id CUSIP YEAR;
	quit;

	%if %sysfunc(exist(solve)) %then %do;
		data solve;
			set solve tmp;
		run;
	%end;
	%else %do;
		data solve;
			set tmp;
		run;
	%end;
%end;
%mend;
/******************************************************/
/**       4.0      Preparing Data                    **/
/******************************************************/
*subset funda;
data funda;
	set &fundaR(keep = GVKEY CUSIP DLC DLTT indfmt datafmt popsrc fic consol datadate);
	where indfmt = 'INDL' and datafmt = 'STD' and popsrc='D' and fic ='USA' and consol='C' 
			and year(datadate) >= &yearS and year(datadate) <= &yearE;
	YEAR = year(datadate) + 1;
	CUSIP = substr(CUSIP,1,8);
	DLC = DLC * 1000000;
	DLTT = DLTT * 1000000;
	F = DLC + 0.5 * DLTT;
	if F eq 0 or F eq . then delete;
	label F = "Default boundary";
	keep GVKEY CUSIP YEAR DLC DLTT F;
run;

*subset dsf;
data dsf;
	set &dsfR(keep = CUSIP DATE PRC SHROUT RET);
	where year(DATE) >= &yearS and year(DATE) <= &yearE and PRC ne . and RET ne .;
	YEAR = year(DATE) + 1;
	SHROUT = SHROUT*1000;
	E = abs(PRC) * SHROUT;
	drop date;
run;
*calculate std and cumulative return;
PROC SQL; 
	CREATE TABLE dsf1 as 
	SELECT CUSIP, YEAR, MEAN(E) as E, EXP(SUM(LOG(1+ret)))-1 as AnnRet, STD(ret)*SQRT(250) as SigmAE 
	FROM DSF
	GROUP BY cusip, year; 
QUIT;

*merge dsf and funda;
proc sort data = funda;
by CUSIP YEAR;
run;
proc sort data = dsf1;
by CUSIP YEAR;
run;
data dsf_funda;
	merge dsf1(in=a) funda(in=b);
	by CUSIP YEAR;
	keep CUSIP YEAR AnnRet SigmAE F E;
	if a and b;
run;

*delete used dataset;
/*proc delete data = funda (gennum = all);*/
/*run;*/
/*proc delete data = dsf (gennum = all);*/
/*run;*/
/*proc delete data = dsf1 (gennum = all);*/
/*run;*/


*get DailyFed;
filename DailyFed url "https://research.stlouisfed.org/fred2/data/DTB3.txt";
data rf;
	infile DailyFed firstobs = 13;
	input @1 date yymmdd10. @12 rf;
	year = year(date);
	r = log(1 + rf / 100);
	if rf ne .;
	drop date rf;
run;
proc sort nodupkey data = rf;
by year;
run;

*merge DailyFed with funda and dsf;
proc sort data = dsf_funda;
by year;
run;
data origData;
	merge rf(in=a) dsf_funda(in=b);
	by year;
	if a and b;
run;

data origData;
	set origData;
	if cmiss(of _all_) then delete;
	else if AnnRet = 0 then delete;
	else if SigmAE = 0 then delete;
	else if E = 0 then delete;
run;

proc sort data = origData;
by CUSIP YEAR;
run;

/*proc delete data = dsf_funda (gennum = all);*/
/*run;*/
/*proc delete data = rf (gennum = all);*/
/*run;*/

*get nber;
filename nberWeb url "https://research.stlouisfed.org/fred2/data/USREC.txt";
data nber;
	infile nberWeb firstobs = 72;
	input @1 date yymmdd10. @12 nber_v;
	year = year(date) + 1;
	drop date;
run;
*convert to yearly NBER data;
proc means data = nber noprint;
by year;
output out = nber mean=;
run;
data nber;
	set nber;
	if nber_v ge 0.5 then nber_v = 1;
	else nber_v = 0;
	keep year nber_v;
run;

*get BAAFFM;
filename baaWeb url "https://research.stlouisfed.org/fred2/data/BAAFFM.txt";
data baa;
	infile baaWeb firstobs = 16;
	input @1 date yymmdd10. @12 baa_v;
	year = year(date) + 1;
	drop date;
run;
*convert to yearly BAAFFM data;
proc means data = baa noprint;
by year;
output out = baa(keep=year baa_v) mean=;
run;

*get CFSI;
filename cfsiWeb url "https://research.stlouisfed.org/fred2/data/CFSI.txt";
data cfsi;
	infile cfsiWeb firstobs = 35;
	input @1 date yymmdd10. @12 cfsi_v;
	year = year(date) + 1;
	drop date;
run;
*convert to yearly CFSI data;
proc means data = cfsi noprint;
by year;
output out = cfsi(keep = year cfsi_v) mean=;
run;

/*************************************************************/
/**                4.1 Naive Method                         **/
/*************************************************************/
data m1;
	set origData;
	sigmD1 = 0.05 + 0.25 * sigmAE;
	sigmD2 = 0.05 + 0.5 * sigmAE;
	sigmD3 = 0.25 * sigmAE;

	sigmV1 = E / (E + F) * sigmAE + F / (E + F) * sigmD1;
	sigmV2 = E / (E + F) * sigmAE + F / (E + F) * sigmD2;
	sigmV3 = E / (E + F) * sigmAE + F / (E + F) * sigmD3;

	m1_DD1 = (log((E+F) / F) + (AnnRet - 0.5 * sigmV1**2)) / sigmV1;
	m1_DD2 = (log((E+F) / F) + (AnnRet - 0.5 * sigmV2**2)) / sigmV2;
	m1_DD3 = (log((E+F) / F) + (AnnRet - 0.5 * sigmV3**2)) / sigmV3;

	m1_PD1 = CDF('Normal', -m1_DD1);
	m1_PD2 = CDF('Normal', -m1_DD2);
	m1_PD3 = CDF('Normal', -m1_DD3);
	
	drop sigmD1-sigmD3 sigmV1-sigmV3;
run;


/***********************************************************/
/**                 4.2 Direct solving                    **/
/***********************************************************/
data m2_0;
	set origdata;
	V = E+F;
	sigmV = E / (E + F) * sigmAE + F / (E + F) * (0.05 + 0.25 * sigmAE);
run;
proc sort data = m2_0;
by YEAR CUSIP;
run;

proc model data = m2_0 out = solve seidel noprint;
/*	exogenous E F sigmAE AnnRet r;*/
/*	endogenous sigmV V;*/
	bounds sigmV > 0;
	eq.e1 = V * CDF('Normal', (log(V/F) + r) / sigmV + 0.5 * sigmV) - exp(-1.0* r) * F * CDF('Normal', (log(V/F) + r) / sigmV - 0.5 * sigmV) - E;
	eq.e2 = V/E * CDF('Normal', (log(V/F) + r) / sigmV + 0.5 * sigmV) * sigmV - sigmAE;
	solve V sigmV;
	id CUSIP YEAR;
quit;

/*%solve(m2_0);*/

proc sort data = solve;
by CUSIP YEAR;
run;
data m2_0;
	merge origdata(in=a) solve(in=b);
	by CUSIP YEAR;
	if a and b;
	drop _TYPE_ _MODE_ _ERRORS_;
run;

data m2;
	set m2_0;
	m2_DD = (log(V/F) + (AnnRet - 0.5 * sigmV**2)) / sigmV; 
	m2_PD = CDF('Normal', -m2_DD);
	keep CUSIP YEAR m2_DD m2_PD;
run;

/*proc delete data = solve (gennum = all);*/
/*run;*/
/*proc delete data = m2_0 (gennum = all);*/
/*run;*/

/***************************************************************/
/**                     4.1 & 4.2                             **/
/***************************************************************/
ods rtf file = "&Opath.assignment41_42.rtf";
*merge m1 and m2;
proc sort data = m1;
by YEAR CUSIP;
run;
proc sort data = m2;
by YEAR CUSIP;
run;
data m1m2;
	merge m1 m2;
	by YEAR CUSIP;
run;

*3.compute stats of two DD and PD measures;
title "Statistics for the two DD and PD measures";
proc sort data = m1m2;
by year;
run;
%compstats(m1m2, m1_DD1 m1_PD1 m1_DD2 m1_PD2 m1_DD3 m1_PD3 m2_DD m2_PD);

*4.compute correlation;
title "Correlations between two methods of DD and PD";
proc corr data = m1m2 noprob;
	var m1_DD1 m1_PD1 m2_DD m2_PD;
run;


*5.plot DD and PD over time;
%plotstats(m1m2, m1_DD1 m1_DD2 m1_DD3 m2_DD, mean p25 p50 p75);

*plot with nber baaffm cfsi;
data m1m2_nbc;
	merge m1m2_mean(in=a) nber baa cfsi;
	by year;
	if a;
run;

*6.with nber;
title "Mean of DD with NBER";
%plotdata(m1m2_nbc, m1_DD1 m1_DD2 m1_DD3 m2_DD, var2=nber_v);
title "Mean of PD with NBER";
%plotdata(m1m2_nbc, m1_PD1 m1_PD2 m1_PD3 m2_PD, var2=nber_v);

*7.with baaffm;
title "Mean of DD with BAAFFM";
%plotdata(m1m2_nbc,m1_DD1 m1_DD2 m1_DD3 m2_DD, var2=baa_v);
title "Mean of PD with BAAFFM";
%plotdata(m1m2_nbc, m1_PD1 m1_PD2 m1_PD3 m2_PD, var2=baa_v);

*8.with cfsi;
title "Mean of DD with CFSI";
%plotdata(m1m2_nbc, m1_DD1 m1_DD2 m1_DD3 m2_DD, var2=cfsi_v);
title "Mean of PD with CFSI";
%plotdata(m1m2_nbc, m1_PD1 m1_PD2 m1_PD3 m2_PD, var2=cfsi_v);

ods rtf close;

/****************************************************************/
/**                  4.3 Iterative method                      **/
/****************************************************************/

/**compute m3;*/
/**set sigmaV0;*/
/*data m3_0;*/
/*	set dsf_funda;*/
/*	sigmV = sigmE;*/
/*run;*/
/**/
/**get daily data;*/
/*proc sort data = m3_0;*/
/*by YEAR CUSIP;*/
/*run;*/
/*proc sort data = dsf;*/
/*by YEAR CUSIP;*/
/*run;*/
/*proc sort data = funda;*/
/*by YEAR CUSIP;*/
/*run;*/
/*data m3_d;*/
/*	merge m3_0 dsf funda;*/
/*	by YEAR CUSIP;*/
/*run;*/
/**solve V0;*/
/*proc model data = m3_d noprint;*/
/*	exogenous E F sigmAE AnnRet sigmV;*/
/*	endogenous V;*/
/*	eq.e1 = V * CDF('Normal', (log(V/F) + (AnnRet + 0.5 * sigmV**2)) / sigmV) - e**(-r) * F * CDF('Normal', (log(V/F) + (AnnRet - 0.5 * sigmV**2)) / sigmV) - E;*/
/*	solve V;*/
/*	id CUSIP YEAR;*/
/*quit;*/
/**/
/*proc means data = m3_0;*/
/*var V;*/
/*output out = m3_0_std std=;*/
/*run;*/
	

*compute correlation;



*plot three method overtime;

