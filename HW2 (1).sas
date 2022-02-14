/*HW2 */
Libname BADM "\\files\users\dath\Documents\BADM742";
run;

/*Create a sample of NYSE listed common stock*/
data hw2 (replace=yes);
set BADM.CRSP;
if shrcd = 10 or shrcd =11;
if exchcd =1 or exchcd =2;
year = year(date);
month = month(date);
if 1995<year<2019;
mktval = prc*shrout;
if mktval >0;
if ret >-1;
run;

proc sort data = HW2;
by year month;
run;

/*risk free data*/
data rf;
set Badm.interest;
year =year(date);
Month=month(date);
RF= TCMNOM_Y1 /(12*100);
if 1996<=year<=2018;
keep year month RF;
run;

proc sort data= riskfree;
by year month;
run;

/*merge datasets*/
data HW2_rf;
merge hw2 riskfree;
by year month;
run;

proc sort data =Hw2_rf;
by year month permno;
run;

/*estimate betas */
Data betas ; 
set Hw2_rf ; 
if 2011<=year<=2015;
run; 

data beta_rf;
set betas;
Rs_rf= ret - RF  ; 
Rm_rf= VWRETD -RF; 
run;

proc sort data = beta_rf;
by permno;
run;
 

ods graphics off;
proc reg data = beta_rf OUTEST=betas2 noprint;
by permno;
model Rs_rf  = Rm_rf;
run;

data betas2;
set betas2;
beta = Rm_rf;
keep permno beta   ;
run ; 


/*rank into 20 portfolios based on their betas*/
proc sort data = betas2;
by beta;
run;

proc rank data = betas2 out=ports groups=20;
ranks port;
var beta;
run;

data ports ;
set ports;
port=port+1;
Keep permno port;
run ;

/*Bring in monthly returns over 2016 - 2018 */

Data Rets ; 
set Hw2_rf ; 
if 2016<=year<=2018;
run; 

/*merge porfolio numbers with monthly stock returns*/

proc sort data = rets;
by permno;
run;

proc sort data = ports;
by permno;
run;

data Rets_p;
merge ports rets;
by   permno;
if port = .  then delete ; /*if a stock is not in a portfolio then delete. */
if RET = .   then delete;
run; 

/*2nd Stage of Fama-MacBeth  */
data rets_p2;
set Rets_p;
Rs_rf= ret- RF  ; 
Rm_rf= VWRETD -RF; 
run ; 

proc sort data = rets_p2; /*Use entire time-series data to estimate beta*/
by permno;
run;


ods graphics off;
proc reg data = rets_p2 OUTEST=betas2 noprint  ; 
by permno ;
model Rs_rf  = Rm_rf;
run;


/*some data cleaning*/

data betas2;
set betas2;
beta_s= Rm_rf;
keep permno beta_s   ;
run ; 


/*add beta stock to the return data */

proc sort data = betas2 ;
by permno;
run;


/*bring return data 2016-2018*/

Proc sort data= Rets_p2;
by permno;
run;


/*this data set has portfolio numbers and estimated stock betas from 2nd stage*/
data Rets_bs; 
merge Rets_p2 betas2 ;
by permno;
run;

/*calculate average beta*/
proc sort data = Rets_bs ;
by  year month port;
run;

Proc means data  =Rets_bs  noprint;
var beta_s;
by year month port;
output out=beta_port  mean=Beta_p; 
run;

/*data cleaning*/
data beta_port;
set beta_port;
drop _type_ _freq_ ;
run; 

/*Rp */
Proc means data  =Rets_bs  noprint;
var Rs_rf  ; /*Rp is the average return of portfolio p, I am using excess stock returns see Litli and Montagner 1998 page 16 */
by year month port ;
output out=ret_port  mean=ret_p ; /*Rp is the average return of portfolio p. */
run;

/*data cleaning*/
data ret_port;
set ret_port;
drop _type_ _freq_ ;
run; 

/* crate final data set that I can run cross-sectional regressions*/
proc sort data= ret_port;
by year month port;
run;

proc sort data=beta_port;
by year month port;
run;

data final;
merge ret_port beta_port ;
by year month port;
run;

/*regression to find beta*/
proc sort data = final;
by year month ;  
run;

ods graphics off;
proc reg data = final OUTEST=Lambdas noprint  ; 
by year month ;          
model Ret_p  = beta_p;  
run;


/*data cleaning*/

data lambdas;
set lambdas;
L0=Intercept;
L1= Beta_p ; /*lambda1, gamma1 in HW*/
keep year month L0 L1;
run; 

/*calculate mean, standard deviation and t-stat of Lambda1 over the period of 36 months*/

proc sort data = lambdas ;
by  year month  ;
run;

/* Lambda1 */

Proc means data  =lambdas  noprint;
var L1  ;
output out=test_stat  mean=Mean_L1 Std=Std_L1 ;
run;


data test_stat;
set test_stat;
sq_n=sqrt(36);
t_stat= Mean_L1 /(Std_L1/ sq_n); 
run;


