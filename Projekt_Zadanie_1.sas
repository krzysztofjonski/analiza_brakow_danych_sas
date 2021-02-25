/* Analiza braków danych, ich udzia³ów w czasie (czyli stabilnoœci w czasie) i porównywania */
/* udzia³ów pomiêdzy zbiorami train i valid (czyli stabilnoœci na zbiorach) w postaci */
/* szczegó³owego raportu tabelarycznego. */

/*Tworzenie biblioteki projekt*/
libname	projekt 'C:\Users\Acer\Desktop\SGH dokumenty\projekt_sas';

/*Zbiór train*/
data work.train;
set projekt.abt_sam_beh_train;
run;

/*Zbiór valid*/
data work.valid;
set projekt.abt_sam_beh_valid;
run;

/*Opis zmiennych*/
proc contents data=work.train out=opis_zmiennych_train noprint;	
run;

/*Zmienne numeryczne*/
proc sql noprint;
create table opis_zmiennych_train_num as
select distinct name
from opis_zmiennych_train
where type = 1
order by varnum;
quit;

/*Test dla pierwszych 20tych zmiennych*/
/*data opis_zmiennych_train_num;
set opis_zmiennych_train_num;
if _N_ < 21 then output;
run;*/

/*Zmienne*/
%let zmienna = act_state_1_CMax_Days;
%let zmienne_czas = period;

/* N i NMiss w danym okresie*/
proc univariate data=work.train noprint;
by &zmienne_czas.;
var &zmienna.;
output out=zmienna_analiza n=N nmiss=NMiss;
run;

/*Przedstawienie procentowe braków*/
data zmienna_analiza;
set zmienna_analiza;
Total = NMiss+N;
PMissing = NMiss / Total;
format PMissing PERCENT8.2;
run;

/*Tabela przedstawiaj¹ca procentow¹ iloœæ braków danych w danej zmiennej*/
proc sql noprint;
create table zmienna_analiza2 as
select &zmienne_czas., PMissing as &zmienna.
from zmienna_analiza
order by &zmienne_czas.;
quit;
/*Zmienne znakowe, sprawdzenie ich braków danych */
/* ************************************************** */

/*proc sql noprint;*/
/*create table opis_zmiennych_train_char as*/
/*select distinct name*/
/*from opis_zmiennych_train*/
/*where type = 2*/
/*order by varnum; */
/*quit;*/

/*data zmienne_char;*/
/*set work.train;*/
/*keep period	*/
/*app_char_job_code	*/
/*app_char_marital_status	*/
/*app_char_city	 */
/*app_char_home_status*/
/*app_char_cars;*/
/*run;*/

/* data zmienne_char; */
/* set work.valid; */
/* keep period	 */
/* app_char_job_code	 */
/* app_char_marital_status	 */
/* app_char_city	 */
/* app_char_home_status	 */
/* app_char_cars; */
/* run; */

/*data zmienne_char_missing1 (drop = i);*/
/*set zmienne_char;*/
/*array oldvar (6) period--app_char_cars;*/
/*do i = 1 to 6;*/
/*if oldvar(i) = 'missing' then oldvar(i) = ' ';*/
/*end;*/
/*run;*/

proc format;
 value $missing_char
              ' ' = 'Missing'
              other = 'Present'
              ;
run;

title 'Missing_char_train'; 
proc freq data = work.train;
tables _character_/missing nocum;
format _character_ $missing_char. ;
run; 

title 'Missing_char_valid'; 
proc freq data = work.valid;
tables _character_/missing nocum;
format _character_ $missing_char. ;
run; 


/* ************************************************** */

/*Okresy*/
proc sql noprint;
create table zmienna_czas as
select distinct &zmienne_czas.
from work.train
order by &zmienne_czas.;
quit;

/*Makro do wypisywania braków danych w % dla wszystkich zmiennych numerycznych w zbiorze*/
%macro OcenaZmiennych();

data opis_zm_train_num_rap;
length nr 8.;
set opis_zmiennych_train_num;
nr = _N_; /*nr wiersza*/
call symputx('max_nr', nr);
run;

%let zmienne_czas = period;

%do nr=1 %to %eval(&max_nr.);

data _null_;
set opis_zm_train_num_rap;
call symputx('zmienna', name);
where nr = &nr.;
run;

%put ~~~~ &nr. ~~ NAME: &zmienna. ~~~~;

/* ************* */

proc univariate data=work.train noprint;
by &zmienne_czas.;
var &zmienna.;
output out=analiza_train n=N nmiss=NMiss;
run;

data analiza_train;
set analiza_train;
PMissing = NMiss / (NMiss+N);
format PMissing PERCENT8.2;
run;

proc sql noprint;
create table analiza_train_kol as
select &zmienne_czas., PMissing as TRAIN_&zmienna.
from analiza_train
order by &zmienne_czas.;
quit;

/* ************* */

proc univariate data=work.valid noprint;
by &zmienne_czas.;
var &zmienna.;
output out=analiza_valid n=N nmiss=NMiss;
run;

data analiza_valid;
set analiza_valid;
PMissing = NMiss / (NMiss+N);
format PMissing PERCENT8.2;
run;

proc sql noprint;
create table analiza_valid_kol as
select &zmienne_czas., PMissing as VALID_&zmienna.
from analiza_valid
order by &zmienne_czas.;
quit;

/* ************* */

data analiza_train;
merge zmienna_czas(in=a) analiza_train_kol;
by &zmienne_czas.;
if a;
run;

data analiza_valid;
merge analiza_train(in=a) analiza_valid_kol;
by &zmienne_czas.;
if a;
run;

proc sort data=analiza_valid out=zmienna_czas;
by &zmienne_czas.;
run;

/* ************* */

%end;

%mend OcenaZmiennych;

%OcenaZmiennych();

data zmienne;
set zmienna_czas;
drop &zmienne_czas.;
run;

proc means data=zmienne noprint;
var _all_;
output out=analiza_means;
run;

/*Maksymalny brak danych w zmiennej*/
proc means data=zmienne noprint;
var _all_;
output out=analiza_max (drop=_type_ _freq_) max()=;
run;

data analiza_max;
length &zmienne_czas. $12;
set analiza_max;
&zmienne_czas. = 'Max';
run;

/*Ostateczny wynik, przedstawienie procentowe braków danych w danych okresie, dodatkowo rekord Max
pokazuj¹cy maksymalny brak danych w zmiennej, porownanie obu zbiorów*/
data zmienna_czas_max;
set analiza_max zmienna_czas;
run;

/*proc print data = zmienna_czas_max;*/
/*title "Braki w zmiennych po czasie";*/
/*footnote1 "Created %sysfunc(today(),weekdate.)";*/
/*run;*/

/*Export do excela*/
proc export data=zmienna_czas_max dbms=xlsx outfile='C:\Users\Acer\Desktop\SGH dokumenty\projekt_sas\raport_braki.xlsx' replace;
run;