Libname L_FUNDA "Q:\Data-ReadOnly\COMP";
Libname L_DSF "Q:\Data-ReadOnly\CRSP";
Libname hw5 "P:\Management_of_Financial_Institutions\hw5";
%Let fundaR = L_FUNDA.funda;
%Let dsfR = L_DSF.dsf;

%let Opath = P:\Management_of_Financial_Institutions\hw4\output\;

%let yearS = 1962;
%let yearE = 2014;

/******************************************************/
/**                     Macros                       **/
/******************************************************/
%macro print(dataset);
proc print data = &dataset(obs=100);
run;
%mend;

*macro for replacing missing value with 0;
%macro replaceMissing(dataset);
proc stdize data = &dataset reponly missing=0 out=&dataset;
run;
%mend;

%macro computeRatios(dataset);
*from Assignment2.1;
data &dataset;
	set &dataset;
	NI_AT = divide(NI,AT);
	LT_AT = divide(LT,AT);
	LOG_AT = log(AT);
run;

*from Assignment2.2 table1;
data &dataset;
	set &dataset;
	CurrentRatio = divide(ACT,LCT);
	QuickRatio = divide((CHE+RECT),LCT);
	DebtEquityRatio = divide(LT,SEQ);
run;
*from Assignment2.2 table2;
data temp;
	set &dataset;
	by gvkey YEAR;
	if first.gvkey then do;
		moving_INVT = .;
		moving_RECT = .;
		moving_AP = .;
	end;
	else do;
		moving_AP = (AP + lag(AP)) / 2;
		moving_INVT = (INVT + lag(INVT)) / 2;
		moving_RECT = (RECT + lag(RECT)) / 2;
	end;
run;
data &dataset;
	set temp;
	DSO = 365 * divide(moving_RECT , SALE);
	DIO = 365 * divide(moving_INVT , COGS);
	DPO = 365 * divide(moving_AP , COGS);
	CCC = DSO + DIO - DPO;
	label DSO = "Days Sales Outstanding"
		DIO = "Days inventory outstanding"
		DPO = "Days payable outstanding"
		CCC = "Cash conversion cycle";
run;
*from Assignment2.2 table3;
data temp;
	set &dataset;
	by gvkey YEAR;
	if first.gvkey then do;
		moving_AT = .;
		moving_INVT = .;
		moving_RECT = .;
	end;
	else do;
		moving_AT = (AT + lag(AT)) / 2;
		moving_INVT = (INVT + lag(INVT)) / 2;
		moving_RECT = (RECT + lag(RECT)) / 2;
	end;
run;
data &dataset;
	set temp;
	TAT_ = divide(SALE , moving_AT);
	IT_ = divide(COGS , moving_INVT);
	RT_ = divide(SALE , moving_RECT);

	label TAT_ = "Total asset turnover"
		IT_ = "Inventory turnover"
		RT_ = "Receivable turnover";
run;
*from Assignment2.2 table4;
data &dataset;
	set &dataset;
	IB_ = divide((OIADP - XINT),OIADP);
	IC_ = divide(OIADP,XINT);
	Leverage = divide(AT,SEQ);

	label IB_ = "Interest burden"
		IC_ = "Interest coverage "
		Leverage = "Leverage";
run;
*from Assignment2.2 table5;
data temp;
	set &dataset;
	by gvkey YEAR;
	if first.gvkey then do;
		moving_AT = .;
		moving_SEQ = .;
	end;
	else do;
		moving_AT = (AT + lag(AT)) / 2;
		moving_SEQ = (SEQ + lag(SEQ)) / 2;
	end;
run;
data &dataset;
	set temp;
	ROA_ = divide(OIADP , moving_AT);
	ROE_ = divide(NI , moving_SEQ);
	ROS_ = divide(OIADP , SALE);
 
	label ROA_ = "Return on assets"
		ROE_ = "Return on equity "
		ROS_ = "Return on sales(Profit margin)";
run;
%mend;

%macro predict_between(start, end);
%if %sysfunc(exist(out_sample_t)) %then %do;
	proc delete data = out_sample_t (gennum = all);
	run;
%end;

%do i = &start %to &end;
	%predict(&i);
%end; 
%mend;

%macro predict(tyear);
*in-sample model;
proc logistic data = dsf_funda_dft(where=(year < &tyear)) descending outmodel = logModel noprint;
	output out = in_sample predicted = prob;
	model DFT = &vars;
run;

*use in-sample model to test out-of-sample data;
proc logistic inmodel = logModel;
	score data=dsf_funda_dft(where=(year = &tyear)) out = out_sample;
run;

%if %sysfunc(exist(out_sample_t)) %then %do;
	data out_sample_t;
		set out_sample_t out_sample;
	run;
%end;
%else %do;
	data out_sample_t;
		set out_sample;
	run;
%end;
%mend;

/******************************************************/
/**             0. Preparing Data                    **/
/******************************************************/
*set variables;
%let origVar = ACT LCT CHE RECT LT SEQ SALE INVT COGS AP AT OIADP XINT OIADP NI;
*%let vars = sigmAE AnnRet CurrentRatio QuickRatio DebtEquityRatio DSO DIO DPO CCC TAT_ IT_ RT_ IB_ IC_ Leverage ROA_ ROE_ ROS_ E F NI_AT LOG_AT LT_AT;
%let vars = sigmAE AnnRet CurrentRatio TAT_ ROA_ r NI_AT LOG_AT LT_AT;
*subset funda;
data funda;
	set &fundaR(keep = GVKEY CUSIP DLC DLTT indfmt datafmt popsrc fic consol datadate &origVar);
	where indfmt = 'INDL' and datafmt = 'STD' and popsrc='D' and fic ='USA' and consol='C' 
			and year(datadate) >= &yearS and year(datadate) <= &yearE;
	YEAR = year(datadate) + 1;
	DLC = DLC * 1000000;
	DLTT = DLTT * 1000000;
	F = DLC + 0.5 * DLTT;
	CUSIP = substr(CUSIP,1,8);
	if F eq 0 or F eq . then delete;
	label F = "Default boundary";
	keep GVKEY CUSIP YEAR DLC DLTT F &origVar;
run;

data funda1;
	set funda;
run;

*compute ratios;
%computeRatios(funda1);

*subset dsf;
data dsf;
	set &dsfR(keep = CUSIP PERMNO DATE PRC SHROUT RET);
	where year(DATE) >= &yearS and year(DATE) <= &yearE and PRC ne . and RET ne .;
	YEAR = year(DATE) + 1;
	SHROUT = SHROUT*1000;
	E = abs(PRC) * SHROUT;
	keep CUSIP PERMNO DATE YEAR RET E;
run;
*calculate std and cumulative return;
PROC SQL; 
	CREATE TABLE dsf1 as 
	SELECT CUSIP, YEAR, MEAN(PERMNO) as PERMNO, MEAN(E) as E, EXP(SUM(LOG(1+ret)))-1 as AnnRet, STD(ret)*SQRT(250) as SigmAE 
	FROM DSF
	GROUP BY cusip, year; 
QUIT;

*merge dsf and funda;
proc sort data = funda1;
by CUSIP YEAR;
run;
proc sort data = dsf1;
by CUSIP YEAR;
run;

data dsf_funda;
	merge dsf1(in=a) funda1(in=b);
	by CUSIP YEAR;
	EF_ = E/F;
	sigmD1 = 0.05 + 0.25 * sigmAE;
	sigmV1 = E / (E + F) * sigmAE + F / (E + F) * sigmD1;
	DD = (log((E+F) / F) + (AnnRet - 0.5 * sigmV1**2)) / sigmV1;
	keep CUSIP PERMNO YEAR &vars;
	if a and b;
run;

*import bankruptcy data;
proc import datafile="Q:\Data-ReadOnly\SurvivalAnalysis\BR1964_2014.csv"
     out=BR1964_2014
     dbms=csv
     replace;
     getnames=yes;
run;
*set default flag;
data BR1964_2014;
	set BR1964_2014;
	YEAR = year(bankruptcy_dt);
	DFT = 1;
	label DFT="default";
run;

*merge dsf funda and default data;
proc sort data = dsf_funda;
by PERMNO YEAR;
run;
proc sort data = BR1964_2014;
by PERMNO YEAR;
run;
data dsf_funda;
	set dsf_funda;
	if cmiss(of _all_) then delete;
run;
data dsf_funda_dft;
	merge dsf_funda(in=a) BR1964_2014(in=b);
	by PERMNO YEAR;
	keep CUSIP PERMNO YEAR DFT &vars;
	if a;
run;
data dsf_funda_dft;
	set dsf_funda_dft;
	by PERMNO;
	retain flag 0;
	if first.PERMNO then do;
		flag=0;
	end;
	if DFT ne 1 and flag=0 then do;
		DFT=0;
		output;
	end;
	else if DFT=1 then do;
		DFT=1;
		flag=1;
		output;
	end;
	drop flag;
run;
*get interest rate;
filename DailyFed url "https://research.stlouisfed.org/fred2/data/DTB3.txt";
data daily_rf;
	infile DailyFed firstobs = 13;
	input @1 date yymmdd10. @12 rf;
	year = year(date);
	r = log(1 + rf / 100)*100;
	if rf ne .;
	drop rf;
run;

proc sort nodupkey data = daily_rf(drop = date) out=rf;
by year;
run;
proc sort data=dsf_funda_dft;
by year;
run;
data dsf_funda_dft;
	merge dsf_funda_dft(in=a) rf(in=b);
	by year;
	if a;
run;

/****************************************************************/
/**                   1. All years in-sample                   **/
/****************************************************************/
ods rtf file="P:\Management_of_Financial_Institutions\hw5\output\Assignment51.rtf";
*logistic regression;
proc logistic data = dsf_funda_dft descending;
	output out = logistic predicted = prob;
	model DFT = &vars;
run;

/***************************************************************/
/**                 2. in-sample and out-of-sample            **/
/***************************************************************/
%predict_between(1991,2014);

*rank into 10 groups according to probability(dft=1);
proc sort data = out_sample_t;
by p_1;
run;
proc rank data = out_sample_t groups=10 out=ranking descending;
var p_1;
ranks rank;
run;

*count the number and compute the percentage of real default in each group;
proc sort data = ranking;
by rank;
run;
data total;
	set ranking(keep = rank DFT) end=Lastobs;
	retain total 0;
	if DFT=1 then total+1;
	if Lastobs;
	keep total;
run;

data count;
	set ranking(keep= rank DFT);
	by rank;
	if first.rank then count=0;
	if DFT=1 then do;
		count+1;
	end;
	if last.rank then output;
	drop DFT;
run;
data count;
	merge count total;
run;
data count;
	set count;
	retain total1;
	if total ne '.' then total1 = total;
	percentage = count/total1;
	drop total total1;
run;

proc print data = count;
run;
ods rtf close;
