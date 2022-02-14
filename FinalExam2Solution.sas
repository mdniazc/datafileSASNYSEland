/*Final Exam 2 solutions*/

libname BADMSAS "\\files\users\mdniazc\Desktop\BADMSAS";
run; 

/* Dataset from Assignmnet 1 and 2*/



/**********************************************/
/*Create a sample of NYSE listed common stock from 1996<=year<=2018*/
/*This is the same CRSP dataset from HW2*/
/*CRSP Dataset*/

data HW3;
set BADMSAS.crsphw1 ;
If SHRCD = 10 or Shrcd = 11; 
If Exchcd = 1 or Exchcd = 2; 
if ret>-1;          
mktval= prc*shrout; 
if mktval >0;       
year= year(date);
Month=Month(date);
if 1996<=year<=2018;
cusip_e=CUSIP;
run;



/*COMPUSTAT dataset*/
data HW3_Compustat;
set BADMSAS.Cusipnew ; 
if AT = . then delete;/*no total asset reported*/
if AT = 0 then delete; /*zero total assets then delete*/
if sale < 0 then delete; /*negative sales then delete*/
run; 



data Crsp_2;
set HW3; 
if month=12; /*all we need is december values*/
run ; 



data comp_2;
set HW3_Compustat ;
year=year(DATADATE);
month=month(DATADATE);
if month=12; 
if 1996<=year<=2018;
run;





data comp_3 (keep= cusip_e BKVLPS  year );
set comp_2;
cusip_e= substr(cusip, 1, 8); /*cut compustat 9 digit cusip, just keep first 1-8 digits, and now it is same as 8 digit CRSP  cusip */
if AT = . then delete;/*no total asset reported*/
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

data crsp9618;
set HW3;
if 1996<=year<=2018;
keep cusip_e ret year month;
run;


/*I need SIZE_MB of previous years  between 2003 and 2005 */
/* I will increase year by +1, in size_MB dataset */

data size_MB9618;
set size_MB;
year=year+1;
keep cusip_e year ln_ME ln_BM;
run;


/*Merge crsp9618 & size_MB9618*/

proc sort data = crsp9618;
by cusip_e year;
run;


proc sort data = size_MB9618;
by cusip_e year;
run;


data retsizemb;
merge crsp9618 size_MB9618;
by cusip_e year;
if ln_Me=. then delete;
if ln_BM=. then delete;
if 1996<=year<=2018;
run;

data final;
set retsizemb;
BMVRatio= ln_BM/ln_ME;
run;

*******************************************************************************
/* ranked into five portfolio based on Earnings per share Ratio in December */


proc sort data = final;
by year BMVRatio;
run;


/*create 5 portfolios based on  in each year, name portfolios as port*/
proc rank data = final out=ports groups=5;
ranks port;
var BMVRatio;
by year;
run;


/*increase port value by 1 */
data ports ;
set ports;
port=port+1;
run;


proc sort data = ports ;
by year BMVRatio;
run;


data all;
set ports;
if ret = . or port = . then delete;
run;

/*Sort all dataset by year and port*/
proc sort data = all;
by year month port ;
run;


/*create a dataset that has mean returns for each portfolio in each year month*/
/*This is an equally weighted portfolio, porftolio returns are calculated monthly. */

proc means data = all noprint;
var ret ;
by year month port ;
output out=results  mean=ret_port;
run;



/*Calculate means of monthly returns of ten portfolios over the study period. */
proc sort data = results ; 
by port year month;
run; 


proc means data = results noprint;
var ret_port ;
by port ;
output out=MeanPort_Ret  mean=MeanPort_Ret;
run;



/*Also, perform a test to investigate whether 
the small sized portfolio statistically outperform the large sized portfolio. */

data P1; /*small sized porftolio, monthly returns*/
set results;
if port=1;
ret_p1=ret_port;
keep year month ret_p1;
run;

data P2; /*small sized porftolio, monthly returns*/
set results;
if port=2;
ret_p2=ret_port;
keep year month ret_p2;
run;

data P3; /*small sized porftolio, monthly returns*/
set results;
if port=3;
ret_p3=ret_port;
keep year month ret_p3;
run;

data P4; /*small sized porftolio, monthly returns*/
set results;
if port=4;
ret_p4=ret_port;
keep year month ret_p4;
run;

data P5; /*small sized porftolio, monthly returns*/
set results;
if port=5;
ret_p5=ret_port;
keep year month ret_p5;
run;

/*sort portfolio 1 dataset by year*/

proc sort data = p1 ;
by year month;
run;

/*sort portfolio 5 dataset by year*/
proc sort data = p5;
by year month;
run;


/*merge portfolio 1 and portfolio 5 datasets by year and calculate difference in returns*/
data p1p5;
merge p1 p5;
by year month;
diff=ret_p1 - ret_p5 ;
run; 

proc ttest data = p1p5 h0=0;
var diff;
run;


/*merge portfolio 1 and portfolio 5 datasets by year and calculate difference in returns*/
data p5p1;
merge p1 p5;
by year month;
diff=ret_p5 - ret_p1 ;
run; 

proc ttest data = p5p1 h0=0;
var diff;
run;


proc ttest data = p1 h0=0;
var ret_p1;
run;

proc ttest data = p2 h0=0;
var ret_p2;
run;

proc ttest data = p3 h0=0;
var ret_p3;
run;

proc ttest data = p4 h0=0;
var ret_p4;
run;

proc ttest data = p5 h0=0;
var ret_p5;
run;


/***************************************************************************************************************/
/*  At the beginning of each year, 
/*all stocks are ranked into five portfolios based on their Earnings Per Share-to-Price ratios in December of previous year*/
/*These portfolios are equally weighted at formation and held for subsequent 12 months during which returns are realized monthly. 
Calculate means of monthly returns of five portfolios for each calendar month over the study period. 
Also, perform tests to investigate whether the difference in performance between the value portfolio 
and growth portfolio is statistically significant. Please use the table below to present your final results. */ 
/***************************************************************************************************************/



data HW3F2;
set BADMSAS.crsphw1 ;
If SHRCD = 10 or Shrcd = 11; 
If Exchcd = 1 or Exchcd = 2; 
if ret>-1;          
mktval= prc*shrout; 
if mktval >0;       
year= year(date);
Month=Month(date);
if 1996<=year<=2018;
cusip_e=CUSIP;
run;


/*COMPUSTAT dataset*/

data HW3_CompustatF2;
set BADMSAS.Cusipnew ; 
if AT = . then delete;/*no total asset reported*/
if AT = 0 then delete; /*zero total assets then delete*/
if sale < 0 then delete; /*negative sales then delete*/
run;




data Crsp_2F2;
set HW3F2; 
if month=12; /*all we need is december values*/
run ; 



data comp_2F2;
set HW3_CompustatF2 ;
year=year(DATADATE);
month=month(DATADATE);
if month=12; 
if 1996<=year<=2018;
run;



data comp_3F2 (keep= cusip_e  EPSPX year );
set comp_2F2;
cusip_e= substr(cusip, 1, 8); /*cut compustat 9 digit cusip, just keep first 1-8 digits, and now it is same as 8 digit CRSP  cusip */
if EPSPX = . then delete;/*no total asset reported*/
run; 



data crsp_3F2 (keep=cusip_e  PRC year shrout mktval) ; 
set Crsp_2F2 ;
cusip_e=CUSIP; 
run; 
 

proc sort data = comp_3F2;
by cusip_e year;
run;


proc sort data = crsp_3F2;
by cusip_e year;
run;



data size_MBF2N; /******YOU WILL NEED to merge CRSP and Compustat for the final as I do here, Also you will no to calculate:  Book to market = BKVLPS / prc, and Earnings to Price = EPSPX / prc  ****/
merge crsp_3F2 comp_3F2;
by cusip_e year; 
PR=  prc*shrout ; 
ln_PR=log(PR);
ln_EPS= log(EPSPX); 
if ln_PR=. then delete;
if ln_EPS=. then delete;
if ln_EPS=0 then delete;
run;


/*Now we need to merge CRSP monthly return, SIZE_MB  datasets. */

/*I need CRSP returns  for each month of the period between 1996 and 2018,*/

data crsp9618F2N;
set HW3F2;
if 1996<=year<=2018;
keep cusip_e ret year month;
run;


/*I need SIZE_MB of previous years  between 2003 and 2005 */
/* I will increase year by +1, in size_MB dataset */

data size_MB9618F2N;
set size_MBF2N;
year=year+1;
keep cusip_e year ln_PR ln_EPS;
run;


/*Merge crsp9618 & size_MB9618*/

proc sort data = crsp9618F2N;
by cusip_e year;
run;


proc sort data = size_MB9618F2N;
by cusip_e year;
run;


data retsizembF2N;
merge crsp9618F2N size_MB9618F2N;
by cusip_e year;
if ln_PR=. then delete;
if ln_EPS=. then delete;
if ln_EPS=0 then delete;
if 1996<=year<=2018;
run;


data finalF2N;
set retsizembF2N;
EPRatio= ln_PR/ln_EPS;
run;

/*******************************************************************************/
/* ranked into five portfolio based on Earnings per share Ratio in December */


proc sort data = finalF2N;
by year EPRatio;
run;


/*create 5 portfolios based on  in each year, name portfolios as port*/
proc rank data = finalF2N out=portsF2N groups=5;
ranks port;
var EPRatio;
by year;
run;


/*increase port value by 1 */
data portsF2N ;
set portsF2N;
port=port+1;
run;


proc sort data = portsF2N ;
by year EPRatio;
run;


data allF2;
set portsF2N;
if ret = . or port = . then delete;
run;

/*Sort all dataset by year and port*/
proc sort data = allF2;
by year month port ;
run;


/*create a dataset that has mean returns for each portfolio in each year month*/
/*This is an equally weighted portfolio, porftolio returns are calculated monthly. */

proc means data = allF2 noprint;
var ret ;
by year month port ;
output out=resultsF2  mean=ret_port;
run;



/*Calculate means of monthly returns of ten portfolios over the study period. */
proc sort data = resultsF2 ; 
by port year month;
run; 


proc means data = resultsF2 noprint;
var ret_port ;
by port ;
output out=MeanPort_RetF2N  mean=MeanPort_RetF2N;
run;



/*Also, perform a test to investigate whether 
the small sized portfolio statistically outperform the large sized portfolio. */

data P1F2; /*small sized porftolio, monthly returns*/
set resultsF2;
if port=1;
ret_p1=ret_port;
keep year month ret_p1;
run;

data P2F2; /*small sized porftolio, monthly returns*/
set resultsF2;
if port=2;
ret_p2=ret_port;
keep year month ret_p2;
run;

data P3F2; /*small sized porftolio, monthly returns*/
set resultsF2;
if port=3;
ret_p3=ret_port;
keep year month ret_p3;
run;

data P4F2; /*small sized porftolio, monthly returns*/
set resultsF2;
if port=4;
ret_p4=ret_port;
keep year month ret_p4;
run;

data P5F2; /*small sized porftolio, monthly returns*/
set resultsF2;
if port=5;
ret_p5=ret_port;
keep year month ret_p5;
run;

/*sort portfolio 1 dataset by year*/

proc sort data = p1F2 ;
by year month;
run;

/*sort portfolio 5 dataset by year*/
proc sort data = p5F2;
by year month;
run;


/*merge portfolio 1 and portfolio 5 datasets by year and calculate difference in returns*/
data p1F2p5F2;
merge p1F2 p5F2;
by year month;
diff=ret_p5 - ret_p1 ;
run; 

proc ttest data = p1f2p5F2 h0=0;
var diff;
run;


/*merge portfolio 1 and portfolio 5 datasets by year and calculate difference in returns*/
data p5F2p1F2;
merge p1F2 p5F2;
by year month;
diff=ret_p1 - ret_p5 ;
run; 

proc ttest data = p5F2p1F2 h0=0;
var diff;
run;


proc ttest data = p1F2 h0=0;
var ret_p1;
run;

proc ttest data = p2F2 h0=0;
var ret_p2;
run;

proc ttest data = p3F2 h0=0;
var ret_p3;
run;

proc ttest data = p4F2 h0=0;
var ret_p4;
run;

proc ttest data = p5F2 h0=0;
var ret_p5;
run;


/* Using data for the period between 2010 and 2014 (five years) to estimate s of individual stocks. 
Then, for each month of the period between 2015 and 2017, the following cross-sectional regression is run:
The independent variable i is the  for stocks i. E/Pi is the Earnings Per Share to Price ratio for
stock i and BE/MEi is the book-to-market ratio for stock i. The values of both E/Pi and BE/MEi for a
given year are determined by the information available in December of previous year. The dependent
variable Ri is the monthly return of stock i. */


/*Final Exam 2 solutions*/

libname BADMSAS "\\files\users\mdniazc\Desktop\BADMSAS";
run; 

/* Dataset from Assignmnet 1 and 2*/



/**********************************************/
/*Create a sample of NYSE listed common stock from 1996<=year<=2018*/
/*This is the same CRSP dataset from HW2*/
/*CRSP Dataset*/

data HW3;
set BADMSAS.crsphw1 ;
If SHRCD = 10 or Shrcd = 11; 
If Exchcd = 1 or Exchcd = 2; 
if ret>-1;          
mktval= prc*shrout; 
if mktval >0;       
year= year(date);
Month=Month(date);
if 1996<=year<=2018;
cusip_e=CUSIP;
run;



/*COMPUSTAT dataset*/
data HW3_Compustat;
set BADMSAS.Cusipnew ; 
if AT = . then delete;/*no total asset reported*/
if AT = 0 then delete; /*zero total assets then delete*/
if sale < 0 then delete; /*negative sales then delete*/
run; 



/*1)  Using data for the period between 1998 and 2002 (five years) to estimate Betas of individual stocks. */

data HW3_C;
set HW3;
if 2010<=year<=2014;
run; 


proc sort data = HW3_C;
by cusip_e;
run;
 

ods graphics off;
proc reg data = HW3_C OUTEST=betas2N noprint  ; /*OUTEST saves your betas to betas2 dataset*/
by cusip_e ;
model ret  = VWRETD ;
run;


/*some data cleaning*/


data betas2N; /*Betai variables are in Betas2 dataset */
set betas2N;
beta = VWRETD;
keep cusip_e beta   ;
run ; 


 /*I need to calculate size and BE/MEi   */  

/* BE book value per share from compustat: BKVLPS: Dollars and cents*/
/* ME market value of equity per share from CRSP: PRC : Dollars and cents */
/* MV of equity (size) =prc*shrout,  price times number of shares outstanding from CRSP*/


/*I need to merge CRSP and compustat datasets. All I need is December values. */




data comp_2;
set HW3_Compustat ;
year=year(DATADATE);
month=month(DATADATE);
if month=12; 
run;


data Crsp_2;
set HW3; 
if month=12; /*all we need is december values*/
run ; 

/*We need to merge CRSP & Compustat datasets*/
/* To merge them I will use CUSIP and Year */
/* CRSP CUSIP has 8 digits, COMPUSTAT CUSIP has 9 digits. I need to cut one digit from Compustat CUSIP */ 

data comp_3 (keep= cusip_e BKVLPS  EPSPX  year );
set comp_2;
cusip_e= substr(cusip, 1, 8); /*cut compustat 9 digit cusip, just keep first 1-8 digits, and now it is same as 8 digit CRSP  cusip */
if AT = . then delete;/*no total asset reported*/
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
ln_EPS= log(EPSPX); 
if ln_EPS=. then delete;
if ln_EPS=0 then delete;
run;




/*Now we need to merge CRSP monthly return, SIZE_MB and BETAS2 datasets. */

/*I need CRSP returns  for each month of the period between 2015 and 2017,*/

data crsp1517;
set HW3;
if 2015<=year<=2017;
keep cusip_e ret year month;
run;


/*I need SIZE_MB of previous years  between 2003 and 2005 */
/* I will increase year by +1, in size_MB dataset */

data size_MB1517;
set size_MB;
year=year+1;
keep cusip_e year ln_ME ln_BM ln_EPS ;
run;


/*Merge crsp1517 & size_MB1517*/

proc sort data = crsp1517;
by cusip_e year;
run;


proc sort data = size_MB1517;
by cusip_e year;
run;


data retsizemb;
merge crsp1517 size_MB1517;
by cusip_e year;
if ln_Me=. then delete;
if ln_BM=. then delete;
if 2015<=year<=2017;
run;


/*Merge betas to retsizemb*/

proc sort data = betas2N;
by cusip_e ;
run; 

proc sort data = retsizemb;
by cusip_e ;
run; 

data final;
merge retsizemb betas2N; 
by cusip_e ;
if ln_Me=. then delete;
if ln_BM=. then delete;
if ln_EPS=. then delete;
if month=. then delete;
run; 

/*Run regression for each month of the period*/


proc sort data = final;
by year month ;  
run;


/*Question 4*/ 
/*Report means, standard deviations and t-stats of L1, L2 , L3  over the period of 36 months.*/

proc sort data = final;
by year month ;  
run;


ods graphics off;
proc reg data = final OUTEST=LambdasQ3 noprint  ; /*save your coefficients in Lamdas dataset*/
by year month ;                               /*Run regression for each month of the period*/
model   ret  =  beta ln_EPS ln_me;            /*this is   Ri = L0 + L1 Betai + L2 ln(MEi) + L3 ln(BE/MEi)+ error termi,   */
run;


/*data cleaning*/

data lambdasQ3 (keep=keep year month L0 L1 L2 L3); /*Keep only the variables you will need*/
set lambdasQ3;
L0=Intercept;
L1= beta ; /*lambda1, gamma1 in HW*/
L2=ln_EPS; 
L3=ln_me; /*lambda2, gamma2 in HW*/
run; 

/*Finally, calculate mean, standard deviation and t-stat of Lambdas over the period of 36 months.*/

proc sort data = lambdasQ3 ;
by  year month  ;
run;


/* Lambda1 */

Proc means data  =LambdasQ3  noprint;
var L1 L2 L3 ;
output out=test_statQ3  
mean(L1)=Mean_L1 Std(L1)=Std_L1  
mean(L2)=Mean_L2 Std(L2)=Std_L2
mean(L3)=Mean_L3 Std(L3)=Std_L3  
;
run;

/*Final test statistics See Fama MacBeth Page 619 */

data test_statQ3N1;
set test_statQ3;
sq_n=sqrt(36); /*SAS functions  https://stats.idre.ucla.edu/sas/modules/using-sas-functions-for-making-and-recoding-variables/ */
t_stat1= Mean_L1 /(Std_L1/ sq_n); /*Final test statistics See Fama MacBeth Page 619 */
t_stat2= Mean_L2 /(Std_L2/ sq_n);
t_stat3= Mean_L3 /(Std_L3/ sq_n);
run;




/*Question 4*/ 
/*Report means, standard deviations and t-stats of L1, L2 , L3 and L4 over the period of 36 months.*/

ods graphics off;
proc reg data = final OUTEST=LambdasQ4 noprint  ; /*save your coefficients in Lamdas dataset*/
by year month ;                               /*Run regression for each month of the period*/
model   ret  =  beta ln_EPS ln_me ln_BM;            /*this is   Ri = L0 + L1 Betai + L2 ln(MEi) + L3 ln(BE/MEi)+ error termi,   */
run;


/*data cleaning*/

data lambdasQ4 (keep=keep year month L0 L1 L2 L3 L4); /*Keep only the variables you will need*/
set lambdasQ4;
L0=Intercept;
L1= beta ; /*lambda1, gamma1 in HW*/
L2=ln_EPS; 
L3=ln_me; /*lambda2, gamma2 in HW*/
L4=ln_bm; /*lambda3, gamma3 in HW*/
run; 

/*Finally, calculate mean, standard deviation and t-stat of Lambdas over the period of 36 months.*/

proc sort data = lambdasQ4 ;
by  year month  ;
run;


/* Lambda1 */

Proc means data  =LambdasQ4  noprint;
var L1 L2 L3 L4 ;
output out=test_statQ4  
mean(L1)=Mean_L1 Std(L1)=Std_L1  
mean(L2)=Mean_L2 Std(L2)=Std_L2
mean(L3)=Mean_L3 Std(L3)=Std_L3  
mean(L4)=Mean_L4 Std(L3)=Std_L4 
;
run;

/*Final test statistics See Fama MacBeth Page 619 */

data test_statQ4N;
set test_statQ4;
sq_n=sqrt(36); /*SAS functions  https://stats.idre.ucla.edu/sas/modules/using-sas-functions-for-making-and-recoding-variables/ */
t_stat1= Mean_L1 /(Std_L1/ sq_n); /*Final test statistics See Fama MacBeth Page 619 */
t_stat2= Mean_L2 /(Std_L2/ sq_n);
t_stat3= Mean_L3 /(Std_L3/ sq_n);
t_stat4= Mean_L4 /(Std_L4/ sq_n);
run;
