
/*HW 3 solutions*/

libname BADMSAS "\\files\users\mdniazc\Desktop\BADMSAS";
run; 


 
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
if 1998<=year<=2002;
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
set HW3;
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
set BADMSAS.CRSPhw1 ;
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

data HW3_Compustat1;
set BADMSAS.Cusipnew ;  
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

data comp_2N;
set HW3_Compustat ;
year=year(DATADATE);
month=month(DATADATE);
if month=12; /*all we need is december values*/
run;


data Crsp_2N;
set HW3_CRSP; 
if month=12; /*all we need is december values*/
run ; 


/*We need to merge CRSP & Compustat datasets*/
/* To merge them I will use CUSIP and Year */
/* CRSP CUSIP has 8 digits, COMPUSTAT CUSIP has 9 digits. I need to cut one digit from Compustat CUSIP */ 

data comp_3N (keep= cusip_e BKVLPS year );
set comp_2N;
cusip_e= substr(cusip, 1, 8); /*cut compustat 9 digit cusip to 8 digit CRSP  cusip */

run; 

data crsp_3N (keep=cusip_e  PRC year shrout) ; 
set Crsp_2N ;
cusip_e=CUSIP; 
run; 

proc sort data = comp_3N;
by cusip_e year;
run;


proc sort data = crsp_3N;
by cusip_e year;
run;

data size_MBN;
merge crsp_3N comp_3N;
by cusip_e year; 
MV_eq=  prc*shrout ; /* MV of equity (size) =prc*shrout*/
ln_ME=log(MV_eq);
ln_BM= log(BKVLPS / prc); 
if ln_Me=. then delete;
if ln_BM=. then delete;
run;


/*Now we need to merge CRSP monthly return, SIZE_MB and BETAS2 datasets. */

/*I need CRSP returns  for each month of the period between 2015 and 2017,*/

data crsp0305N;
set HW3_CRSP;
if 2015<=year<=2017;
keep cusip_e ret year month;
run;

/*I need SIZE_MB of previous years  between 2015 and 2017 */
/* I will increase year by +1, in size_MB dataset */

data size_MB0305N;
set size_MBN;
year=year+1;
keep cusip_e year ln_ME ln_BM;
run;




/*Merge crsp0305 & size_MB0305*/
proc sort data = crsp0305N;
by cusip_e year;
run;


proc sort data = size_MB0305N;
by cusip_e year;
run;


data retsizembN;
merge crsp0305N size_MB0305N;
by cusip_e year;
if ln_Me=. then delete;
if ln_BM=. then delete;
if 2015<=year<=2017;
run;

/*Merge betas to retsizemb*/

proc sort data = betas2;
by cusip_e ;
run; 

proc sort data = retsizembN;
by cusip_e ;
run; 

data finalN;
merge retsizembN betas2; 
by cusip_e ;
if ln_Me=. then delete;
if ln_BM=. then delete;
if month=. then delete;
run; 

 


 /*Run regression for each month of the period*/


proc sort data = finalN;
by year month ;  
run;



ods graphics off;
proc reg data = finalN OUTEST=Lambdas_partbN noprint  ; 
by year month ;          /*Run regression for each month of the period*/
model   ret  =  beta ln_me ln_BM;            /*this is   Ri = L0 + L1 Betai + L2 ln(MEi) + L3 ln(BE/MEi)+ error termi,   */
run;


/*data cleaning*/

data Lambdas_partbN (keep = year month L0 L1 L2 L3);
set Lambdas_partbN;
L0=Intercept;
L1= beta ; /*lambda1, gamma1 in HW*/
L2=ln_me; /*lambda2, gamma2 in HW*/
L3=ln_bm; /*lambda3, gamma3 in HW*/

run; 

/*Finally, calculate mean, standard deviation and t-stat of Lambda1 over the period of 36 months.*/

proc sort data = Lambdas_partbN ;
by  year month  ;
run;

/* Lambda1 */

Proc means data  =Lambdas_partbN  noprint;
var L1 L2 L3 ;
output out=test_stat_partbN  
mean(L1)=Mean_L1 Std(L1)=Std_L1  
mean(L2)=Mean_L2 Std(L2)=Std_L2
mean(L3)=Mean_L3 Std(L3)=Std_L3  
;
run;

/*Final test statistics See Fama MacBeth Page 619 */

data test_stat_partbN;
set test_stat_partbN;
sq_n=sqrt(36); /*SAS functions  https://stats.idre.ucla.edu/sas/modules/using-sas-functions-for-making-and-recoding-variables/ */
t_stat1= Mean_L1 /(Std_L1/ sq_n); /*Final test statistics See Fama MacBeth Page 619 */
t_stat2= Mean_L2 /(Std_L2/ sq_n);
t_stat3= Mean_L3 /(Std_L3/ sq_n);
run;


