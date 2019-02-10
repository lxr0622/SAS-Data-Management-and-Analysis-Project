libname Project "/home/xiruoli20/Project";

/* import data and cleaning */
proc import
	datafile='/home/xiruoli20/Project/ufosightingsdata.csv'
	dbms=csv
	out=Project.UFO;
	datarow=2;
	getnames=no;
run;

data Project.UFO1(rename=(var1=datetime var2=city var3=state var4=country var5=shape var6=duration var7=latitude var8=longitude));
	set Project.UFO;
	where var4 is not missing and var5 is not missing and var6 is not missing and var7 is not missing and var8 is not missing;
	/*drop the outlier of duration time*/
	where var6<=259200 ; 
run;

proc contents data=project.ufo1;
run;

proc print data=project.ufo1 (obs=10);
run;

/* latitude and longitude distribution */
proc univariate data=Project.UFO1 normal; 
    var latitude longitude;
	histogram latitude longitude;
run; 

/* convert latitude and longitude into categorical variable */
data Project.UFO2;
	set Project.UFO1;
	if latitude<=42.0083 then latitude_level=1;
	else if 42.0083<latitude<=46.3000 then latitude_level=2;
	else if 46.3000<latitude<=51.8333 then latitude_level=3;
	else if 51.8333<latitude then latitude_level=4;
	
	if longitude<=-95.708056 then longitude_level=1;
	else if -95.708056<longitude<=-78.878611 then longitude_level=2;
	else if -78.878611<longitude<=-2.666667 then longitude_level=3;
	else if -2.666667<longitude then longitude_level=4;
run;


/* shape and country frequency */
proc freq data=project.ufo2 order=freq;
	tables country shape;
run;

/* cross tabulation */
proc tabulate data=Project.UFO2;
class country shape latitude_level longitude_level;
var duration;
table country*shape*latitude_level*longitude_level, duration*(mean std n);
run;

/* original model */
proc glm data=Project.UFO2;
class country shape latitude_level longitude_level;
model duration =country shape latitude_level longitude_level;
ods select OverallANOVA FitStatistics ModelANOVA;
run;

/* final model and multiple comparison */
proc glm data=Project.UFO2;
class longitude_level;
model duration = longitude_level;
lsmeans longitude_level / adjust=Tukey cl;
ods select ModelANOVA OverallANOVA FitStatistics LSMeans LSMeanDiffCL;
run;
