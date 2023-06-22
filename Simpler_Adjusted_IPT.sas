**********************************************************************************
This file calculates an alternate and simpler adjusted IPT, following
Blankespoor, deHaan, and Zhu (2018).
Assumption is that the daily return accumulation is immediately at the open.

This file also outputs an alternate standard IPT measure, without the adjustment, 
that also assumes the return accumulation is immediately at the open.

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
	alt_std_ipt_0_max is the alternate standard IPT in the time period specified 
		(i.e., output variable name is alt_std_ipt_0_10 if max=10, alt_std_ipt_0_5 if max=5)
	ipt_0_max (i.e., output variable name is ipt_0_10 if max=10, ipt_0_5 if max=5)
		is the alternate adjusted IPT
**********************************************************************************
Example implementation:
	%iptcalc(returns, ipt, AR, 10);
	* Takes a dataset called returns and outputs a dataset called ipt, with the 
	IPT variables called ipt. The abnormal returns variable in the input dataset
	has prefix 'AR' and the calculated standard and adjusted IPT are for days [0, 10]
**********************************************************************************;

%macro alt_iptcalc(_dsetin, _dsetout, AR, max);

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

* 2. Calculate IPT;

data ipt_prep;
set ipt_prep;
* prep to calculate total alternate std_ipt and total alternate adjusted IPT;
%do day = 0 %to &max.;
	stdipt_&day.=&AR._&day./&AR._max;
	adjipt_&day.=1-(abs((&AR._max - &AR._&day.)/&AR._max));
%end;
run;

data &_dsetout;
set ipt_prep;
* standard IPT is the sum of each day;
retain stdipt_: adjipt_:;
alt_std_ipt_0_&max.=sum(of stdipt_0-stdipt_&max.);
alt_ipt_0_&max.=sum(of adjipt_0-adjipt_&max.);
run;

%mend alt_iptcalc;
