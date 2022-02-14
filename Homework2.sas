/*HW 2 solutions*/

libname BADMSAS "\\files\users\mdniazc\Desktop\BADMSAS";
run; 


/*Create a sample of NYSE listed common stock from 1996<=year<=2018*/
  
data HW2;
set BADMSAS.crsphw1 ;
If SHRCD = 10 or Shrcd = 11; 
If Exchcd = 1 or Exchcd = 2; 
if ret>-1;          
mktval= prc*shrout; 
if mktval >0;       
year= year(date);
Month=Month(date);
if 1996<=year<=2018;
run;



/*Bring in Risk free rate */

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
keep permno beta   ;
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



/*HW 3 solutions*/

libname BADM "D:\TeachingSpring2020\BADM742SAS";
run; 

 
/*Create a sample of NYSE listed common stock from 1996<=year<=2018*/
/*This is the same CRSP dataset from HW2*/
/*CRSP Dataset*/
data HW3_CRSP;
set BADM.CRSP ;
If SHRCD = 10 or Shrcd = 11; /*Ordinary common sahres*/
If Exchcd = 1 or Exchcd = 2; /*NYSE listed*/
if ret>-1;          /*keep if ret >-100%*/
mktval= prc*shrout; /*calculate market value*/
if mktval >0;       /*keep if mcap is greater than zero*/
year= year(date);
Month=Month(date);
if 1996<=year<=2018;

cusip_e=CUSIP;  /*This variable is new, I will use this to match CRSP and compustat*/
run;

/*COMPUSTAT dataset*/
data HW3_Comp;
set BADM.Compustat ;  
if AT = . then delete;/*no total asset reported*/
if AT = 0 then delete; /*zero total assets then delete*/
if sale < 0 then delete; /*negative sales then delete*/
run; 



/*1)  Using data for the period between 1998 and 2002 (five years) to estimate Betas of individual stocks. */

data HW3_CRSP_b;
set HW3_CRSP;
if 1998<=year<=2002;
run; 


proc sort data = HW3_CRSP_b;
by cusip_e;
run;
 

ods graphics off;
proc reg data = HW3_CRSP_b OUTEST=betas2 noprint  ; /*OUTEST saves your betas to betas2 dataset*/
by cusip_e ;
model ret  = VWRETD ;
run;


/*some data cleaning*/

data betas2; /*Betai variables are in Betas2 dataset */
set betas2;
beta = VWRETD;
keep cusip_e beta   ;
run ; 

/*Then, for each month of the period between 2003 and 2005, the following cross-sectional regression is run:
               Ri = L0 + L1 Betai + L2 ln(MEi) + L3 ln(BE/MEi) + error termi,  i = 1, 2 ...
The independent variable Betai is the Beta for stocks i. 
MEi is the market value (size) of equity for stock i 
and BE/MEi is the book-to-market ratio for stock i. 
The values of both MEi and BE/MEi for a given year are determined by the information available in December of previous year. 
The dependent variable Ri is the monthly return of stock i.
*/ 

 /*I need to calculate size and BE/MEi   */  

/* BE book value per share from compustat: BKVLPS: Dollars and cents*/
/* ME market value of equity per share from CRSP: PRC : Dollars and cents */
/* MV of equity (size) =prc*shrout,  price times number of shares outstanding from CRSP*/


/*I need to merge CRSP and compustat datasets. All I need is December values. */

data comp_2;
set HW3_Comp ;
year=year(DATADATE);
month=month(DATADATE);
if month=12; /*all we need is december values*/
run;


data Crsp_2;
set HW3_CRSP; 
if month=12; /*all we need is december values*/
run ; 


/*We need to merge CRSP & Compustat datasets*/
/* To merge them I will use CUSIP and Year */
/* CRSP CUSIP has 8 digits, COMPUSTAT CUSIP has 9 digits. I need to cut one digit from Compustat CUSIP */ 

data comp_3 (keep= cusip_e BKVLPS  year );
set comp_2;
cusip_e= substr(cusip, 1, 8); /*cut compustat 9 digit cusip, just keep first 1-8 digits, and now it is same as 8 digit CRSP  cusip */
run; 

data crsp_3 (keep=cusip_e  PRC year shrout) ; 
set Crsp_2 ;
cusip_e=CUSIP; 
run; 

proc sort data = comp_3;
by cusip_e year;
run;


proc sort data = crsp_3;
by cusip_e year;
run;

data size_MB; /******YOU WILL NEED to merge CRSP and Compustat for the final as I do here, Also you will no to calculate:  Book to market = BKVLPS / prc, and Earnings to Price = EPSPX / prc  ****/
merge crsp_3 comp_3;
by cusip_e year; 
MV_eq=  prc*shrout ; /* MV of equity (size) =prc*shrout*/
ln_ME=log(MV_eq);
ln_BM= log(BKVLPS / prc); 
if ln_Me=. then delete;
if ln_BM=. then delete;
run;


/*Now we need to merge CRSP monthly return, SIZE_MB and BETAS2 datasets. */

/*I need CRSP returns  for each month of the period between 2003 and 2005,*/

data crsp0305;
set HW3_CRSP;
if 2003<=year<=2005;
keep cusip_e ret year month;
run;

/*I need SIZE_MB of previous years  between 2003 and 2005 */
/* I will increase year by +1, in size_MB dataset */

data size_MB0305;
set size_MB;
year=year+1;
keep cusip_e year ln_ME ln_BM;
run;




/*Merge crsp0305 & size_MB0305*/
proc sort data = crsp0305;
by cusip_e year;
run;


proc sort data = size_MB0305;
by cusip_e year;
run;


data retsizemb;
merge crsp0305 size_MB0305;
by cusip_e year;
if ln_Me=. then delete;
if ln_BM=. then delete;
if 2003<=year<=2005;
run;

/*Merge betas to retsizemb*/

proc sort data = betas2;
by cusip_e ;
run; 

proc sort data = retsizemb;
by cusip_e ;
run; 

data final;
merge retsizemb betas2; 
by cusip_e ;
if ln_Me=. then delete;
if ln_BM=. then delete;
if month=. then delete;
run; 

 


 /*Run regression for each month of the period*/


proc sort data = final;
by year month ;  
run;



ods graphics off;
proc reg data = final OUTEST=Lambdas noprint  ; /*save your coefficients in Lamdas dataset*/
by year month ;                               /*Run regression for each month of the period*/
model   ret  =  beta ln_me ln_BM;            /*this is   Ri = L0 + L1 Betai + L2 ln(MEi) + L3 ln(BE/MEi)+ error termi,   */
run;


/*data cleaning*/

data lambdas (keep=keep year month L0 L1 L2 L3); /*Keep only the variables you will need*/
set lambdas;
L0=Intercept;
L1= beta ; /*lambda1, gamma1 in HW*/
L2=ln_me; /*lambda2, gamma2 in HW*/
L3=ln_bm; /*lambda3, gamma3 in HW*/

run; 

/*Finally, calculate mean, standard deviation and t-stat of Lambdas over the period of 36 months.*/

proc sort data = lambdas ;
by  year month  ;
run;

/*Mean and stdev of L1, L2, and L3*/

Proc means data  =lambdas  noprint;
var L1 L2 L3 ;
output out=test_stat  
mean(L1)=Mean_L1 Std(L1)=Std_L1  
mean(L2)=Mean_L2 Std(L2)=Std_L2
mean(L3)=Mean_L3 Std(L3)=Std_L3  
;
run;

/*Final test statistics See Fama MacBeth Page 619 */

data test_stat;
set test_stat;
sq_n=sqrt(36);                /*SAS functions  https://stats.idre.ucla.edu/sas/modules/using-sas-functions-for-making-and-recoding-variables/ */
t_stat1= Mean_L1 /(Std_L1/ sq_n); /*Final test statistics See Fama MacBeth Page 619 */
t_stat2= Mean_L2 /(Std_L2/ sq_n);
t_stat3= Mean_L3 /(Std_L3/ sq_n);
run;




/*Part b is repetition of Part a in  different time periods. 
 I will use the same code from part a, and only change the time periods. */

/*Copy and paste part a code*/




 
/*Create a sample of NYSE listed common stock from 1996<=year<=2018*/
/*This is the same CRSP dataset from HW2*/
/*CRSP Dataset*/
data HW3_CRSP;
set BADM.CRSP ;
If SHRCD = 10 or Shrcd = 11; /*Ordinary common sahres*/
If Exchcd = 1 or Exchcd = 2; /*NYSE listed*/
if ret>-1;          /*keep if ret >-100%*/
mktval= prc*shrout; /*calculate market value*/
if mktval >0;       /*keep if mcap is greater than zero*/
year= year(date);
Month=Month(date);
if 1996<=year<=2018;

cusip_e=CUSIP;  /*This variable is new, I will use this to match CRSP and compustat*/
run;

/*COMPUSTAT dataset*/
data HW3_Comp;
set BADM.Compustat ;  
if AT = . then delete;/*no total asset reported*/
if AT = 0 then delete; /*zero total assets then delete*/
if sale < 0 then delete; /*negative sales then delete*/
run; 



/*1)  Using data for the period between 2010 and 2014 (five years) to estimate Betas of individual stocks. */

data HW3_CRSP_b;
set HW3_CRSP;
if 2010<=year<=2014;
run; 


proc sort data = HW3_CRSP_b;
by cusip_e;
run;
 

ods graphics off;
proc reg data = HW3_CRSP_b OUTEST=betas2 noprint  ; /*OUTEST saves your betas*/
by cusip_e ;
model ret  = VWRETD ;
run;


/*some data cleaning*/

data betas2; 
set betas2;
beta = VWRETD;
keep cusip_e beta   ;
run ; 

/*Then, for each month of the period between 2015 and 2017, the following cross-sectional regression is run:
               Ri = L0 + L1 Betai + L2 ln(MEi) + L3 ln(BE/MEi) + error termi,  i = 1, 2 ...
The independent variable Betai is the Beta for stocks i. 
MEi is the market value (size) of equity for stock i 
and BE/MEi is the book-to-market ratio for stock i. 
The values of both MEi and BE/MEi for a given year are determined by the information available in December of previous year. 
The dependent variable Ri is the monthly return of stock i.
*/ 

/*Betai variables are in Betas2 dataset */

/*I need to calculate size and BE/MEi   */  

/* BE book value per share from compustat: BKVLPS: Dollars and cents*/
/* ME market value of equity per share from CRSP: PRC : Dollars and cents */
/* MV of equity (size) =prc*shrout,  price times number of shares outstanding from CRSP*/


/*I need to merge CRSP and compustat datasets. All I need is December values. */

data comp_2;
set HW3_Comp ;
year=year(DATADATE);
month=month(DATADATE);
if month=12; /*all we need is december values*/
run;


data Crsp_2;
set HW3_CRSP; 
if month=12; /*all we need is december values*/
run ; 


/*We need to merge CRSP & Compustat datasets*/
/* To merge them I will use CUSIP and Year */
/* CRSP CUSIP has 8 digits, COMPUSTAT CUSIP has 9 digits. I need to cut one digit from Compustat CUSIP */ 

data comp_3 (keep= cusip_e BKVLPS year );
set comp_2;
cusip_e= substr(cusip, 1, 8); /*cut compustat 9 digit cusip to 8 digit CRSP  cusip */

run; 

data crsp_3 (keep=cusip_e  PRC year shrout) ; 
set Crsp_2 ;
cusip_e=CUSIP; 
run; 

proc sort data = comp_3;
by cusip_e year;
run;


proc sort data = crsp_3;
by cusip_e year;

run;

data size_MB;
merge crsp_3 comp_3;
by cusip_e year; 
MV_eq=  prc*shrout ; /* MV of equity (size) =prc*shrout*/
ln_ME=log(MV_eq);
ln_BM= log(BKVLPS / prc); 
if ln_Me=. then delete;
if ln_BM=. then delete;
run;


/*Now we need to merge CRSP monthly return, SIZE_MB and BETAS2 datasets. */

/*I need CRSP returns  for each month of the period between 2015 and 2017,*/

data crsp0305;
set HW3_CRSP;
if 2015<=year<=2017;
keep cusip_e ret year month;
run;

/*I need SIZE_MB of previous years  between 2015 and 2017 */
/* I will increase year by +1, in size_MB dataset */

data size_MB0305;
set size_MB;
year=year+1;
keep cusip_e year ln_ME ln_BM;
run;




/*Merge crsp0305 & size_MB0305*/
proc sort data = crsp0305;
by cusip_e year;
run;


proc sort data = size_MB0305;
by cusip_e year;
run;


data retsizemb;
merge crsp0305 size_MB0305;
by cusip_e year;
if ln_Me=. then delete;
if ln_BM=. then delete;
if 2015<=year<=2017;
run;

/*Merge betas to retsizemb*/

proc sort data = betas2;
by cusip_e ;
run; 

proc sort data = retsizemb;
by cusip_e ;
run; 

data final;
merge retsizemb betas2; 
by cusip_e ;
if ln_Me=. then delete;
if ln_BM=. then delete;
if month=. then delete;
run; 

 


 /*Run regression for each month of the period*/


proc sort data = final;
by year month ;  
run;



ods graphics off;
proc reg data = final OUTEST=Lambdas_partb noprint  ; 
by year month ;          /*Run regression for each month of the period*/
model   ret  =  beta ln_me ln_BM;            /*this is   Ri = L0 + L1 Betai + L2 ln(MEi) + L3 ln(BE/MEi)+ error termi,   */
run;


/*data cleaning*/

data Lambdas_partb (keep = year month L0 L1 L2 L3);
set Lambdas_partb;
L0=Intercept;
L1= beta ; /*lambda1, gamma1 in HW*/
L2=ln_me; /*lambda2, gamma2 in HW*/
L3=ln_bm; /*lambda3, gamma3 in HW*/

run; 

/*Finally, calculate mean, standard deviation and t-stat of Lambda1 over the period of 36 months.*/

proc sort data = Lambdas_partb ;
by  year month  ;
run;

/* Lambda1 */

Proc means data  =Lambdas_partb  noprint;
var L1 L2 L3 ;
output out=test_stat_partb  
mean(L1)=Mean_L1 Std(L1)=Std_L1  
mean(L2)=Mean_L2 Std(L2)=Std_L2
mean(L3)=Mean_L3 Std(L3)=Std_L3  
;
run;

/*Final test statistics See Fama MacBeth Page 619 */

data test_stat_partb;
set test_stat_partb;
sq_n=sqrt(36); /*SAS functions  https://stats.idre.ucla.edu/sas/modules/using-sas-functions-for-making-and-recoding-variables/ */
t_stat1= Mean_L1 /(Std_L1/ sq_n); /*Final test statistics See Fama MacBeth Page 619 */
t_stat2= Mean_L2 /(Std_L2/ sq_n);
t_stat3= Mean_L3 /(Std_L3/ sq_n);
run;






