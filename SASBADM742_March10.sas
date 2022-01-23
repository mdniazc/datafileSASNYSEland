
 /*simulate a dataset to test sample mean*/

/* Source link: https://www.stat.purdue.edu/~lfindsen/stat350/Lab3SAS.pdf */


%Let points = 24; *this is the number of data points in the sample;
%Let mu = 1.5;
%Let sigma = 3.6;
%Let norm = rand('normal',&mu, &sigma);

data RandomNormal;
 do x=1 to &points; *When I use &points, I don't need to search to change the number of points. The change is now  only done in the beginning of the code;
 ret=&norm;
 output;
 end; 
 run; 

 
 proc means data = RandomNormal;
 run;


proc ttest data = RandomNormal h0=1.10 ;
var  ret;
run;

/*Or simulate the data in Excel and read it in */


/*Read the data in and test the difference in portfolio returns*/
data ex2;
set ex2;
diff=port_a - port_b;
run;


proc ttest data = ex2 h0=0;
var  diff;
run;

/*doing simple algebra*/

data test;
input mean stdv ;
cards ;
3.06 6.62
;
run;
 
data tstat;
set test;
stdev2= stdv/sqrt(50);
t=mean/stdev2;
run; 


/*Example 8-12 running a simple regression*/
/*saving regression outputs in a dataset*/
libname badm "\\tsclient\G\Box Sync\TeachingSpring2020\BADM742SAS";
run; 

 
libname badm "G:\Box Sync\TeachingSpring2020\BADM742SAS";
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




/*Optional */
/*Crash and jump definitions based on residuals*/
/*calculate mean ln(1+residual return) for each month.*/


data b;
set  Ress;
logres=log(1+retres); /*residuals are corrected*/
run; 

/*annual residuals*/
proc sql;
 create table b1 as
 select permno,year,  avg(logres) as lnres  
 from b
 group by permno, year;
 
quit;

/*average annual residuals, stdev of daily residuals*/
proc sql;
 create table b2 as
 select permno, std(lnres) as stdlnres , avg(lnres) as lnresm  
 from b1 
 group by permno;
 quit;

 data b3;
 merge b1 b2;
 by permno;
 run;

data b3;
set b3;
limdw= lnresm - (stdlnres*3.09);
limup=lnresm + (stdlnres*3.09);

if lnres <=limdw then crash =1; else crash = 0; 
if lnres >= limup then jump =1; else jump=0;
run;
