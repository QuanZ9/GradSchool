/***********************/
/**   Assignment 2    **/
/**   Quan Zhou       **/
/***********************/

*set data and lib path;
/*%Let path = P:\Management_of_Financial_Institutions\hw2;*/
/*Libname hw2 "&path";*/
/*%let funda = hw2.fundasample;*/

%Let pathAll = Q:\Data-ReadOnly\COMP;
Libname hw2 "&pathAll";
%let funda = hw2.funda;

%Let years = 1971 1975 1980 1985 1990 1995 1998 2003 2008 2013;
%let Opath = P:\Management_of_Financial_Institutions\hw2\output\;

*macro for replacing missing value with 0;
%macro replaceMissing(dataset);
proc stdize data = &dataset reponly missing=0 out=&dataset;
run;
%mend;

*filter by FYEAR INDFMT DATAFMT POPSRC CONSOL SCF;
%macro globalFilter(newData, origData, variables);
data &newData(keep = fyear gvkey datadate SCF &variables);
	set &funda.(keep = fyear gvkey datadate indfmt datafmt popsrc consol SCF SICH COMPST &variables);
	if SCF = 4 or SCF = 5 OR SCF = 6 OR SCF = . then DELETE;
	else if 5999 < SICH < 7000 or 4899 < SICH < 5000 then DELETE;
	else if COMPST eq "AB" then DELETE;
	else if fyear in (&years) and
		indfmt = "INDL" and
		datafmt = "STD" and
		popsrc = "D" and
		consol = "C" then output;
run;

proc sort data = &newData;
by fyear;
run;
%mend;


%macro globalFilter2(newData, origData, variables);
data &newData(keep = fyear gvkey datadate SCF &variables);
	set &funda.(keep = fyear gvkey datadate indfmt datafmt popsrc consol SCF SICH COMPST &variables);
	if SCF = 4 or SCF = 5 OR SCF = 6 OR SCF = . then DELETE;
	else if 5999 < SICH < 7000 or 4899 < SICH < 5000 then DELETE;
	else if COMPST eq "AB" then DELETE;
	else if indfmt = "INDL" and
		datafmt = "STD" and
		popsrc = "D" and
		consol = "C" then output;
run;

proc sort data = &newData;
by fyear;
run;
%mend;


*normalize;
%macro normalize(newData, origData, variables, divider);
data &newData;
	set &origData;
	array cols {*} &variables;
	do i = 1 to dim(cols);
		if cols[i] ne &divider then cols[i] = divide(cols[i], &divider);
	end;
	&divider = 1;
	drop i;
run;
%mend;

*macro for format output;
%macro tabular(dataset, variables, statsType);
*%replaceMissing(&dataset);
proc tabulate data = &dataset;
	var _freq_ &variables;
	class fyear;
	table _freq_ = 'Number of Oservations' &variables, fyear="Fiscal Year --- &statsType"*mean='';
run;
%mend;

*macro for calculating stats and do tabular output;
%macro statsTab(dataset, variables);
/*%removeOutliers(&dataset, &variables);*/
proc means data = &dataset mean min max std p25 p50 p75 noprint;
by fyear;
var &variables;
output out = stats_mean mean=;
output out = stats_min min=;
output out = stats_max max=;
output out = stats_std std=;
output out = stats_p25 p25=;
output out = &dataset._p50 p50=;
output out = stats_p75 p75=;

run;
*format output;
title2 "mean";
%tabular(stats_mean, &variables, mean);
title2 "std";
%tabular(stats_std, &variables, std);
title2 "min";
%tabular(stats_min, &variables, min);
title2 "max";
%tabular(stats_max, &variables, max);
title2 "p25";
%tabular(stats_p25, &variables, p25);
title2 "p50";
%tabular(&dataset._p50, &variables, p50);
title2 "p75";
%tabular(stats_p75, &variables, p75);
%mend;

*macro for plotting;
%macro graphPlot(variables, var);
proc sgplot data = table2_all;
	%do i = 1 %to %sysfunc(countw(&variables));
		%let fvariable = %qscan(&variables, &i, %str(" "));
		series x=fyear y=&fvariable / legendlabel = "median of &fvariable";
	%end;
	series x=fyear y=&var/y2axis;
run;
%mend;

%macro graphPlot2(dataset, var);
proc sgplot data = &dataset;
	%do i = 1 %to %sysfunc(countw(&var));
		%let fvariable = %qscan(&var, &i, %str(" "));
		series x=fyear y=&fvariable / legendlabel = "median of &fvariable";
	%end;
run;
%mend;

*remove outliers that are more than 3 std away from the mean;
%macro removeOutliers(dataset, variables);
proc standard data = &dataset mean = 0 std = 1 out = StandardData;
var &variables;
run;

data tempdata;
	merge &dataset StandardData;
	array vars {*} &variables;
	do i = 1 to dim(vars);
		if vars[i] > 3 or vars[i] < -3 then do;
			DELETE;
			LEAVE;
		end;
	end;
run;
%mend;

/*******************************************************************************************/
/**                               Assignment 2.1                                          **/
/*******************************************************************************************/

ods rtf file = "&Opath.assignment2.1.rtf";
/******************/
/**   TABLE 1    **/
/******************/
*set global variables;
%let tableVar1 = CH IVST RECT INVT ACO ACT PPENT IVAEQ IVAO INTAN AO AT 
				DLC AP TXP LCO DLTT LO TXDITC MIB LT 
				PSTK CEQ SEQ ;

*filter by years and other properties;
%globalFilter(temp1, &funda, &tableVar1)

*divide variables by AT;
%normalize(table1, temp1, &tableVar1, AT);

*calculate stats;
title "2.1 --- Table 1";
%statsTab(table1, &tableVar1);

/***********************/
/**     Table 2       **/
/***********************/
%let tableVar2 = DV CAPX IVCH AQC FUSEO SPPE SIV IVSTCH IVACO
				WCAPC CHECH DLCCH RECCH INVCH APALCH TXACH AOLOCH FIAO
				IBC XIDOC DPC TXDC ESUBC SPPIV FOPO FSRCO EXRE
				DLTIS DLTR 
				SSTK PRSTKC 
				AT;
%let tableVar2_ = a b c d e f g h;
*filter;
%globalFilter(temp1, &funda, &tableVar2);

%normalize(temp2, temp1, &tableVar2, AT);

/*%replaceMissing(temp2);*/

*calaulations;
data table2(keep = fyear &tableVar2_);
	set temp2;
	a = DV;
	if SCF = 1 then
		do;
		b = CAPX+IVCH+AQC+FUSEO-SPPE-SIV;
		c = WCAPC+CHECH+DLCCH;
		d = IBC+XIDOC+DPC+TXDC+ESUBC+SPPIV+FOPO+EXRE;
		end;
	else if SCF = 2 or SCF = 3 then
		do;
		b = CAPX+IVCH+AQC+FUSEO-SPPE-SIV;
		c = -WCAPC+CHECH-DLCCH;
		d = IBC+XIDOC+DPC+TXDC+ESUBC+SPPIV+FOPO+EXRE;
		end;
	else if SCF = 7 then
		do;
		b = CAPX+IVCH+AQC-SPPE-SIV-IVSTCH-IVACO;
		c = -RECCH-INVCH-APALCH-TXACH-AOLOCH+CHECH-FIAO-DLCCH;
		d = IBC+XIDOC+DPC+TXDC+ESUBC+SPPIV+FOPO+EXRE;
		end;

	e = a+b+c-d;
	f = DLTIS - DLtr;
	g = SSTK-PRSTKC;
	h = f+g;

	label a = "Cash Dividend"
		b = "Investments"
		c = "Changing Working Capital"
		d = "Internal Cash Flow"
		e = "Financing Deficit"
		f = "Net debt issues"
		g = "Net equity issues"
		h = "Net external financing";
run;


*calculate stats;
title "2.1 --- Table 2";
%statsTab(table2, &tableVar2_);

/*******************************/
/**       table 8             **/
/*******************************/
%let tableVar8 = SALE COGS XSGA OIBDP DP OIADP XINT NOPI SPI PI TXT MII IB DVP CSTKE XIDO NI
				IBC DPC XIDOC TXDC ESUBC SPPIV FOPO FOPT RECCH INVCH APALCH TXACH AOLOCH OANCF
				IVCH SIV CAPX SPPE AQC IVSTCH IVACO IVNCF
				SSTK PRSTKC DV DLTIS DLTR DLCCH FIAO FINCF EXRE CHECH FSRCO FUSEO WCAPC
				AT;

%let tableVar8_ = SALE COGS XSGA OIBDP DP OIADP XINT newA PI TXT MII IB DVP CSTKE XIDO NI
				IBC DPC newB FOPT RECCH INVCH APALCH TXACH AOLOCH OANCF
				IVCH SIV CAPX SPPE AQC newC IVNCF
				SSTK PRSTKC DV DLTIS DLTR DLCCH FIAO FINCF EXRE CHECH FSRCO FUSEO WCAPC
				AT;

%globalFilter(temp1, &funda, &tableVar8);

%normalize(temp2, temp1, &tableVar8, AT);

/*%replaceMissing(temp2);*/

data table8;
	set temp2;
	newA = NOPI+SPI;
	label newA = "Non operating income and special items";
	drop NOPI SPI;

	newB = XIDOC+TXDC+ESUBC+SPPIV+FOPO;
	label newB = "Other funds from operation";
	drop XIDOC TXDC ESUBC SPPIV FOPO;

	newC = IVSTCH + IVACO;
	label newC = "Short term investment-change, and investing activities-Other";
	drop IVSTCH IVACO;
run;

*output;
title "2.1 --- Table 8";
%statsTab(table8, &tableVar8_);


/*************************************/
/***          table 9             ****/
/*************************************/
%let tableVar9 = AT LCT SALE DLC DLTT DV DLTIS DLTR SSTK PRSTKC DLC SEQ PPENT MKVALT NI;
%let tableVar9_ = AT SALE new1 DV b c d e DLTIS DLTR f SSTK PRSTKC g h new2-new17;

%globalFilter(temp1, &funda, &tableVar9);

/*%replaceMissing(temp1);*/
/*%replaceMissing(table2);*/

*getdata from table2;
data table9;
	merge table2 temp1;
	netAsset = AT - LCT;
	new1 = DLC+DLTT;
	new2 = divide(DV, NetAsset);
	b = b * AT;
	c = c * AT;
	d = d * AT;
	e = e * AT;
	f = f * AT;
	g = g * AT;
	h = h * AT;
	new3 = divide(b,NetAsset);
	new4 = divide(c,NetAsset);
	new5 = divide(d,NetAsset);
	new6 = divide(e,NetAsset);
	new7 = divide(DLTIS,NetAsset);
	new8 = divide(f,NetAsset);
	new9 = divide(g,NetAsset);
	new10 = divide(h,NetAsset);
	new11 = divide(DLC,NetAsset);
	new12 = divide(f,AT);
	new13 = divide(DLTT,AT);
	new14 = divide((DLTT+DLC),(DLTT+DLC+SEQ));
	new15 = divide(PPENT,AT);
	new16 = divide(MKVALT,AT);
	new17 = divide(NI,AT);
	
	label new1 = "Book value of debt"
		new2 = "Cash dividend/net assets"
		new3 = "Capital investment/net assets"
		new4 = "Net increase in working capital/net assets"
		new5 = "Internal cash flow/net assets"
		new6 = "Financing deficit/net assets"
		new7 = "Gross debt issued/net assets"
		new8 = "Net debt issued/net assets"
		new9 = "Net equity issued/net assets" 
		new10 = "Net external financing/net assets"
		new11 = "Current maturity of long-term debt/net assets"
		new12 = "Change in long-term debt/net asset ratio"
		new13 = "Long-term debt/total assets" 
		new14 = "Book leverage"
		new15 = "Tangibility (Net fixed assets/total assets)"
		new16 = "Market value of assets/book value of assets"
		new17 = "Profitability (operating income/assets)";
run;


*output;
title "2.1 --- Table 9";
%statsTab(table9, &tableVar9_);


/***************************************/
/**            table 10               **/
/***************************************/

title "2.1 --- Table 10";
proc corr data = table9 noprob;
var &tableVar9_;
run;

ods rtf close;


/****************************************************************************************************/
/**						  Assignment 2.2                                                           **/
/****************************************************************************************************/

/***********************************/
/**   1. Liquidity and Solvency   **/
/***********************************/
ods rtf file = "&Opath.assignment2.2.rtf";

%let tableVar2_1 = ACT LCT CHE RECT LT SEQ;
%let tableVar2_1_ = CurrentRatio QuickRatio DebtEquityRatio;

%globalFilter2(temp1, &funda, &tableVar2_1);
/*%replaceMissing(temp1);*/

data table2_1;
	set temp1;
	CurrentRatio = divide(ACT,LCT);
	QuickRatio = divide((CHE+RECT),LCT);
	DebtEquityRatio = divide(LT,SEQ);
run;


title "2.2 --- Liquidity and Solvency";
%statsTab(table2_1, &tableVar2_1_);

title "2.2 --- Liquidity and Solvency (Correlation)";
proc corr data = table2_1 noprob out = table2_1_corr;
var &tableVar2_1_;
run;

%graphPlot2(table2_1_p50, &tableVar2_1_);

/************************************************/
/**               2. Activity                  **/
/************************************************/
%let tableVar2_2 = RECT SALE INVT COGS AP;
%let tableVar2_2_ = DSO DIO DPO CCC;

%globalFilter2(temp1, &funda, &tableVar2_2);
/*%replaceMissing(temp1);*/

proc sort data = temp1;
by gvkey fyear;
run;

/*proc expand data=temp1 out=temp2;*/
/*	by gvkey;*/
/*	id datadate;*/
/*	convert RECT = moving_RECT / transformout = (movave 2);*/
/*	convert INVT = moving_INVT / transformout = (movave 2);*/
/*	convert AP = moving_AP / transformout = (movave 2);*/
/*run;*/

data temp2;
	set temp1;
	by gvkey fyear;
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


data table2_2;
	set temp2;
	DSO = 365 * divide(moving_RECT , SALE);
	DIO = 365 * divide(moving_INVT , COGS);
	DPO = 365 * divide(moving_AP , COGS);
	CCC = DSO + DIO - DPO;
	label DSO = "Days Sales Outstanding"
		DIO = "Days inventory outstanding"
		DPO = "Days payable outstanding"
		CCC = "Cash conversion cycle";
run;

proc sort data = table2_2;
by fyear;
run;

title "2.2 --- Activity";
%statsTab(table2_2, &tableVar2_2_);

title "2.2 --- Activity (Correlation)";
proc corr data = table2_2 noprob out = table2_2_corr;
var &tableVar2_2_;
run;

%graphPlot2(table2_2_p50, &tableVar2_2_);

/******************************************************/
/**                3. Asset Utilization              **/
/******************************************************/
%let tableVar2_3 = RECT SALE INVT COGS AT;
%let tableVar2_3_ = TAT_ IT_ RT_;

%globalFilter2(temp1, &funda, &tableVar2_3);
/*%replaceMissing(temp1);*/

proc sort data = temp1;
by gvkey fyear;
run;

/*proc expand data = temp1 out = temp2;*/
/*	by gvkey;*/
/*	id datadate;*/
/*	convert RECT = moving_RECT / transformout = (movave 2);*/
/*	convert INVT = moving_INVT / transformout = (movave 2);*/
/*	convert AT = moving_AT / transformout = (movave 2);*/
/*run;*/

data temp2;
	set temp1;
	by gvkey fyear;
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

data table2_3;
	set temp2;
	TAT_ = divide(SALE , moving_AT);
	IT_ = divide(COGS , moving_INVT);
	RT_ = divide(SALE , moving_RECT);

	label TAT_ = "Total asset turnover"
		IT_ = "Inventory turnover"
		RT_ = "Receivable turnover";
run;

proc sort data = table2_3;
by fyear;
run;

title "2.2 --- Asset Utilization";
%statsTab(table2_3, &tableVar2_3_);

title "2.2 --- Asset Utilization(Correlation)";
proc corr data = table2_3 noprob out = table2_3_corr;
var &tableVar2_3_;
run;

%graphPlot2(table2_3_p50, &tableVar2_3_);

/********************************************/
/**            4. Leverage                 **/
/********************************************/
%let tableVar2_4 = OIADP XINT OIADP AT SEQ;
%let tableVar2_4_ = IB_ IC_ Leverage;

%globalFilter2(temp1, &funda, &tableVar2_4);
/*%replaceMissing(temp1);*/

data table2_4;
	set temp1;
	IB_ = divide((OIADP - XINT),OIADP);
	IC_ = divide(OIADP,XINT);
	Leverage = divide(AT,SEQ);

	label IB_ = "Interest burden"
		IC_ = "Interest coverage "
		Leverage = "Leverage";
run;


title "2.2 --- Leverage";
%statsTab(table2_4, &tableVar2_4_);

title "2.2 --- Leverage(Correlation)";
proc corr data = table2_4 noprob out = table2_4_corr;
var &tableVar2_4_;
run;

%graphPlot2(table2_4_p50, &tableVar2_4_);


/*************************************************/
/**          5. Profitability                   **/
/*************************************************/
%let tableVar2_5 = OIADP AT NI SEQ SALE;
%let tableVar2_5_ = ROA_ ROE_ ROS_;

%globalFilter2(temp1, &funda, &tableVar2_5);
/*%replaceMissing(temp1);*/

proc sort data = temp1;
by gvkey;
run;

/*proc expand data = temp1 out = temp2;*/
/*	by gvkey;*/
/*	id datadate;*/
/*	convert AT = moving_AT / transformout = (movave 2);*/
/*	convert SEQ = moving_SEQ / transformout = (movave 2);*/
/*run;*/

data temp2;
	set temp1;
	by gvkey fyear;
	if first.gvkey then do;
		moving_AT = .;
		moving_SEQ = .;
	end;
	else do;
		moving_AT = (AT + lag(AT)) / 2;
		moving_SEQ = (SEQ + lag(SEQ)) / 2;
	end;
run;


data table2_5;
	set temp2;
	ROA_ = divide(OIADP , moving_AT);
	ROE_ = divide(NI , moving_SEQ);
	ROS_ = divide(OIADP , SALE);
 
	label ROA_ = "Return on assets"
		ROE_ = "Return on equity "
		ROS_ = "Return on sales(Profit margin)";
run;

proc sort data = table2_5;
by fyear;
run;

title "2.2 --- Profitability";
%statsTab(table2_5, &tableVar2_5_);

title "2.2 --- Profitability(Correlation)";
proc corr data = table2_5 noprob out = table2_5_corr;
var &tableVar2_5_;
run;

%graphPlot2(table2_5_p50, &tableVar2_5_);

/**********************************************************/
/**              6. Special Scores                       **/
/**********************************************************/
%let tableVar2_6 = ACT LCT AT REUNA ACOMINC SEQO OIADP MKVALT LT SALE NI PI DP;
*%let tableVar2_6_ = AZS_ A0 B0 C0 D0 E0 OOS_ A B C D E F FFO_ G H I ;
%let tableVar2_6_ = AZS_ OOS_ FFO_;

%globalFilter2(temp1, &funda, &tableVar2_6);
/*%replaceMissing(temp1);*/

proc sort data = temp1;
by gvkey fyear;
run;

data temp2;
	set temp1;
	by gvkey fyear;
	NI_lag = lag(NI);
	if first.gvkey then NI_lag = .;
	NI_sub = NI - NI_lag;
	NI_sum = NI + NI_lag;

	NI_2year = lag2(NI) + NI_lag;
run;

data table2_6;
	set temp2;
	A0 = divide((ACT-LCT),AT);
	B0 = divide((REUNA +ACOMINC +SEQO),AT);
	C0 = divide(OIADP,AT);
	D0 = divide((MKVALT-LT),LT);
	E0 = divide(SALE,AT);
	AZS_ = 1.2*A0 + 1.4*B0 + 3.3*C0 + 0.6*D0 + 1.0*E0;

	A = log(AT);
	B = divide(LT,AT);
	C = divide((ACT-LCT),AT);
	D = divide(LCT,ACT);
	E = divide(NI,AT);
	F = divide((PI +DP),LT);
	FFO_ = PI + DP;

	if LT > AT then G = 1;
	else G = 0;

	if NI_2year < 0 then H = 1;
	else H = 0;

	I = divide(NI_sub , NI_sum);

	OOS_= -1.32 -0.407*A + 6.03*B - 1.43*C + 0.757*D - 2.37*E - 1.83*F - 1.72*G + 0.285*H - 0.521*I;

	label AZS_ = "Altman-Z score"
		FFO_ = "Funds from operations"
		OOS_ = "Ohlson O-score";
run;

proc sort data = table2_6;
by fyear;
run;

title "2.2 --- Special Scores";
%statsTab(table2_6, &tableVar2_6_);

title "2.2 --- Special Scores(Correlation)";
proc corr data = table2_6 noprob out = table2_6_corr;
var &tableVar2_6_;
run;
%graphPlot2(table2_6_p50, &tableVar2_6_);

/**********************************************/
/**               7. NBER                    **/
/**********************************************/
%let tableVar2_all = &tableVar2_1_ &tableVar2_2_ &tableVar2_3_ &tableVar2_4_ &tableVar2_5_ &tableVar2_6_;

*get data from url;
filename nberWeb url "https://research.stlouisfed.org/fred2/data/USREC.txt";
data nber;
	infile nberWeb firstobs = 72;
	input @1 date yymmdd10. @12 nber_v;
	year = year(date);
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
run;

*merge NBER and financial variables in 2.2;
data table2_all;
	merge table2_1_p50 table2_2_p50 table2_3_p50 table2_4_p50 table2_5_p50 table2_6_p50;
	by fyear;
run;
data table2_all;
	merge table2_all(in=x) nber(in=y rename=(year=fyear));
	by fyear;
	if x&y;
run;

proc sort data = table2_all;
by nber_v;
run;

*calculate statistics for recession=0 and recession=1;
title "2.2 --- NBER Recession ";
proc means data = table2_all n mean std p25 p50 p75 min max;
var &tableVar2_all;
by nber_v;
run;


/********************************************************/
/**                   8. BAAFFM                        **/
/********************************************************/
*get data;
filename baaWeb url "https://research.stlouisfed.org/fred2/data/BAAFFM.txt";
data baa;
	infile baaWeb firstobs = 1;
	input @1 date yymmdd10. @12 baa_v;
	year = year(date);
	drop date;
run;
*convert to yearly BAAFFM data;
proc means data = baa noprint;
by year;
output out = baa mean=;
run;

proc sort data = table2_all;
by fyear;
run;

*merge BAAFFM and yearly financial variables in 2.2;
data table2_all;
	merge table2_all(in=x) baa(in=y rename=(year=fyear));
	by fyear;
	if x&y;
run;

title "2.2 --- BAAFFM with financial variables";
%graphPlot(&tableVar2_1_, baa_v);
%graphPlot(&tableVar2_2_, baa_v);
%graphPlot(&tableVar2_3_, baa_v);
%graphPlot(&tableVar2_4_, baa_v);
%graphPlot(&tableVar2_5_, baa_v);
%graphPlot(&tableVar2_6_, baa_v);


/*****************************************************/
/**               9. CFSI                           **/
/*****************************************************/
*get data;
filename cfsiWeb url "https://research.stlouisfed.org/fred2/data/CFSI.txt";
data cfsi;
	infile cfsiWeb firstobs = 1;
	input @1 date yymmdd10. @12 cfsi_v;
	year = year(date);
	drop date;
run;
*convert to yearly CFSI data;
proc means data = cfsi noprint;
by year;
output out = cfsi mean=;
run;

*merge CFSI and yearly financial variables in 2.2;
data table2_all;
	merge table2_all(in=x) cfsi(in=y rename=(year=fyear));
	by fyear;
	if x&y;
run;

title "2.2 --- CFSI with financial varialbles";
%graphPlot(&tableVar2_1_, cfsi_v);
%graphPlot(&tableVar2_2_, cfsi_v);
%graphPlot(&tableVar2_3_, cfsi_v);
%graphPlot(&tableVar2_4_, cfsi_v);
%graphPlot(&tableVar2_5_, cfsi_v);
%graphPlot(&tableVar2_6_, cfsi_v);

ods rtf close;
