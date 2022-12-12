* This is for Mali DHS-SARA linked multi-level analysis.
* Six outcomes were selected by Gheda Themsa, based on regional-level analysis 
*•	Use of modern contraception
*•	Percent of births in last five years receiving at least 4 ANC visits
*•	Percent of children 12-23 receiving BCG vaccination
*•	Prevalence of moderate-to-severe stunting among children under five
*•	Percent of women 15-49 with a birth in the last 2 years receiving SP/Fansidar 2+ doses, at least one during ANC visit (IPTp)
*•	Percent of children under five with fever who took any ACT
* Code from the GitHub https://github.com/DHSProgram/DHS-Indicators-Stata 

* Data
*	Mali DHS 2018 from the web
*   SARA 2018, estimates from the excel file from Gheda Themsa (she double checked the numbers)
*		This provides regional-level SARA information for each of the outcomes

* Table of Contents
* 	A. SETTING 
* 	B. Run the prep do file, 
* 	C. Analysis: Regional SARA data 
* 	D. Analysis: Descriptive 
* 	E. Analysis - regression 
* 	F. Analysis - regression 

clear
clear matrix
clear mata
capture log close

set more off
set mem 300m
set maxvar 9000
numlabel, add

************************************************************************
* A. SETTING 
************************************************************************

cd "C:\Users\YoonJoung Choi\Dropbox\0 iSquared\iSquared_DHS\Mali_DHS_SARA\"

local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)

/*
************************************************************************
* B. Run the prep do file, 
************************************************************************

do Mali_DHS_SARA_LinkedAnalysis_prep.do 
*/

* This generates two analysis datasets - 
*	- save IR_Mali_2018_LinkedAnalysis.dta, replace 
*	- save KR_Mali_2018_LinkedAnalysis.dta, replace 
* At the end of this do file, you will will see the following error:
*	. Well done! End of do file
*	command Well is unrecognized
*	r(199);

/*
************************************************************************
* C. Analysis: Regional SARA data 
************************************************************************
capture putdocx clear 
putdocx begin
	
putdocx paragraph
putdocx text ("REGIONAL-LEVEL, SARA indicators"), linebreak bold 

use sara.dta, clear

	drop if xregion==.
	gen regioncode=substr(region, 1, 2)
	tab regioncode
			
	foreach var of varlist sara* {
	graph bar `var', over(region) title("`var'")
	graph export graph.png, replace	

putdocx paragraph
putdocx image graph.png				

	}

	***** CHECK CORRELATION 	
	graph matrix sara_fp_* sara_anc_* sara_del_* sara_hiv_*, half mlabel(regioncode)
	graph export graph.png, replace	

putdocx paragraph
putdocx image graph.png				
		
	graph matrix sara_vac_* sara_growth_* sara_dia_*, half mlabel(regioncode)
	graph export graph.png, replace	

putdocx paragraph
putdocx image graph.png				
	
	graph matrix sara_ipt_* sara_act_*, half mlabel(regioncode)
	graph export graph.png, replace	

putdocx paragraph
putdocx image graph.png				

	pwcorr sara_fp_* sara_anc_* sara_del_* sara_hiv_*, sig
	pwcorr sara_vac_* sara_growth_* sara_dia_*, sig
	pwcorr sara_ipt_* sara_act_*, sig

erase graph.png
putdocx save Mali_SARA_EDA_Descriptive_$date.docx, replace

*/

/*
************************************************************************
* D. Analysis: Descriptive 
************************************************************************
global outcomeIR "yfp_cruse_mod yml_two_iptp" 
global outcomeKR "yrh_anc_4vs ystunting ych_bcg_either yml_act"
global covariateIR "xage_5_* xmcurrent xnoschool xprimary xsecondary xpoor xmiddle xrich xrurb"  
global covariateKR "xmale xcage_yr_* xage_5_* xmcurrent xnoschool xprimary xsecondary xpoor xmiddle xrich xrurb"  

/*
use IR_Mali_2018_LinkedAnalysis.dta, clear

	svyset v021, weight(xweight) strata(v023) , singleunit(centered) || _n, weight(xweight2)

		sum $covariateIR 
		
		foreach outcome of varlist $outcomeIR {		
			svy: mean `outcome'
			svy: mean $covariateIR if `outcome'!=.
		}	
	
use KR_Mali_2018_LinkedAnalysis.dta, clear

	svyset v021, weight(xweight) strata(v023) , singleunit(centered) || _n, weight(xweight2)

		sum $covariateKR 
		
		foreach outcome of varlist $outcomeKR {
			svy: mean `outcome'
			svy: mean $covariateKR if `outcome'!=.
		}
*/

putexcel set Mali_DHS_SARA_Linked_EDA_Descriptive_$date.xlsx, sheet("TOC") replace
putexcel A1="Descriptive analysis of the six outcomes and their covariates"

use IR_Mali_2018_LinkedAnalysis.dta, clear

	svyset v021, weight(xweight) strata(v023) , singleunit(centered) || _n, weight(xweight2)

	foreach outcome of varlist $outcomeIR  {		
		sum `outcome'
			
			putexcel set Mali_DHS_SARA_Linked_EDA_Descriptive_$date.xlsx, sheet(`outcome') modify
			putexcel B3 = ("`outcome'")
			putexcel C3 = (r(N))
		
		local row=5
		foreach cov of varlist $covariateIR {		
		sum `cov' if `outcome'!=.
			putexcel set Mali_DHS_SARA_Linked_EDA_Descriptive_$date.xlsx, sheet(`outcome') modify
			putexcel B`row'=("`cov'")
			putexcel C`row'=(r(N))
			local row=`row'+1	
			}
			
		svy: mean `outcome'	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_EDA_Descriptive_$date.xlsx, sheet(`outcome') modify
			putexcel D2 = matrix(results), names nformat(number_d2) right 		

		svy: mean $covariateIR if `outcome'!=.
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_EDA_Descriptive_$date.xlsx, sheet(`outcome') modify
			putexcel D4 = matrix(results), names nformat(number_d2) right 		
			
	}	
	
use KR_Mali_2018_LinkedAnalysis.dta, clear

	svyset v021, weight(xweight) strata(v023) , singleunit(centered) || _n, weight(xweight2)	
	
	foreach outcome of varlist $outcomeKR  {		
		sum `outcome'
			
			putexcel set Mali_DHS_SARA_Linked_EDA_Descriptive_$date.xlsx, sheet(`outcome') modify
			putexcel B3 = ("`outcome'")
			putexcel C3 = (r(N))
		
		local row=5
		foreach cov of varlist $covariateKR {		
		sum `cov' if `outcome'!=.
			putexcel set Mali_DHS_SARA_Linked_EDA_Descriptive_$date.xlsx, sheet(`outcome') modify
			putexcel B`row'=("`cov'")
			putexcel C`row'=(r(N))
			local row=`row'+1	
			}
			
		svy: mean `outcome'	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_EDA_Descriptive_$date.xlsx, sheet(`outcome') modify
			putexcel D2 = matrix(results), names nformat(number_d2) right 		

		svy: mean $covariateKR if `outcome'!=.
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_EDA_Descriptive_$date.xlsx, sheet(`outcome') modify
			putexcel D4 = matrix(results), names nformat(number_d2) right 		
			
	}		
*/	
okokok
************************************************************************
* E. Analysis - regression, EDA 
************************************************************************
global outcomeIR "yfp_cruse_mod yml_two_iptp" 
global outcomeKR "yrh_anc_4vs ystunting ych_bcg_either yml_act"
global covariateIR "xage_5_2-xage_5_7 xmcurrent xprimary xsecondary xpoor xrich xrurb"  
global covariateKR "xmale xcage_yr_2-xcage_yr_5 xage_5_2-xage_5_7 xmcurrent xprimary xsecondary xpoor xrich xrurb"  

putexcel set Mali_DHS_SARA_Linked_EDA_regression_$date.xlsx, sheet("TOC") replace
putexcel A1="Bivariate regression of the six outcomes and their covariates"

use IR_Mali_2018_LinkedAnalysis.dta, clear

	svyset v021, weight(xweight) strata(v023) , singleunit(centered) || _n, weight(xweight2)
	
	foreach outcome of varlist $outcomeIR {

		svy: melogit `outcome' xage_5_2 - xage_5_7 || v001:, or
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_EDA_regression_$date.xlsx, sheet(`outcome') modify
			putexcel D4 = matrix(results), names nformat(number_d2) right 			
		svy: melogit `outcome' xmcurrent || v001:, or
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_EDA_regression_$date.xlsx, sheet(`outcome') modify
			putexcel D13 = matrix(results), names nformat(number_d2) right 			
		svy: melogit `outcome' xprimary xsecondary || v001:, or
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_EDA_regression_$date.xlsx, sheet(`outcome') modify
			putexcel D17 = matrix(results), names nformat(number_d2) right 			
		svy: melogit `outcome' xpoor xrich || v001:, or
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_EDA_regression_$date.xlsx, sheet(`outcome') modify
			putexcel D22 = matrix(results), names nformat(number_d2) right 			
		svy: melogit `outcome' xrurb || v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_EDA_regression_$date.xlsx, sheet(`outcome') modify
			putexcel D27 = matrix(results), names nformat(number_d2) right 			
		svy: melogit `outcome' $covariateIR || v001:, or
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_EDA_regression_$date.xlsx, sheet(`outcome') modify
			putexcel D31 = matrix(results), names nformat(number_d2) right 				
	}

use KR_Mali_2018_LinkedAnalysis.dta, clear

	svyset v021, weight(xweight) strata(v023) , singleunit(centered) || _n, weight(xweight2)
	
	foreach outcome of varlist $outcomeKR {

		svy: melogit `outcome' xmale || v001:, or
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_EDA_regression_$date.xlsx, sheet(`outcome') modify
			putexcel D4 = matrix(results), names nformat(number_d2) right 				
		svy: melogit `outcome' xcage_yr_2 - xcage_yr_5|| v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_EDA_regression_$date.xlsx, sheet(`outcome') modify
			putexcel D8 = matrix(results), names nformat(number_d2) right 				
		svy: melogit `outcome' xage_5_2 - xage_5_7 || v001:, or
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_EDA_regression_$date.xlsx, sheet(`outcome') modify
			putexcel D15 = matrix(results), names nformat(number_d2) right 			
		svy: melogit `outcome' xmcurrent || v001:, or
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_EDA_regression_$date.xlsx, sheet(`outcome') modify
			putexcel D24 = matrix(results), names nformat(number_d2) right 				
		svy: melogit `outcome' xprimary xsecondary || v001:, or
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_EDA_regression_$date.xlsx, sheet(`outcome') modify
			putexcel D28 = matrix(results), names nformat(number_d2) right 				
		svy: melogit `outcome' xpoor xrich || v001:, or
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_EDA_regression_$date.xlsx, sheet(`outcome') modify
			putexcel D33 = matrix(results), names nformat(number_d2) right 				
		svy: melogit `outcome' xrurb || v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_EDA_regression_$date.xlsx, sheet(`outcome') modify
			putexcel D38 = matrix(results), names nformat(number_d2) right 				
		svy: melogit `outcome' $covariateKR || v001:, or
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_EDA_regression_$date.xlsx, sheet(`outcome') modify
			putexcel D42 = matrix(results), names nformat(number_d2) right 				
	}

************************************************************************
* F. Analysis - regression, EDA with SARA
************************************************************************
capture log close
log using Mali_DHS_SARA_Linked_EDA_SARAregression_$date.log

use IR_Mali_2018_LinkedAnalysis.dta, clear

	svyset v021, weight(xweight) strata(v023) , singleunit(centered) || _n, weight(xweight2)

	* yfp_cruse_mod 
		svy: melogit yfp sara_fp_offer || v001:, or	
		svy: melogit yfp sara_fp_staff || v001:, or	
		svy: melogit yfp sara_fp_ready || v001:, or	
		svy: melogit yfp sara_fp_* || v001:, or	
	* yml_two_iptp 
		svy: melogit yml_two_iptp sara_ipt_offer || v001:, or	
		svy: melogit yml_two_iptp sara_ipt_staff || v001:, or	
		svy: melogit yml_two_iptp sara_ipt_drug || v001:, or	
		svy: melogit yml_two_iptp sara_ipt_* || v001:, or	
		
use KR_Mali_2018_LinkedAnalysis.dta, clear

	svyset v021, weight(xweight) strata(v023) , singleunit(centered) || _n, weight(xweight2)

	* yrh_anc_4vs 
		svy: melogit yrh_anc_4vs sara_anc_offer || v001:, or	
		*svy: melogit yrh_anc_4vs sara_anc_staff || v001:, or	
		svy: melogit yrh_anc_4vs sara_anc_ready || v001:, or	
		*svy: melogit yrh_anc_4vs sara_anc_* || v001:, or	
	* ystunting 
		svy: melogit ystunting sara_growth_guideline || v001:, or	
		svy: melogit ystunting sara_growth_staff || v001:, or	
		svy: melogit ystunting sara_growth_chart || v001:, or	 
		svy: melogit ystunting sara_growth_height || v001:, or	 
		svy: melogit ystunting sara_growth_weight || v001:, or	 
		svy: melogit ystunting sara_growth_* || v001:, or	
	* ych_bcg_either 
		svy: melogit ych_bcg_either sara_vac_offer || v001:, or	
		svy: melogit ych_bcg_either sara_vac_staff || v001:, or	 
		svy: melogit ych_bcg_either sara_vac_bcg_stock || v001:, or	 
		svy: melogit ych_bcg_either sara_vac_offer sara_vac_staff sara_vac_bcg_stock || v001:, or	
	* yml_act	
		svy: melogit yml_act sara_act_maldx || v001:, or	 
		svy: melogit yml_act sara_act_drug || v001:, or	 
		svy: melogit yml_act sara_act_* || v001:, or			
		
log close

************************************************************************
* G. Analysis - regression, Multivariate
************************************************************************

global covariateIR "xage_5_2-xage_5_7 xmcurrent xprimary xsecondary xpoor xrich xrurb"  

use IR_Mali_2018_LinkedAnalysis.dta, clear

	svyset v021, weight(xweight) strata(v023) , singleunit(centered) || _n, weight(xweight2)

	* yfp_cruse_mod 
		svy: melogit yfp  || v001:, or		
		svy: melogit yfp  || v001:|| xregion:, or		
			estat icc
		
		svy: melogit yfp sara_fp_ready || v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(cruse_mod)replace
			putexcel A1="Odds of using modern methods among women 15-49 yrs. Random intercept"
			putexcel D2 = "Model 1"
			putexcel B3 = matrix(results), names nformat(number_d2) right 		

		svy: melogit yfp sara_fp_ready density || v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(cruse_mod) modify
			putexcel L2 = "Model 2"
			putexcel J3 = matrix(results), names nformat(number_d2) right 
	
		svy: melogit yfp sara_fp_ready $covariateIR || v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(cruse_mod) modify
			putexcel T2 = "Model 3"
			putexcel R3 = matrix(results), names nformat(number_d2) right 
			
		
		svy: melogit yfp sara_fp_ready density $covariateIR || v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(cruse_mod) modify
			putexcel AB2 = "Model 4"
			putexcel Z3 = matrix(results), names nformat(number_d2) right 

	* yml_two_iptp 
		svy: melogit yml_two_iptp sara_ipt_* || v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(iptp2) modify
			putexcel A1="Odds of receiving IPTp among women 15-49 yrs who had live birth within last two years. Random intercept"
			putexcel D2 = "Model 1"
			putexcel B3 = matrix(results), names nformat(number_d2) right 		
			
		svy: melogit yml_two_iptp sara_ipt_* density || v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(iptp2) modify
			putexcel L2 = "Model 2"
			putexcel J3 = matrix(results), names nformat(number_d2) right 			
		
		svy: melogit yml_two_iptp sara_ipt_* $covariateIR || v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(iptp2) modify
			putexcel T2 = "Model 3"
			putexcel R3 = matrix(results), names nformat(number_d2) right 			
		
		svy: melogit yml_two_iptp sara_ipt_* density $covariateIR || v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(iptp2) modify
			putexcel AB2 = "Model 4"
			putexcel Z3 = matrix(results), names nformat(number_d2) right 			

global covariateKR "xmale xcage_yr_2-xcage_yr_5 xage_5_2-xage_5_7 xmcurrent xprimary xsecondary xpoor xrich xrurb"  
		
use KR_Mali_2018_LinkedAnalysis.dta, clear

	svyset v021, weight(xweight) strata(v023) , singleunit(centered) || _n, weight(xweight2)

	* yrh_anc_4vs 
		svy: melogit yrh_anc_4vs sara_anc_ready || v001:, or
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(anc4) modify
			putexcel A1="Odds of 4+ ANC visits among all births in the last five years. Random intercept"
			putexcel D2 = "Model 1"
			putexcel B3 = matrix(results), names nformat(number_d2) right 			
			
		svy: melogit yrh_anc_4vs sara_anc_ready density || v001:, or
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(anc4) modify
			putexcel L2 = "Model 2"
			putexcel J3 = matrix(results), names nformat(number_d2) right 			
			
		svy: melogit yrh_anc_4vs sara_anc_ready $covariateKR || v001:, or
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(anc4) modify
			putexcel T2 = "Model 3"
			putexcel R3 = matrix(results), names nformat(number_d2) right 					
			
		svy: melogit yrh_anc_4vs sara_anc_ready density $covariateKR || v001:, or
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(anc4) modify
			putexcel AB2 = "Model 4"
			putexcel Z3 = matrix(results), names nformat(number_d2) right 			
		
	* ystunting 
		svy: melogit ystunting sara_growth_* || v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(stunting) modify
			putexcel A1="Odds of stunting among children under-five. Random intercept"
			putexcel D2 = "Model 1"
			putexcel B3 = matrix(results), names nformat(number_d2) right 		
		
		svy: melogit ystunting sara_growth_* density || v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(stunting) modify
			putexcel L2 = "Model 2"
			putexcel J3 = matrix(results), names nformat(number_d2) right 		
		
		svy: melogit ystunting sara_growth_* $covariateKR || v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(stunting) modify
			putexcel T2 = "Model 3"
			putexcel R3 = matrix(results), names nformat(number_d2) right 		
			
		svy: melogit ystunting sara_growth_* density $covariateKR || v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(stunting) modify
			putexcel AB2 = "Model 4"
			putexcel Z3 = matrix(results), names nformat(number_d2) right 		
			
	* ych_bcg_either 
		svy: melogit ych_bcg_either sara_vac_offer sara_vac_staff sara_vac_bcg_stock || v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(bcg) modify
			putexcel A1="Odds of vaccinated for BCG among children 12-23 months old. Random intercept"
			putexcel D2 = "Model 1"
			putexcel B3 = matrix(results), names nformat(number_d2) right 				

		svy: melogit ych_bcg_either sara_vac_offer sara_vac_staff sara_vac_bcg_stock density || v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(bcg) modify
			putexcel L2 = "Model 2"
			putexcel J3 = matrix(results), names nformat(number_d2) right 	
			
		svy: melogit ych_bcg_either sara_vac_offer sara_vac_staff sara_vac_bcg_stock $covariateKR || v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(bcg) modify
			putexcel T2 = "Model 3"
			putexcel R3 = matrix(results), names nformat(number_d2) right 	
			
		svy: melogit ych_bcg_either sara_vac_offer sara_vac_staff sara_vac_bcg_stock density $covariateKR || v001:, or	
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(bcg) modify
			putexcel AB2 = "Model 4"
			putexcel Z3 = matrix(results), names nformat(number_d2) right 	
			
	* yml_act	
		svy: melogit yml_act sara_act_* || v001:, or		
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(act) modify
			putexcel A1="Odds of receiving ACT among children under-five with fever within 2 week. Random intercept"
			putexcel D2 = "Model 1" 
			putexcel B3 = matrix(results), names nformat(number_d2) right 	
			
		svy: melogit yml_act sara_act_* density || v001:, or			
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(act) modify
			putexcel L2 = "Model 2"
			putexcel J3 = matrix(results), names nformat(number_d2) right 			
			
		svy: melogit yml_act sara_act_* $covariateKR || v001:, or			
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(act) modify
			putexcel T2 = "Model 3"
			putexcel R3 = matrix(results), names nformat(number_d2) right 			
			
		svy: melogit yml_act sara_act_* density $covariateKR || v001:, or			
			matlist r(table)
			matrix results = r(table)
			matrix results = results[1..6,1...]'
			matlist results
			putexcel set Mali_DHS_SARA_Linked_$date.xlsx, sheet(act) modify
			putexcel AB2 = "Model 4"
			putexcel Z3 = matrix(results), names nformat(number_d2) right 	
			
OKAY END OF ANALYSIS			
			
/*
	
use IR_Mali_2018_LinkedAnalysis.dta, clear
	svyset v021, weight(xweight) strata(v023) , singleunit(centered) || _n, weight(xweight2)
	
	*random intercept, null model
	svy: melogit yfp_cruse_mod || v001:, or
	
	*random intercept, with key cov 
	svy: melogit yfp_cruse_mod sara_fp_ready || v001:, or

	*random intercept, with other cov 
	svy: melogit yfp_cruse_mod sara_fp_ready xsecondary xpoor xrich xrurb || v001:, or 		
	melogit yfp_cruse_mod sara_fp_ready xsecondary xpoor xrich xrurb || v001:, or 			
	estimates store model1

	*random intercept & random slope on key cov, with other cov 	
	svy: melogit yfp_cruse_mod sara_fp_ready xsecondary xpoor xrich xrurb || v001: sara_fp_ready, covariance(unstructured) or			
	melogit yfp_cruse_mod sara_fp_ready xsecondary xpoor xrich xrurb || v001: sara_fp_ready, covariance(unstructured) or			
	estimates store model2
	
	lrtest model1 model2
	
	svy: melogit yfp_cruse_mod xsecondary || v001:, or 	
	svy: melogit yfp_cruse_mod xsecondary || xregion: || v021:, or 	
	
/*

*IDENTICAL results
use IR_Mali_2018_LinkedAnalysis.dta, clear
	foreach var of varlist $outcomeIR $covariate {
		tabout `var' using Tables_Pref_wm.xls [iw=xweight] , c(col) f(1) replace 
	}
	collapse (mean) $outcomeIR $covariate [iw=xweight] 
		ds
		foreach var of varlist `r(varlist)' {
			replace `var'=`var'*100
			format `var' %9.1f
			}
	list		
*/

/*
************************************************************************
* D. Analysis: Descriptive 
************************************************************************

global outcomeIR "yfp_cruse_mod yml_two_iptp" 
global outcomeKR "yrh_anc_4vs ystunting ych_bcg_either yml_act"
global covariate "xage_5_* xmcurrent xnoschool xprimary xsecondary xpoor xrich xrurb"  

capture putdocx clear 
putdocx begin

putdocx paragraph
putdocx pagebreak 
putdocx text ("IR"), linebreak bold 

	use IR_Mali_2018_LinkedAnalysis.dta, clear
		sum $covariate 
		sum $outcomeIR 
		tab xbirth24

		collapse (mean) $outcomeIR $covariate [iw=xweight] 
			ds
			foreach var of varlist `r(varlist)' {
				replace `var'=`var'*100
				format `var' %9.1f
				}
		
putdocx paragraph
putdocx pagebreak 
putdocx text ("KR"), linebreak bold 
	
	use KR_Mali_2018_LinkedAnalysis.dta, clear
		sum $covariate 
		sum $outcomeKR 
		tab xml_fever if b5==1
		tab xcage1223 if b5==1 
		
		collapse (mean) $outcomeKR $covariate [iw=xweight] 
			ds
			foreach var of varlist `r(varlist)' {
				replace `var'=`var'*100
				format `var' %9.1f
				}
*/
