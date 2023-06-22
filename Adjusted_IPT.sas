**********************************************************************************
This file calculates complex adjusted IPT, following Blankespoor, deHaan, and Zhu (2018).
Assumption of even return accumulation over a given day

This file also outputs a standard IPT measure, without the adjustment, 
that also assumes even return accumulation over a given day.

Contact: Christina Zhu, chrzhu@wharton.upenn.edu
Last updated: 6/22/23
**********************************************************************************
Input variables:
	_dsetin is your input dataset that has abnormal returns for each firm-date you
		are interested in
	_dsetout is your output dataset, which will contain all of the variables in
		_dsetin, in addition to two Output variables
	AR is the name of the prefix for the variables specifying cumulative abnormal returns
		e.g, &AR._0 to &AR._5 (or &AR._10 or &AR._75 or any number) are the cumulative
		buy-and-hold abnormal returns realized up to and including a given day,
		including day 0
	max is the end day of the calculation period, relative to day 0 of the event
		(e.g. max=10 if you want to calculate 10-day IPT)
**********************************************************************************
Output variables:
	std_ipt_0_max is the standard IPT in the time period specified 
		(i.e., output variable name is std_ipt_0_10 if max=10, std_ipt_0_5 if max=5)
	ipt_0_max (i.e., output variable name is ipt_0_10 if max=10, ipt_0_5 if max=5)
		is adjusted IPT
**********************************************************************************
Example implementation:
	%iptcalc(returns, ipt, AR, 10);
	* Takes a dataset called returns and outputs a dataset called ipt, with the 
	IPT variables called ipt. The abnormal returns variable in the input dataset
	has prefix 'AR' and the calculated standard and adjusted IPT are for days [0, 10]
**********************************************************************************;

%macro iptcalc(_dsetin, _dsetout, AR, max);

%let maxminusone=%eval(&max.-1);

* 1. create &AR._max variable that is the cumulative abnormal return of the max period (i.e., 10 day abnormal return if interested in IPT_0_10);
* This is because day 10 (or 9, or 8, ...) abnormal returns might be missing (e.g., firm is delisted day 10, day 9, etc.);

data ipt_prep;
set &_dsetin;
&AR._max=&AR._&max.;
%do day = &maxminusone. %to 1 %by -1;
	if &AR._max='' then &AR._max=&AR._&day.;
%end;
run;

* 2. Calculate IPT when the final abnormal cumulative return is positive (positive &AR._max);

data ipt_pos;
set ipt_prep;
if &AR._max>=0;
* prep to calculate total std_ipt;
%do day = 0 %to &max.;
	stdipt_&day.=&AR._&day./&AR._max;
%end;
* prep to calculate overreaction amount on each day;
b=0;
if &AR._0>0 then b=1-abs(&AR._max/&AR._0);
if 0>&AR._0 then b=abs(&AR._max/&AR._0);
over_0=0;
if (&AR._0>&AR._max and &AR._0^='') then over_0=abs(((max(&AR._0,0)-&AR._max)*b)/(2*&AR._max));
run;

data ipt_pos;
set ipt_pos;
* standard IPT is the sum of each day;
retain stdipt_:;
std_ipt=sum(sum(of stdipt_0-stdipt_&maxminusone.), stdipt_&max./2);
* calculate overreaction on each day;
%do day = 1 %to &maxminusone.;
%let dayminusone=%eval(&day.-1);
b=0;
if &AR._&day.>&AR._&dayminusone. then b=1-abs((&AR._max-&AR._&dayminusone.)/(&AR._&day.-&AR._&dayminusone.));
if &AR._&dayminusone.>&AR._&day. then b=abs((&AR._max-&AR._&dayminusone.)/(&AR._&day.-&AR._&dayminusone.));
over_&day.=0;
if ((&AR._&dayminusone.>&AR._max or &AR._&day.>&AR._max) and &AR._&day.^='') then over_&day.=abs(((max(&AR._&day.,&AR._&dayminusone.)-&AR._max)*b)/(2*&AR._max));
if (&AR._&dayminusone.>&AR._max and &AR._&day.>&AR._max) then over_&day.=(&AR._&dayminusone.+&AR._&day.-2*&AR._max)/(2*&AR._max);
%end;
run;

data ipt_pos;
set ipt_pos;
* calculate overreaction on the last day;
over_&max.=0;
retain over_:;
if &AR._&maxminusone.>&AR._max then over_&max.=(&AR._&maxminusone.-&AR._max)/(2*&AR._max);
* adjusted IPT is standard IPT minus 2 times the amount of overreaction;
* assumes overreaction is the same as underreaction when calculating timeliness of reaction;
ipt_0_&max.=std_ipt-2*sum(of over_0-over_&max.);
drop b over_: stdipt_:;
run;

* 2. Calculate IPT when the final abnormal cumulative return is negative (negative &AR._max);

data ipt_neg;
set ipt_prep;
if &AR._max<0;
* prep to calculate total std_ipt;
%do day = 0 %to &max.;
	stdipt_&day.=&AR._&day./&AR._max;
%end;
* prep to calculate overreaction amount on each day;
b=0;
if &AR._0<0 then b=1-abs(&AR._max/&AR._0);
if 0<&AR._0 then b=abs(&AR._max/&AR._0);
over_0=0;
if (&AR._0<&AR._max and &AR._0^='') then over_0=abs(((min(&AR._0,0)-&AR._max)*b)/(2*&AR._max));
run;

data ipt_neg;
set ipt_neg;
* standard IPT is the sum of each day;
retain stdipt_:;
std_ipt_0_&max.=sum(sum(of stdipt_0-stdipt_&maxminusone.), stdipt_&max./2);
* calculate overreaction on each day;
%do day = 1 %to &maxminusone.;
%let dayminusone=%eval(&day.-1);
b=0;
if &AR._&day.<&AR._&dayminusone. then b=1-abs((&AR._max-&AR._&dayminusone.)/(&AR._&day.-&AR._&dayminusone.));
if &AR._&dayminusone.<&AR._&day. then b=abs((&AR._max-&AR._&dayminusone.)/(&AR._&day.-&AR._&dayminusone.));
over_&day.=0;
if ((&AR._&dayminusone.<&AR._max or &AR._&day.<&AR._max) and &AR._&day.^='') then over_&day.=abs(((min(&AR._&day.,&AR._&dayminusone.)-&AR._max)*b)/(2*&AR._max));
if (&AR._&dayminusone.<&AR._max and &AR._&day.<&AR._max) then over_&day.=(&AR._&dayminusone.+&AR._&day.-2*&AR._max)/(2*&AR._max);
%end;
run;

data ipt_neg;
set ipt_neg;
* calculate overreaction on the last day;
over_&max.=0;
retain over_:;
if &AR._&maxminusone.<&AR._max then over_&max.=(&AR._&maxminusone.-&AR._max)/(2*&AR._max);
* adjusted IPT is standard IPT minus 2 times the amount of overreaction;
* assumes overreaction is the same as underreaction when calculating timeliness of reaction;
ipt_0_&max.=std_ipt-2*sum(of over_0-over_&max.);
drop b over_: stdipt:;
run;

* 3. Combine the positive and negative datasets to create the output dataset;

data &_dsetout;
set ipt_neg ipt_pos;
run;

%mend iptcalc;
