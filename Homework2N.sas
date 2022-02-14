

/*HW 2 solutions*/

libname BADMSAS "\\files\users\mdniazc\Desktop\BADMSAS";
run; 

/*You are required to perform analyses to investigate whether 
the beta is positively correlated with the stock return in the US stock market.
You need the data for assignment#1 
(The dataset consists of monthly returns for NYSE-listed stocks between 1996 and 2018) to work on the assignment. */

/*Create a sample of NYSE listed common stock from 1996<=year<=2018*/
  
data HW2;
set BADMSAS.crsphw1 ;
If SHRCD = 10 or Shrcd = 11; /*Ordinary common sahres*/
If Exchcd = 1 or Exchcd = 2; /*NYSE listed*/
if ret>-1;          /*keep if ret >-100%*/
mktval= prc*shrout; /*calculate market value*/
if mktval >0;       /*keep if mcap is greater than zero*/
year= year(date);
Month=Month(date);
if 1996<=year<=2018;
run;




/*1st stage of Fama MacBeth, using historical data estimate a beta for each stock and put each stok into a portfolio based on its Beta, */

/*Stock beta is measured using the capital asset pricing model (CAPM).
For each stock, monthly excess stock returns are regressed on monthly excess market returns (value-weighted CRSP market index minus the Treasury bill rate) 
during the five-year period preceding a year. 
Stock market beta is the coefficient estimate on excess market returns. 
Use CRSP monthly data. �Holding Period Return� is the stock return. �Value-Weighted Return (includes distributions)� is the market return. 
RF: TCMNOM_Y1,	1-year From WRDS
*/


/*Bring in Risk free rate */
/*Go to WRDS>  Get Data > Federal Reserve Bank > Interest Rates > Interest Rates (Federal Reserve, H15 report)
Choose all 1-years then we can drop the ones we do not need.*/

data RiskFree;
set Badmsas.interest;
year =year(date);
Month=month(date);
RF= TCMNOM_Y1 /(12*100);
if 1996<=year<=2018;
keep year month RF;
run;


proc sort data = HW2;
by year month;
run;

proc sort data= riskfree;
by year month;
run;


data HW2_rf;
merge hw2 riskfree;
by year month;
run;

proc sort data =Hw2_rf; /*complete dataset with Rf data*/
by year month permno;
run;



/* Using data for the period between 2011 and 2015 (five years) to estimate Betas of individual stocks. */

Data betas ; 
set Hw2_rf ; 
if 2011<=year<=2015;
run; 

/* Run regressions stock by stock, estimate Betas of individual stocks and save them into a dataset*/
/*calculate excess stock returns and excess market return
See Fama MacBeth  1973 equation 6*/

data beta_rf;
set betas;
Rs_rf= ret - RF  ; 
Rm_rf= VWRETD -RF; /* VWRETD: I use CRSP value weighted portfolio as my market port. proxy. S&P-500 would also work. */
run ; 


/*run regressions and save betas for each stock. 
There will be only one beta for each stock, and we will use all available data in our estimates
See https://support.sas.com/rnd/app/ets/examples/capm/index.htm for CAPM specification*/

proc sort data = beta_rf;
by permno;
run;
 

ods graphics off;
proc reg data = beta_rf OUTEST=betas2 noprint  ; /*OUTEST saves your betas*/
by permno ;
model Rs_rf  = Rm_rf;
run;


/*some data cleaning*/

data betas2;
set betas2;
beta = Rm_rf;
keep permno beta;
run ; 


/*Then, at begging of 2016, all stocks are ranked into twenty portfolios based on their betas.*/
proc sort data = betas2;
by beta;
run;


/*create 20 portfolios based on beta, name portfolios as port*/
proc rank data = betas2 out=ports groups=20;
ranks port;
var beta;
run;

/*We want portfolio numbers to start with 1 so ... */
data ports ;
set ports;
port=port+1;
Keep permno port;
run ;


/*These portfolios are equally weighted at formation and held for subsequent 36 months (between 2016 and 2018) 
during which returns are calculated monthly (they are re-balanced monthly). */

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

/*For each month of the period, the following cross-sectional regression is run:

               Rp = Lambda0 + Lambda1*Betap +Errorp,               p = 1 , 2 ,..., 20.

The independent variable Betap is the average of the beta for stocks in portfolio p, and Rp is the average return of portfolio p. 
*/

/*This is the 2nd stage of Fama-MacBeth, 
I need to estimate beta of each stock using monthly returns over 2016-2018 
I will use stock Betas to calculate Portfolio betas, portfolios are equally weighted */
   

data rets_p2;
set Rets_p;
Rs_rf= ret- RF  ; 
Rm_rf= VWRETD -RF; /* VWRETD: I use CRSP value weighted portfolio as my market port. proxy. S&P-500 would also work. */
run ; 


/*run regressions and Save betas for each stock. There will be only one beta for each stock, and we will use all available data in our estimates
See https://support.sas.com/rnd/app/ets/examples/capm/index.htm for CAPM specification*/

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


/*For each month of the period, the following cross-sectional regression is run:

               Rp = Lambda0 + Lambda1*Betap +Errorp,               p = 1 , 2 ,..., 20.

The independent variable Betap is the average of the beta for stocks in portfolio p, and Rp is the average return of portfolio p. 
*/

/*Now I will calculate average beta = BetaP and average ret= Rp over 20 portfolios in each month,  2016-2018*/
/*these are equally weighted portfolios : Weight is 1/n */

proc sort data = Rets_bs ;
by  year month port;
run;

/*Bp */

Proc means data  =Rets_bs  noprint;
var beta_s  ; /*stock betas */
by year month port ;
output out=beta_port  mean=Beta_p ; /* Betap is the average of the beta for stocks in portfolio p */
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


/*For each month of the period, the following cross-sectional regression is run:

               Rp = Lambda0 + Lambda1*Betap +Errorp,               p = 1 , 2 ,..., 20.

The independent variable Betap is the average of the beta for stocks in portfolio p, and Rp is the average return of portfolio p. 
*/

proc sort data = final;
by year month ;  
run;



ods graphics off;
proc reg data = final OUTEST=Lambdas noprint  ; 
by year month ;          /*Run regression for each month of the period*/
model Ret_p  = beta_p;   /*this is  Rp = Lambda0 + Lambda1*Betap +Errorp,   */
run;


/*data cleaning*/

data lambdas;
set lambdas;
L0=Intercept;
L1= Beta_p ; /*lambda1, gamma1 in HW*/
keep year month L0 L1;
run; 

/*Finally, calculate mean, standard deviation and t-stat of Lambda1 over the period of 36 months.*/

proc sort data = lambdas ;
by  year month  ;
run;

/* Lambda1 */

Proc means data  =lambdas  noprint;
var L1  ;
output out=test_stat  mean=Mean_L1 Std=Std_L1 ;
run;

/*Final test statistics See Fama MacBeth Page 619 */

data test_stat;
set test_stat;
sq_n=sqrt(36); /*SAS functions  https://stats.idre.ucla.edu/sas/modules/using-sas-functions-for-making-and-recoding-variables/ */
t_stat= Mean_L1 /(Std_L1/ sq_n); /*Final test statistics See Fama MacBeth Page 619 */
run;
