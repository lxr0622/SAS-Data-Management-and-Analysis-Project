/* libname project 'C:\Users\Xiruo Li\Desktop\STAT440\project'; */


/*Input datasets for 5 cities*/
data Beijing;
	infile '/home/yuanl20/sasuser.v94/BeijingPM20100101_20151231.csv' dlm=',' firstobs=2;
	input Number Year Month Day Hour Season PM DEWP HUMI PRES TEMP cbwd :$4. lws precipitation lprec;
	City = 'Beijing';
run;

data Chengdu;
	infile '/home/yuanl20/sasuser.v94/ChengduPM20100101_20151231.csv' dlm=',' firstobs=2;
	input Number Year Month Day Hour Season PM DEWP HUMI PRES TEMP cbwd :$4. lws precipitation lprec;
	City = 'Chengdu';
run;

data Guangzhou;
	infile '/home/yuanl20/sasuser.v94/GuangzhouPM20100101_20151231.csv' dlm=',' firstobs=2;
	input Number Year Month Day Hour Season PM DEWP HUMI PRES TEMP cbwd :$4. lws precipitation lprec;
	City = 'Guangzhou';
run;

data Shanghai;
	infile '/home/yuanl20/sasuser.v94/ShanghaiPM20100101_20151231.csv' dlm=',' firstobs=2;
	input Number Year Month Day Hour Season PM DEWP HUMI PRES TEMP cbwd :$4. lws precipitation lprec;
	City = 'Shanghai';
run;

data Shenyang;
	infile '/home/yuanl20/sasuser.v94/ShenyangPM20100101_20151231.csv' dlm=',' firstobs=2;
	input Number Year Month Day Hour Season PM DEWP HUMI PRES TEMP cbwd :$4. lws precipitation lprec;
	City = 'Shenyang';
run;

/*Concatenate 5 datasets*/
data originaldata_prep; 
	length City $20;
	set Beijing Chengdu Guangzhou Shanghai Shenyang; 
run;

/*Check missing value*/
proc means data=originaldata_prep nmiss;
run;

/* 1. Variables 'precipitation' and 'lprec' has lots of missing values -> Drop these two variables
 * 2. There is one observation has no season -> Use proc print to see which one it is 
   3. There are some missing values in essential variables -> Drop observations that has critical missing values*/

proc print data=originaldata_prep;
	where Season is missing;
run;
/*Guangzhou, 2015/12/31 is the one that has no season, and it should be winter -> Season = 4*/

/*Check the levels of cbwd*/
proc freq data=originaldata_prep;
	table cbwd /nopercent nocum;
run;
/*All levels are correct, but NA should be missing*/

/*Data cleaning*/
data originaldata_1 (drop=precipitation lprec);
	set originaldata_prep;
	where PM is not missing and DEWP is not missing and HUMI is not missing and PRES is not missing and TEMP is not missing and cbwd is not missing and lws is not missing;
	if Number = 52584 then Season = 4;
	if cbwd = 'NA' then cbwd = ' ';
	if cbwd = 'cv' then cbwd = 'CV';
run;

/*Check data: HUMI should not less than 0*/
proc print data=originaldata_1;
	where HUMI < 0;
run;
/*There are 4 observations that has HUMI less than 0*/

/*Second data cleaning*/
data originaldata;
	set originaldata_1;
	where HUMI >= 0;
run;

/*Data validation*/
proc print data=originaldata;
	where cbwd = 'NA' or cbwd = 'cv' or HUMI < 0;
run;	

proc means data=originaldata nmiss;
run;

/* 1.Use the average of variables in a day to represent one day's data;
 * 2.Combine Year, Month and Day to Date;
 * 3.Drop useless variables and intermeidate variables;
 * 4.Label and Format*/

/*Sort data */
proc sort data=originaldata out=data_sort;
	by City Year Month Day;
run;

proc format;
	value Seasonfmt 1 = 'Spring'
	                2 = 'Summer'
	                3 = 'Autumn'
	                4 = 'Winter';
run;

data data_time (keep= City Season date_new DAY_PM DAY_DEWP DAY_TEMP DAY_HUMI DAY_PRES DAY_lws DAY_cbwd);
	set data_sort;
	by City Year Month Day;
 	date_new=mdy(Month, Day, Year);
	if First.Day then do;
		SUM_PM=0;
		SUM_DEWP=0;
		SUM_TEMP=0;
		SUM_HUMI=0;
		SUM_PRES=0;
		SUM_lws=0;
		i=0;
	end;
	SUM_PM+PM;
	SUM_DEWP+DEWP;
	SUM_TEMP+TEMP;
	SUM_HUMI+HUMI;
	SUM_PRES+PRES;
	SUM_lws+lws;
	i+1;
	if Last.Day then do
		DAY_PM=SUM_PM/i;
		DAY_DEWP=SUM_DEWP/i;
		DAY_TEMP=SUM_TEMP/i;
		DAY_HUMI=SUM_HUMI/i;
		DAY_PRES=SUM_PRES/i;
		DAY_lws=SUM_lws/i;
		DAY_cbwd=cbwd;
		output data_time;
	end;
  	format date_new mmddyy10.
  		   DAY_PM DAY_DEWP DAY_TEMP DAY_HUMI DAY_PRES DAY_lws 10.2
  		   Season seasonfmt.;
    label date_new = 'Date'
    	  DAY_PM = 'PM 2.5'
          DAY_DEWP = 'Dew Point (deg)'
          DAY_TEMP = 'Temperature (deg)'
          DAY_HUMI = 'Humidity (%)'
          DAY_PRES = 'Pressure (hPa)'
          DAY_lws = 'Cumulated wind speed (m/s)'
          DAY_cbwd = 'Combined wind direction';
run;

/*Print the first 10 observations of the final dataset*/
proc print data=data_time (obs=10) label noobs;
run;

proc contents data=data_time;
run;

/*See the distribution of variables for grading*/
proc univariate data=data_time normal; 
    var DAY_PM DAY_DEWP DAY_TEMP DAY_HUMI DAY_PRES DAY_lws;
	histogram DAY_PM DAY_DEWP DAY_TEMP DAY_HUMI DAY_PRES DAY_lws;
run; 

/* divide levels for PM */
data data_divide1;
	set data_time;
	if DAY_PM<=34.8 then Level_PM=1;
	else if 34.8<DAY_PM<=57 then Level_PM=2;
	else if 57<DAY_PM<=92.7 then Level_PM=3;
	else if 92.7<DAY_PM then Level_PM=4;
run;

/* divide levels for DEWP */
data data_divide2;
	set data_divide1;
	if DAY_DEWP<=0.71 then Level_DEWP=1;
	else if 0.71<DAY_DEWP<=11.64 then Level_DEWP=2;
	else if 11.64<DAY_DEWP<=19 then Level_DEWP=3;
	else if 19<DAY_DEWP<=27 then Level_DEWP=4;
run;

/* divide levels for TEMP */
data data_divide3;
	set data_divide2;
	if DAY_TEMP<=8.89 then Level_TEMP=1;
	else if 8.89<DAY_TEMP<=18.46 then Level_TEMP=2;
	else if 18.46<DAY_TEMP<=24.63 then Level_TEMP=3;
else if 24.63<DAY_TEMP then Level_TEMP=4;
run;

/* divide levels for HUMI */
data data_divide4;
	set data_divide3;
	if DAY_HUMI<=55.42 then Level_HUMI=1;
	else if 55.42<DAY_HUMI<=69.64 then Level_HUMI=2;
	else if 69.64<DAY_HUMI<=79.43 then Level_HUMI=3;
	else if 79.43<DAY_HUMI then Level_HUMI=4;
run;

/* divide levels for PRES */
data data_divide5;
	set data_divide4;
	if DAY_PRES<=1006 then Level_PRES=1;
	else if 1006<DAY_PRES<=1013 then Level_PRES=2;
	else if 1013<DAY_PRES<=1021.125 then Level_PRES=3;
	else if 1021.125<DAY_PRES then Level_PRES=4;
run;

/* divide levels for Lws */
data data_divide6;
	set data_divide5;
	if DAY_lws<=4.32 then Level_lws=1;
	else if 4.32<DAY_lws<=8.94 then Level_lws=2;
	else if 8.94<DAY_lws<=21.08 then Level_lws=3;
	else if 21.08<DAY_lws then Level_lws=4;
run;

/*Tables*/
proc tabulate data = data_divide6;
			  class City DAY_cbwd Level_PM;
			  table City, DAY_cbwd,Level_PM*(n rowpctn);
run;
			  
proc tabulate data = data_divide6;
			  class City Level_DEWP Level_PM;
			  table City,Level_DEWP,Level_PM*(n rowpctn);
run;
	
proc tabulate data = data_divide6;
			  class City Level_TEMP Level_PM;
			  table City,Level_TEMP,Level_PM*(n rowpctn);
run;
		
proc tabulate data = data_divide6;
			  class City Level_HUMI Level_PM;
			  table City,Level_HUMI,Level_PM*(n rowpctn);
run;
			  
proc tabulate data = data_divide6;
			  class City Level_PRES Level_PM;
			  table City,Level_PRES,Level_PM*(n rowpctn);
run;
			  
proc tabulate data = data_divide6;
			  class City Level_lws Level_PM;
			  table City,Level_lws,Level_PM*(n rowpctn);
run;