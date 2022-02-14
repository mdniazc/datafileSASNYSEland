

/*BADM class SAS notes*/
/* type your code in editor, to run your code: select the code and hit Running man at the top.*/
/*you can comment using  */
/*SAS does not execute the comments. */
/*WORK is a temporary library, everything in it will be deleted once you end your SAS session. So, you should save your data in a 
permanant library you created with libname command. 
Also save your sas code in your flash drive so you can reach it later.*/

/*Creating a library (BADM) in the folder located in " ... " */

libname BADM "\\tsclient\F\BADM742SAS" ;
run;


data A1 ;
set BADM.CRSP ;
if permno = 10001; 
year=year(date); 
month=month(date);
day=day(date);
weekday=weekday(date);
run ; 





Libname BADM "\\tsclient\D\BADM742SAS"; /* each command ends with a semi colon ; */
run; /* we put a run; end of each step we want to run. */






/*create a data set A_data from the orginal data set (CRSP) locate in BADM library. */
data A_data;
set  BADM.CRSP;
if permno =10051; /*conditional statement. Selects observations belongs to permno 10051. */
run; 


data A_data;
set BADM.CRSP;
year=year(date); /*exctracts year from date, */
month=month(date);/*exctracts month from date, */
week=weekday(date);/*exctracts weekday from date, */
day=day(date);      /*exctracts day from date, */


if year = 2018; /*only year 2018 is kept */
run;


data A_data;
set A_data;
run;

proc contents data =A_data; 
run; 

Proc print data= a_data (firstobs=10 obs=25); /*print the observations from 10 to 25 */
run;

proc print data =a_data (firstobs=10 obs=20);
var cusip comnam ret; /*print only these variables*/
run;

data b; /*new dataset created*/
set a; /*original datasey*/
keep cusip year month prc ret vol; /*keep only these variables.*/
run; 


/*Exercise use data CRSP and generate a new dataset
that contains following variables for year 2015: Cusip year month date ret vol shrout*/

data c;
set BADM.CRSP;
year= year(date);
month=month(date);
if year = 2015;
keep Cusip year month date ret vol shrout;
run;


proc means data = c; /*calculate descriptive statistics of specified varaible*/
var ret; /*list of variables */
run; 
 
proc means data = c n mean median std min p1 p5 p25 p50 p75 p95 p99 max ; /* detailed descriptive statistics*/
var ret;
run;

/*name the output variables*/

proc means data =c noprint;
var ret;
output out =cc 
n=nob
mean=ret_avg
median=red_med
min=ret_min
max=ret_max
std=ret_std
p99=ret_p99;
run;


data d;
set c;
month=month(date);
run;

proc sort data = d;
by month;
run;

proc means data = d noprint;
var ret;
by month;
output out=dd
n=nob 
mean=ret_avg
median=ret_md 
min=ret_min
max=ret_max
std=ret_std
p99=ret_p99;
run;
