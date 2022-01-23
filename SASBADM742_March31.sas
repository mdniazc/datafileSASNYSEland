
/*March 31, Regression analysis, dummy variable creation. */

/*How to run regressions and save betas, R2s, residuals and predicted (fitted) values*/
libname badm "D:\TeachingSpring2020\BADM742SAS";
run;


data BADM.NYSE_5y;
set BADM.CRSP ;
If SHRCD = 10 or Shrcd = 11;
If Exchcd = 1 or Exchcd = 2;
year= year(date);
if 2009<year<2016;
run;


data test ;
set badm.nyse_5y;
if permno =10001 or permno =10028;
run;
 
proc sort data =test;
by permno year;
run;

ods graphics off;
proc reg data = test OUTEST=betass SSE  RSQUARE  noprint  ; /** In SAS: R2 = 1 - (SSE/SST) https://v8doc.sas.com/sashtml/stat/chap55/sect37.htm https://v8doc.sas.com/sashtml/stat/chap55/sect27.htm   http://support.sas.com/documentation/cdl/en/etsug/66100/HTML/default/viewer.htm#etsug_panel_details56.htm **/
by permno year;
model ret = SPRTRN;

output out=Ress
       r=retres p=yhat; /*http://web.stanford.edu/class/pp105/OUTPUTstatement.pdf */
run;


/*Let's create a portfolio of two stocks (1001, 10028) and see how their returns are chaging over 12 months*/



data CRSP;
set BADM.CRSP ;
If SHRCD = 10 or Shrcd = 11;
If Exchcd = 1 or Exchcd = 2;
year= year(date);
if 1996<year<2018;
run;


data TwoSPort ;
set CRSP;
if permno =10001 or permno =10028;
year= year(date);
month=month(date);
port=1; /*there is only one portfolio, so I am giving a number (1) */
run;

/*When discussing TwoSPort in the video, 
I said each month has two stocks. However, some months have only one security. It won't be a problem in large samples.
So, it is not an important issue. */
 


proc sort data =TwoSPort;
by port  year month ;
run;

/*calculate Monthly porftolio returns, portfolio is equally weighted.*/


proc means data = TwoSPort noprint;
var ret ;
by port year month   ;
output out=Port_2   mean=ret_port; /*monthly return of equally weighted portfolio of two stocks.*/
run;

/*Creating dummy variables for months*/

Data port_2;
set port_2;
if month =1 then D01=1 ; else D01=0 ; /*dummy variable for January*/
if month =2 then D02=1 ; else D02=0 ; /*dummy variable for feb*/
if month =3 then D03=1 ; else D03=0 ; /*dummy variable for mar*/
if month =4 then D04=1 ; else D04=0 ; /*dummy variable for Apr*/
if month =5 then D05=1 ; else D05=0 ; /*dummy variable for May*/
if month =6 then D06=1 ; else D06=0 ; /*dummy variable for Jun*/
if month =7 then D07=1 ; else D07=0 ; /*dummy variable for Jul*/
if month =8 then D08=1 ; else D08=0 ; /*dummy variable for Aug*/
if month =9 then D09=1 ; else D09=0 ; /*dummy variable for Sep*/
if month =10 then D10=1 ; else D10=0 ; /*dummy variable for Oct*/
if month =11 then D11=1 ; else D11=0 ; /*dummy variable for Nov*/
if month =12 then D12=1 ; else D12=0 ; /*dummy variable for Dec*/
run; 

Proc sort data=  port_2;
by port year month;
run;



ods graphics on;

proc reg data = port_2;    
by port ;
model ret_port = D02 D03 D04 D05 D06 D07 D08 D09 D10 D11 D12 ;
run;


/*Lets use the portfolio returns data from Homework 1 */

/*Creating dummy variables for months*/


/*Calculate means of monthly returns of ten portfolios over the study period. */
proc sort data = results ; /*From HW1*/
by port year month;
run; 

Data port_2;
set Results; /*From HW1*/
if month =1 then D01=1 ; else D01=0 ; /*dummy variable for January*/
if month =2 then D02=1 ; else D02=0 ; /*dummy variable for feb*/
if month =3 then D03=1 ; else D03=0 ; /*dummy variable for mar*/
if month =4 then D04=1 ; else D04=0 ; /*dummy variable for Apr*/
if month =5 then D05=1 ; else D05=0 ; /*dummy variable for May*/
if month =6 then D06=1 ; else D06=0 ; /*dummy variable for Jun*/
if month =7 then D07=1 ; else D07=0 ; /*dummy variable for Jul*/
if month =8 then D08=1 ; else D08=0 ; /*dummy variable for Aug*/
if month =9 then D09=1 ; else D09=0 ; /*dummy variable for Sep*/
if month =10 then D10=1 ; else D10=0 ; /*dummy variable for Oct*/
if month =11 then D11=1 ; else D11=0 ; /*dummy variable for Nov*/
if month =12 then D12=1 ; else D12=0 ; /*dummy variable for Dec*/
run; 

Proc sort data=  port_2;
by port year month;
run;



ods graphics on;

proc reg data = port_2;    
by port ;
model ret_port = D02 D03 D04 D05 D06 D07 D08 D09 D10 D11 D12 ;
run;
