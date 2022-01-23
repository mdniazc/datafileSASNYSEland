

/*BADM class SAS notes*/
/* type your code in editor, to run your code: select the code and hit Running man at the top.*/
/*you can comment using  */
/*SAS does not execute the comments. */
/*WORK is a temporary library, everything in it will be deleted once you end your SAS session. So, you should save your data in a 
permanant library you created with libname command. 
Also save your sas code in your flash drive so you can reach it later.*/

/*Creating a library (BADM) in the folder located in " ... " */

libname BADM "\\tsclient\H\BADM742SAS" ;
run;

libname BADM "G:\Box Sync\TeachingSpring2020\BADM742SAS";
run;


libname BADM "H:\BADM742SAS" ;
run; 


/*Feb 25 2020 Class participation solution*/
/*
Following the Feb18 class notes and SAS code conduct the following Group means tests:

If we sort stocks into 10 portfolios based on their market capitalization in August,

Is there a significant difference across portfolio performance in January of the next year? 

Bring your SAS code and final results (Returns of portfolios 1 and 10, difference, t-stat and p-value of difference) */


/* Using Code from */
/*Feb 18 class notes*/


/*Create a sample of NYSE listed common stock from 2010 to 2015 (2009<year<2016)*/
  
data BADM.NYSE_5y;
set BADM.CRSP ;
If SHRCD = 10 or Shrcd = 11;
If Exchcd = 1 or Exchcd = 2;
year= year(date);
if 2009<year<2016;
run;



/*create a data set for Aug */
data Aug;
set BADM.NYSE_5y;
year=year(date);
month=month(date);
if month=8;        /*keep if month is december*/
if ret>-1;          /*keep if ret >-100%*/
mktval= prc*shrout; /*calculate market value*/
if mktval >0;       /*keep if mcap is greater than zero*/
keep permno year mktval;
run;


/*sort stocks in dec by year and market value*/
proc sort data = Aug;
by year mktval;
run;


/*create 10 portfolios based on mktval in each year, name portfolios as port*/
proc rank data = Aug out=ports groups=10;
ranks port;
var mktval;
by year;
run;

/*increase port value by 1 and only keep permno year port*/
data ports ;
set ports;
port=port+1;
keep permno year port;
run;

 /*create a data set for Jan */
data Jan;
set BADM.NYSE_5y;
year=year(date);
month=month(date);
if month=1;
if ret>-1;
mktval= prc*shrout;
if mktval >0;
keep permno year ret ;
run;

/*increase year by 1*/
data ports1;
set ports;
year=year+1;
run;

/*sort ports1 dataset by permno and year*/
proc sort data = ports1 ;
by permno year;
run;

/*sort jan dataset by permno and year*/
proc sort data = Jan;
by permno year;
run;

/*merge Jan and Ports1 dataset by permno and year; delete missing returns and port  */
data all;
merge jan ports1;
by permno year;
if ret = . or port = . then delete;
run;

/*Sort all dataset by year and port*/
proc sort data = all;
by year port;
run;

/*create a dataset that has mean returns for each portfolio in each year*/
proc means data = all noprint;
var ret ;
by year port;
output out=results  mean=ret_port;
run;

/*Just keep the variables you need for your tests. year port ret_port*/
data results ;
set results;
keep year port ret_port;
run;

/*create a dataset for portfolio 1, keep only year and portfolio return in the dataset */
data p1;
set results;
if port=1;
ret_p1=ret_port;
keep year ret_p1;
run;

/*create a dataset for portfolio 10, keep only year and portfolio return in the dataset */
data P10;
set results;
if port=10;
ret_p10=ret_port;
keep year ret_p10;
run;

/*sort portfolio 1 dataset by year*/
proc sort data = p1 ;
by year;
run;

/*sort portfolio 10 dataset by year*/
proc sort data = p10;
by year;
run;

/*merge portfolio 1 and portfolio 10 datasets by year and calculate difference in returns*/
data p1p10;
merge p1 p10;
by year;
diff=ret_p1 - ret_p10 ;
run;

/*test if the difference between returns in portfolio 1 and portfolio 10 is statistically different than zero. */
proc ttest data = p1p10 h0=0;
var diff;
run;
/*Mean: 0.0762 t-stat: 2.35 p-value: 0.0786 */



/*Easley, D., Hvidkjaer, S.,   O’Hara, M. (2010). Factoring information into returns.

V. Factor Tests 
page 13 */




/*correlation analysis proc*/
/*correlation between portfolio returns*/
proc corr data =p1p10;
var ret_p1 ret_p10;
run; 


/*examine correlation between an asset return and market returns over years*/



data coid;
set BADM.NYSE_5y;
if permno=11707; /*Camprex corp*/
year=year(date);
*keep permno year ret sprtrn COMNAM; 
run;



/*Scatter plots*/
/*for more details:  http://support.sas.com/documentation/cdl/en/graphref/63022/HTML/default/viewer.htm#axischap.htm */ 

/*The most basic plots*/
proc gplot data=coid;
     plot ret*sprtrn;
	 run ;



/*Add titles*/

proc gplot data=coid;
     plot ret*sprtrn;

     title 'Camprex Corporation CAPM Example';
     title2'Plot of Risk Premiums';
     title3'Camprex Corporation versus the Market';

run ;

/*Add symbols*/
proc gplot data=coid;
     plot ret*sprtrn;

 symbol1 c=blue v=star;

     title 'Camprex Corporation CAPM Example';
     title2'Plot of Risk Premiums';
     title3'Camprex Corporation versus the Market';

run ;


/*modify Axis*/

proc gplot data=coid ;
     plot ret*sprtrn /haxis=axis1 hminor=4 cframe=ligr
                      vaxis=axis2 vminor=4;

 symbol1 c=blue v=star;

axis1 order=(-0.1 to 0.12 by 0.2);
axis2 label=(angle=90 'Camprex Corp. Risk Premium')
          order=(-0.3 to 0.6 by 0.2);

     title 'Camprex Corporation CAPM Example';
     title2'Plot of Risk Premiums';
     title3'Camprex Corporation versus the Market';

run ;


/**/

proc sort data = coid;
by year;
run;

proc corr data = coid ;
var ret sprtrn;
by year;
run;  


/*regression analysis*/
proc sort data = coid ;
by year;
run; 

proc reg data=coid;
model ret = sprtrn;
by year;
run;

proc sort data = BADM.NYSE_5y out =allcoid;
by permno;
run;

proc reg data = allcoid noprint outest= final;
model ret= sprtrn;
by permno;
run; 



/*a simple test of CAPM assuming monthly rf=0*/

data coid2;
set coid;
r_mkt= sprtrn ; 
r_camp =ret;
run ;


   proc reg data=coid2;
     model r_camp = r_mkt ;
     test r_mkt = 1;
     run;
