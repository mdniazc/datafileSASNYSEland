

/*HW 1 solutions*/

libname BADMSAS "\\files\users\mdniazc\Desktop\BADMSAS";
run; 


/*Create a sample of NYSE listed common stock from 1996<=year<=2018*/
  
data hw1NYSE;
set BADMSAS.crsphw1;
If SHRCD = 10 or Shrcd = 11;
If Exchcd = 1 or Exchcd = 2;
year= year(date);
if 1995<year<2019;
run;




/*Portfolios are created by market value in December at the end of each year  */
data december;
set hw1NYSE;
year=year(date);
month=month(date);
if month=12;        /*keep if month is december*/
if ret>-1;          /*keep if ret >-100%*/
mktval= prc*shrout; /*calculate market value*/
if mktval >0;       /*keep if mcap is greater than zero*/
keep permno year mktval ;
run;



/*sort stocks in dec by year and market value*/
proc sort data = december;
by year mktval;
run;



/*create 10 portfolios based on mktval in each year, name portfolios as port*/
proc rank data = december out=ports groups=10;
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


 /*create an annual return dataset */
data Ret_ann;
set hw1NYSE;
year=year(date);
month=month(date);
if ret>-1;
mktval= prc*shrout;
if mktval >0;
keep permno year ret month;
run;


/*increase year by 1*/  


data ports1;
set ports;
year=year+1; /*ranking is based on previous year's market value*/
run;


/*sort ports1 dataset by permno and year*/
proc sort data = ports1 ;
by permno year;
run;


/*sort Ret_ann  dataset by permno and year*/
proc sort data = Ret_ann;
by permno year;
run;



/*merge All and Ports1 dataset by permno and year; delete missing returns and port  */
data all;
merge Ret_ann ports1;
by permno year;
if ret = . or port = . then delete;
run;

/*iii-	Combine the monthly returns of securities in each decile
to form the monthly returns of each portfolio 1 through 10, 
with 1 corresponding to the lowest decile and 10 to the highest. */


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


data P10; /*large sized porftolio, monthly returns*/
set results;
if port=10;
ret_p10=ret_port;
keep year month ret_p10;
run;
 


/*sort portfolio 1 dataset by year*/
proc sort data = p1 ;
by year month;
run;

/*sort portfolio 10 dataset by year*/
proc sort data = p10;
by year month;
run;



/*merge portfolio 1 and portfolio 10 datasets by year and calculate difference in returns*/
data p1p10;
merge p1 p10;
by year month;
diff=ret_p1 - ret_p10 ;
run;

/*test if the difference between returns in portfolio 1 and portfolio 10 is statistically different than zero. */
proc ttest data = p1p10 h0=0;
var diff;
run;



