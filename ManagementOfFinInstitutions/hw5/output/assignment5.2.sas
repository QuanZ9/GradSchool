Libname hw5 "P:\Management_of_Financial_Institutions\hw5";

%let Opath = P:\Management_of_Financial_Institutions\hw5\output\;

/******************************************************/
/**                     Macros                       **/
/******************************************************/
%macro print(dataset);
proc print data = &dataset(obs=100);
run;
%mend;

%macro predict_between(start, end, variables, classes);
%if %sysfunc(exist(out_sample_t)) %then %do;
	proc delete data = out_sample_t (gennum = all);
	run;
%end;

%do i = &start %to &end;
	%predict(&i, &variables, &classes);
%end;
%mend;

%macro predict(tyear, variables, classes);
*in-sample model;
proc logistic data = origData(where=(fyear < &tyear)) descending outmodel = logModel noprint;
	output out = in_sample predicted = prob;
	class &classes;
	model loan_status = &variables;
run;

*use in-sample model to test out-of-sample data;
proc logistic inmodel = logModel;
	score data=origData(where=(fyear = &tyear)) out = out_sample;
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
%let vars = loan_amnt term installment grade home_ownership 
annual_inc verification_status dti delinq_2yrs inq_last_6mths 
revol_util int_rate emp_length total_pymnt total_rec_prncp last_pymnt_amnt open_acc total_acc;
*read data from csv;
proc import datafile="P:\Management_of_Financial_Institutions\hw5\LoanStats3a.csv" out=LoanStats3a(drop=desc) dbms=csv replace;
getnames=yes;
run;
proc import datafile="P:\Management_of_Financial_Institutions\hw5\LoanStats3b.csv" out=LoanStats3b(drop=desc) dbms=csv replace;
getnames=yes;
run;
proc import datafile="P:\Management_of_Financial_Institutions\hw5\LoanStats3c.csv" out=LoanStats3c(drop=desc) dbms=csv replace;
getnames=yes;
run;
proc import datafile="P:\Management_of_Financial_Institutions\hw5\LoanStats3d.csv" out=LoanStats3d(drop=desc) dbms=csv replace;
getnames=yes;
run;
*convert character to numeric;
data LoanStats3a;
	set LoanStats3a;
	mths_since_last_record1 = input(mths_since_last_record,8.);
	mths_since_last_major_derog1 = input(mths_since_last_major_derog,8.);
	drop mths_since_last_record mths_since_last_major_derog;
	rename mths_since_last_record1 = mths_since_last_record;
	rename mths_since_last_major_derog1 = mths_since_last_major_derog;
run;

*merge 4 dataset together;
data origData_raw;
	set LoanStats3a LoanStats3b LoanStats3c LoanStats3d;
run;

data origData(keep = &vars fyear loan_status ins_to_inc);
	set origData_raw;
	*parse term. 36months->0, 60months->1;
	if term = "36 months" then term1 = 0;
	else term1 = 1;
	drop term;
	rename term1=term;
	*pase int_rate;
	int_rate = substr(int_rate, 1, length(int_rate)-1);
	int_rate1 = input(int_rate, 8.);
	drop int_rate;
	rename int_rate1 = int_rate;
	*parse grade. A B C D E F -> 1 2 3 4 5 6;
	if grade = "A" then grade1 = 1;
	else if grade = "B" then grade1 = 2;
	else if grade = "C" then grade1 = 3;
	else if grade = "D" then grade1 = 4;
	else if grade = "E" then grade1 = 5;
	else if grade = "F" then grade1 = 6;
	else grade1 = .;
	drop grade;
	rename grade1=grade;
	*parse emp_length;
	if emp_length = "10+ years" then emp_length1 = 10;
	else if emp_length = "< 1 year" then emp_length1 = 0;
	else if emp_length = "n/a" then emp_length1 = .;
	else emp_length1 = input(substr(emp_length, 1, 1),8.);
	drop emp_length;
	rename emp_length1 = emp_length;
	*parse home ownership. RENT->1, OWN->2, MORTGATE->3, OTHER->4;
	if home_ownership = "RENT" then home_ownership1 = 1;
	else if home_ownership = "OWN" then home_ownership1 = 2;
	else if home_ownership = "MORTGAGE" then home_ownership1 =3;
	else if home_ownership = "OTHER" then home_ownership1 = 4;
	else home_ownership1 = .;
	drop home_ownership;
	rename home_ownership1 = home_ownership;
	*parse verification_status, verified_src->2, verified->1, not->0;
	if verification_status = "not verified" then verification_status1 = 0;
	else if verification_status = "VERIFIED - income" then verification_status1 = 1;
	else if verification_status = "VERIFIED - income source" then verification_status1 = 2;
	else verification_status1 = .;
	drop verification_status;
	rename verification_status1 = verification_status;
	*parse issue_d;
	if length(issue_d) = 6 then fyear =("20" || substr(issue_d ,1 ,2)) + 0;
	else fyear = ("200"||substr ( issue_d ,1 ,1)) + 0;
	**default;
	**parse loan_status (late or default or charged of)->1, (others)->0;
	if loan_status = "Charged Off" or loan_status = "Default" then loan_status1 = 1;
	else if loan_status = "Fully Paid" then loan_status1 = 0;
	else delete;
	drop loan_status;
	rename loan_status1 = loan_status;
	*parse revol_util;
	if index(revol_util, "%") gt 1 then do;
		revol_util = substr(revol_util, 1, length(revol_util)-1);
		revol_util1 = input(revol_util, 8.);
	end;
	else revol_util1 = .;
	drop revol_util;
	rename revol_util1 = revol_util;
	*parse init list status. Whole->0, Fractional->1;
	if initial_list_status = "w" then initial_list_status1 = 0;
	else if initial_list_status = "f" then initial_list_status1 = 1;
	else initial_list_status1 = .;
	drop initial_list_status;
	rename initial_list_status1 = initial_list_status;
	*compute ratio;
	ins_to_inc = installment / annual_inc;
run;

data origData;
	set origData;
	if cmiss(of _all_) then delete;
run;


/****************************************************************/
/**                   1. All years in-sample                   **/
/****************************************************************/
*set variables;
%let vars = revol_util int_rate total_pymnt ins_to_inc last_pymnt_amnt inq_last_6mths;
%let classes = grade;
ods rtf file="P:\Management_of_Financial_Institutions\hw5\output\Assignment52.rtf";
*logistic regression;
proc logistic data = origData descending;
	output out = logistic predicted = prob;
	model loan_status = &vars;
run;

/***************************************************************/
/**                 2. in-sample and out-of-sample            **/
/***************************************************************/
%predict_between(2014, 2015, &vars, &classes);

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
	set ranking(keep = rank loan_status) end=Lastobs;
	retain total 0;
	if loan_status=1 then total+1;
	if Lastobs;
	keep total;
run;

data count;
	set ranking(keep= rank loan_status);
	by rank;
	if first.rank then count=0;
	if loan_status=1 then do;
		count+1;
	end;
	if last.rank then output;
	drop loan_status;
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
