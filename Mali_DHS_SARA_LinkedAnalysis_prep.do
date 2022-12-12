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

* Table of Contents for this do file
* 	A. SETTING
* 	B. DATA PROCESSING: DHS
* 	C. DATA PROCESSING: merging regional level SARA data
* 	D. DATA PROCESSING: regional level facility density
* 	E. MERGE

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
global data "C:\Users\YoonJoung Choi\Dropbox\0 Data\DHS\"

#delimit;
global datalist " 
	IR_Mali_2018
	KR_Mali_2018
	";
	#delimit cr
	
************************************************************************
* B. DATA PROCESSING: DHS
************************************************************************

foreach recode_ctry_yr in $datalist{
	use "$data\\`recode_ctry_yr'.dta", clear		

*****0. Keep completed interviews (which is all in DHS)
	keep if v015==1
	
		gen xweight=v005/1000000
		gen xweight2=1
	
*****1. BACKGROUND Individual 	
	* Age
		rename v012 xage 
		egen xage_5		=cut(xage), at(10, 15, 20, 25, 30, 35, 40, 45, 50, 60) 
			tab xage_5, gen(xage_5_) 
		
	* Marital status
		rename v501 xmstatus_detail
		rename v502 xmstatus		
		gen byte xmnever = xmstatus==0
		gen byte xmever = xmnever==0
		gen byte xmcurrent = xmstatus==1	
		gen byte xmformerly = xmstatus>1	
			tab xmstatus*, m		
		lab var xmnever "never married"
		lab var xmcurrent "currently married" 
		lab var xmformerly "formerly married"
		
	* Education 
		rename v106 xedusome /*highest level ever attended*/
		rename v133 xeduyears
		rename v149 xeducomp 
		tab xedusome xeducomp, m
					
		clonevar xedu3 = xedusome
		*combining higher and secondary:
		recode xedu3 3=2
		label var xedu3 "Highest ed level attended"
		label define edu3lab 0 "none" 1 "primary" 2 "secondary +"
		label values xedu3 edu3lab	
		
		tab xedusome xedu3
		*dummy vars (for later use)
		tab xedu3, gen(dummy)
		rename dummy1 xnoschool
		rename dummy2 xprimary
		rename dummy3 xsecondary	

*****2. BACKGROUND household 	
	* Region	
		rename v024 xregion 
	
	* Residential area
		rename v102 xrurb 
			recode xrurb 2=0
			
	* Electricity	
		gen byte xelectricity=v119==1
		lab var xelectricity "HH with electricity"		
	* Wealth	
		rename v190 xwealth5 
		
		gen byte xpoor=xwealth5==1
		gen byte xmiddle=xwealth5>=2 & xwealth<=4 
		gen byte xrich=xwealth5==5 
		
		tab xwealth5, gen(dummy)
			rename dummy1 xwlowest
			rename dummy2 xwsecond
			rename dummy3 xwmiddle
			rename dummy4 xwfourth
			rename dummy5 xwhighest		

keep caseid v0* x* v313* b4* b5* b19* h* m*		
save "`recode_ctry_yr'_LinkedAnalysis.dta", replace	
}			

*****2. BACKGROUND child level
use KR_Mali_2018_LinkedAnalysis.dta, clear	

	* child age
		rename b19 xcage 
		egen xcage_yr		=cut(xcage), at(0,12,24,36,48,60) 
			tab xcage_yr, gen(xcage_yr_) 
	
	* Sex 
		rename b4 xmale 
			recode xmale 2=0
		label var xmale "Child is male"
		label define male 0 "female" 1 "male"
		label values xmale male 

save KR_Mali_2018_LinkedAnalysis.dta, replace 
	
*****3. Outcome: woman-level 
use IR_Mali_2018_LinkedAnalysis.dta, clear	
	*•	Use of modern contraception
		//Currently use modern method
		gen yfp_cruse_mod = v313==3
		label var yfp_cruse_mod "Currently used any modern method"

	*•	Percent of women 15-49 with a birth in the last 2 years receiving SP/Fansidar 2+ doses, at least one during ANC visit (IPTp)
		//had birth in the last 2 years 
		gen xbirth24= b19_01<24		
			
		//2+ doses SP/Fansidar
		gen yml_two_iptp=0
		replace yml_two_iptp=1 if m49a_1==1 & ml1_1 >=2 & ml1_1<=97
		replace yml_two_iptp=. if xbirth24==0 /*analysis sample restriction*/
		lab var yml_two_iptp "Two or more doses of SP/Fansidar"

keep caseid v0* x* y*
save IR_Mali_2018_LinkedAnalysis.dta, replace

*****3. Outcome: child-level		
use KR_Mali_2018_LinkedAnalysis.dta, clear	

	*•	Percent of births in last five years receiving at least 4 ANC visits
		//Number of ANC visits in 4 categories that match the table in the final report
		recode m14 (0=0 "none") (1=1) (2 3=2 "2-3") (4/90=3 "4+") (else=9 "don't know/missing"), gen(yrh_anc_numvs)
		replace yrh_anc_numvs=. if xcage>59
		replace yrh_anc_numvs=. if m14==.
		label var yrh_anc_numvs "Number of ANC visits"
		
		tab m14 yrh_anc_numvs, m
		
		//4+ ANC visits  
		recode yrh_anc_numvs (1 2 9=0 "no") (3=1 "yes"), gen(yrh_anc_4vs)
		replace yrh_anc_4vs=. if xcage>59
		replace yrh_anc_4vs=. if m14==.
		lab var yrh_anc_4vs "Attended 4+ ANC visits"
		
	*•	Percent of births at facilities 
		//facility delivery
		recode m15 (11/12=0 "home") (else=1 "facility"), gen(yrh_facilitydel)
		replace yrh_facilitydel=. if xcage>59
		replace yrh_facilitydel=. if m15==.
		label var yrh_facilitydel "Delivery at facilities"
		
		tab m15 yrh_facilitydel, m

	*•	Percent of children 12-23 receiving BCG vaccination
		//BCG either source
		recode h2 (0 8=0) (else=1), gen(ych_bcg_either)
		replace ych_bcg_either =. if xcage<12 | xcage>23 
		replace ych_bcg_either =. if b5==0
		replace ych_bcg_either =. if h2==.
		label var ych_bcg_either	"BCG vaccination according to either source"
		
		gen byte xcage1223=xcage>=12 & xcage<=23 
		lab var xcage1223			"children 12-23 month old"
		
	*•	Prevalence of moderate-to-severe stunting among children under five
		gen ystunting=hw70<-200
		replace ystunting=. if xcage>59
		replace ystunting=. if b5==0
		
	*•	Percent of children under five with fever who took any ACT
	
		//Fever
		gen xml_fever=(h22==1)
		replace xml_fever =. if xcage>59
		replace xml_fever =. if b5==0
		lab var xml_fever "Fever symptoms in the 2 weeks before the survey"

		//Child with fever in past 2 weeks took an ACT
		*gen xml_act=0 if xml_fever==1 & xml_antimal==1
		gen yml_act=0 if xml_fever==1 /*analysis sample restriction*/
		replace yml_act=1 if ml13e==1 
		lab var yml_act "Child took an ACT"

keep caseid v0* x* y* b* midx	
save KR_Mali_2018_LinkedAnalysis.dta, replace 


foreach recode_ctry_yr in HR_Mali_2018{
	use "$data\\`recode_ctry_yr'.dta", clear		

	* weight
		gen xweight=hv005/1000000
		
	* Region	
		rename hv024 xregion 
	
	* Residential area
		rename hv025 xurban
			recode xurban 2=0
			
	* Electricity	
		gen byte xelectricity=hv206==1
		lab var xelectricity "HH with electricity"		

	* Wealth	
		rename hv270 xwealth5 
		gen byte xtop2=xwealth5>=4 		
		lab var xtop2 "Top 2 wealth quintiles"		
		
keep hhid hv0* x* 
save "`recode_ctry_yr'_LinkedAnalysis.dta", replace	
}			
 



************************************************************************
* C. DATA PROCESSING: merging regional level SARA data
************************************************************************

* C-1. Import tables from the excel file 
	import excel "fromICF\WP 169 draft_SARA and DHS Linkage results_v2.xlsx", sheet("Table 1 Contraception") clear
		save sara_fp.dta, replace 
	import excel "fromICF\WP 169 draft_SARA and DHS Linkage results_v2.xlsx", sheet("Tables 2-4 ANC and Maternal") clear
		save sara_maternal.dta, replace /*NOTE there are three tables here*/
	import excel "fromICF\WP 169 draft_SARA and DHS Linkage results_v2.xlsx", sheet("Table 5 Vaccination _ all") clear
		save sara_vacall.dta, replace 
	import excel "fromICF\WP 169 draft_SARA and DHS Linkage results_v2.xlsx", sheet("Table 6 Vaccination by type") clear
		save sara_vacbytype.dta, replace
	import excel "fromICF\WP 169 draft_SARA and DHS Linkage results_v2.xlsx", sheet("Table 7 Diarhhea") clear
		save sara_diarrhea.dta, replace	
	import excel "fromICF\WP 169 draft_SARA and DHS Linkage results_v2.xlsx", sheet("Table 8 Stunting") clear
		save sara_stunting.dta, replace
	import excel "fromICF\WP 169 draft_SARA and DHS Linkage results_v2.xlsx", sheet("Table 9 Wasting") clear
		save sara_wasting.dta, replace	
	import excel "fromICF\WP 169 draft_SARA and DHS Linkage results_v2.xlsx", sheet("Table 10 IPT") clear
		save sara_ipt.dta, replace
	import excel "fromICF\WP 169 draft_SARA and DHS Linkage results_v2.xlsx", sheet("Table 11 Fever") clear
		save sara_act.dta, replace
	import excel "fromICF\WP 169 draft_SARA and DHS Linkage results_v2.xlsx", sheet("Table 12 HIV ") clear
		save sara_hiv.dta, replace	
	
* C-2. Prep all services EXCEPT maternal, which has three tables in one sheet 

	local services "fp vacall vacbytype diarrhea stunting wasting ipt act hiv"
		
	foreach x in `services'{
		use  sara_`x'.dta, clear
			*drop the first column with TOC link
			drop A
			
			*rename B
			rename B region
				#delimit;
				keep if region=="Bamako" |
						region=="Gao"|
						region=="Kayes"|
						region=="Koulikoro"|
						region=="Mopti"|
						region=="Ségou"|
						region=="Sikasso"|
						region=="Tombouctou"|
						region=="Total"|
						region=="";
				#delimit cr	

			*drop the first two empty rows
			drop in 1/2			
			
			*keep ther first 11 rows because of the ANC/MH have many rows 
			keep in 1/11
			
			*drop empty columns
			ds, not(type string)
			foreach var of varlist `r(varlist)' {
				quietly sum `var'
				if `r(N)'==0 {
					drop `var'
					disp "dropped `var' for too much missing data"
				}
			}

			d

		save sara_`x'.dta, replace
		}

		use sara_fp.dta, clear 
			list if _n==2
				rename C dhs_mcpr_all
				rename E sara_fp_offer
				rename F sara_fp_staff
				rename G sara_fp_ready
				lab var sara_fp_offer "Percent of facilities offering family planning services"
				lab var sara_fp_staff "Percent of facilities with staff trained in FP"
				lab var sara_fp_ready "Family planning service readiness score"
			drop in 1/2
			sort region
		save sara_fp.dta, replace 

		use  sara_vacall.dta, clear
			list if _n==2
				rename C dhs_vac_basic
				rename E sara_vac_offer
				rename F sara_vac_staff
				rename G sara_vac_offer_d
				rename H sara_vac_offer_w
				rename I sara_vac_offer_m
				lab var sara_vac_offer "Percent of facilities offering  child immunization services"
				lab var sara_vac_staff "Percent of facilities with staff trained in child immunization"
				lab var sara_vac_offer_d "Percent of facilities offering routine child immunization services at the facility on daily basis"
				lab var sara_vac_offer_w "Percent of facilities offering routine child immunization services at the facility on weekly basis"
				lab var sara_vac_offer_m "Percent of facilities offering routine child immunization services at the facility on monthly basis"
			drop in 1/2
			sort region
		save sara_vacall.dta, replace 

		use  sara_vacbytype.dta, clear
			list if _n==2	
				rename C dhs_vac_bcg
				rename F dhs_vac_dpt
				rename I dhs_vac_polio
				rename L dhs_vac_measles
				rename D sara_vac_bcg_stock
				rename G sara_vac_dpt_stock
				rename J sara_vac_pol_stock
				rename M sara_vac_mea_stock
				lab var sara_vac_bcg_stock "Percent of facilities with BCG vaccine in-stock"
				lab var sara_vac_dpt_stock "Percent of facilities with DPT-HepB-Hib vaccine in-stock"
				lab var sara_vac_pol_stock "Percent of facilities with Polio vaccine in-stock"
				lab var sara_vac_mea_stock "Percent of facilities with measles vaccine in-stock"       
			drop in 1/2
			sort region
		save sara_vacbytype.dta, replace

		use  sara_diarrhea.dta, clear
			list if _n==2
				rename C dhs_ors
				rename F dhs_orszinc
				rename D sara_dia_ors
				rename G sara_dia_offer
				lab var sara_dia_ors "Percent of facilities with ORS packets"
				lab var sara_dia_offer "Percent of facilities offering ORS and Zinc supplementation"
			drop in 1/2
			sort region
		save sara_diarrhea.dta, replace
		
		use  sara_stunting.dta, clear
			list if _n==2
				rename C dhs_stunting
				rename E sara_growth_guidelines
				rename F sara_growth_staff
				rename G sara_growth_height
				rename H sara_growth_chart
				lab var sara_growth_guidelines "Percent of facilities with guidelines for growth monitoring"
				lab var sara_growth_staff "Percent of facilities with staff trained in growth monitoring"         
				lab var sara_growth_height "Percent of facilities with length/height measuring equipment" 
				lab var sara_growth_chart "Percent of facilities with growth chart"  
			drop in 1/2
			sort region
		save sara_stunting.dta, replace

		use  sara_wasting.dta, clear
			list if _n==2
				rename C dhs_wasting			
				rename E sara_growth_guidelines
				rename F sara_growth_staff
				rename G sara_growth_weight
				rename H sara_growth_height
				rename I sara_growth_chart
				lab var sara_growth_guidelines "Percent of facilities with guidelines for growth monitoring"
				lab var sara_growth_staff "Percent of facilities with staff trained in growth monitoring"         
				lab var sara_growth_weight "Percent of facilities with child/infant scale4" 
				lab var sara_growth_height "Percent of facilities with length/height measuring equipment" 
				lab var sara_growth_chart "Percent of facilities with growth chart"  
			drop in 1/2
			sort region
		save sara_wasting.dta, replace
				
		use  sara_ipt.dta, clear
			list if _n==2
				rename C dhs_preg_iptp2
				rename E sara_ipt_offer
				rename F sara_ipt_staff
				rename G sara_ipt_drug
				lab var sara_ipt_offer "Percent of facilities offering IPT"
				lab var sara_ipt_staff "Percent of facilities with staff trained in IPT"   
				lab var sara_ipt_drug "Percent of facilities with IPT drug"   
			drop in 1/2
			sort region
		save sara_ipt.dta, replace

		use  sara_act.dta, clear
			list if _n==2
				rename C dhs_fev_test
				rename F dhs_fev_act	
				rename D sara_act_maldx
				rename G sara_act_drug
				lab var sara_act_maldx "Percent of facilities with malaria diagnostic capacity"
				lab var sara_act_drug "Percent of facilities with first-line antimalarial in stock"
			drop in 1/2
			sort region
		save sara_act.dta, replace
		
		use  sara_hiv.dta, clear
			list if _n==2
				rename C dhs_preg_counsel
				rename F dhs_preg_cnt	
				rename D sara_hiv_offer
				rename G sara_hiv_staff
				rename H sara_hiv_dx
				lab var sara_hiv_offer  "Percent of facilities offering HIV counselling and testing services"
				lab var sara_hiv_staff "Percent of facilities with staff trained in HIV counseling and testing"
				lab var sara_hiv_dx "Percent of facilities with HIV diagnostic capacity"   
			drop in 1/2
			sort region
		save sara_hiv.dta, replace		

* C-3. Prep maternal services 

		use  sara_maternal.dta, clear
			keep in 3/15
		save  sara_anc.dta, replace
			
		use  sara_maternal.dta, clear
			keep in 23/35
		save  sara_tetanus.dta, replace

		use  sara_maternal.dta, clear
			keep in 43/55
		save  sara_delivery.dta, replace		

	local services "anc tetanus delivery"
		
	foreach x in `services'{
		use  sara_`x'.dta, clear
			*drop the first column with TOC link
			drop A
			
			*rename B
			rename B region
				#delimit;
				keep if region=="Bamako" |
						region=="Gao"|
						region=="Kayes"|
						region=="Koulikoro"|
						region=="Mopti"|
						region=="Ségou"|
						region=="Sikasso"|
						region=="Tombouctou"|
						region=="Total"|
						region=="";
				#delimit cr	
			
			*drop empty columns
			ds, not(type string)
			foreach var of varlist `r(varlist)' {
				quietly sum `var'
				if `r(N)'==0 {
					drop `var'
					disp "dropped `var' for too much missing data"
				}
			}

			d

		save sara_`x'.dta, replace
		}

		use  sara_anc.dta, clear
			list if _n==2
				rename C dhs_preg_anc4
				rename E sara_anc_offer
				rename F sara_anc_staff
				rename G sara_anc_ready
				lab var sara_anc_offer "Percent of facilities providing ANC services"
				lab var sara_anc_staff "Percent of facilities with staff trained in ANC"
				lab var sara_anc_ready "ANC readiness score"
			drop in 1/2
			sort region
		save sara_anc.dta, replace
		
		use  sara_tetanus.dta, clear
			list if _n==2
				rename C dhs_preg_tetanus
				rename E sara_tetanus_stock 
				lab var sara_tetanus_stock "Percent of facilities with tetanus toxoid vaccine" 
			drop in 1/2
			sort region
		save sara_tetanus.dta, replace
		
		use  sara_delivery.dta, clear
			list if _n==2
				rename C dhs_del_fac
				rename E sara_del_offer
				rename F sara_del_ready 
				lab var sara_del_offer "Percent of facilities offering delivery services"
				lab var sara_del_ready "BEmOC service readiness score"			
			drop in 1/2
			sort region
		save sara_delivery.dta, replace	
			
* C-4. Merge all services 
	
local servicesminusone "anc tetanus delivery vacall vacbytype diarrhea stunting wasting ipt act hiv"
	
	use  sara_fp.dta, clear
	sort region
	foreach x in `servicesminusone'{
		merge region using sara_`x'.dta, 
		drop _merge*
		sort region
	}		
	
	ds, 
	foreach var of varlist `r(varlist)' {
		replace `var' ="" if `var' =="…"
	}	
	
	ds, 
	foreach var of varlist `r(varlist)' {
		destring(`var'), replace
	}

	gen xregion=.
		replace xregion=	1	if region=="Kayes"
		replace xregion=	2	if region=="Koulikoro"
		replace xregion=	3	if region=="Sikasso"
		replace xregion=	4	if region=="Ségou"
		replace xregion=	5	if region=="Mopti"
		replace xregion=	6	if region=="Tombouctou"
		replace xregion=	7	if region=="Gao"
		replace xregion=	8	if region=="Kidal" /*This region not covered in SARA*/
		replace xregion=	9	if region=="Bamako"
	
	keep region xregion sara_* dhs_* 
	
	sort xregion
	save sara.dta, replace	

local services "fp maternal anc tetanus delivery vacall vacbytype diarrhea stunting wasting ipt act hiv"
	foreach x in `services'{
		erase sara_`x'.dta 
	}		
/*
************************************************************************
* D. DATA PROCESSING: regional level facility density => DO NOT USE THIS, use the table from the final table
************************************************************************
* 	Number of facilities by region came from ICF GIS team. 
*	 	They aggregated individual facility data from this database/article 
*		https://www.nature.com/articles/s41597-019-0142-2?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+sdata%2Frss%2Fcurrent+%28Scientific+Data%29
*		"a health facility database described in this article contains all 
*		public health facilities and non-profit facilities"
* 	Number of population by region came from the Mali DHS 2018 sampling annex.  
*		https://dhsprogram.com/pubs/pdf/FR358/FR358.pdf
* 		Tableau A.1 Répartition de la population dans la base de sondage
*			Répartition (en nombre) de la population par milieu de résidence, 
*			pourcentage de la population totale et pourcentage de la
*			population en milieu urbain, selon la région, EDSM-VI Mali 2018

import delimited "fromICF\FacitiesByRegion.csv", clear

	rename  ïdhsregfr region 
	replace region="Ségou" if region=="SÃ©gou"
	gen xregion=.
		replace xregion=	1	if region=="Kayes"
		replace xregion=	2	if region=="Koulikoro"
		replace xregion=	3	if region=="Sikasso"
		replace xregion=	4	if region=="Ségou"
		replace xregion=	5	if region=="Mopti"
		replace xregion=	6	if region=="Tombouctou"
		replace xregion=	7	if region=="Gao"
		replace xregion=	8	if region=="Kidal" /*This region not covered in SARA*/
		replace xregion=	9	if region=="Bamako"
	
	gen n_facilities=hospitals_count + nonhospitals_count
	gen n_pop=.
		replace n_pop=	1993615	 if region=="Kayes"
		replace n_pop=	2422108	 if region=="Koulikoro"
		replace n_pop=	2611405	 if region=="Sikasso"
		replace n_pop=	2338349	 if region=="Ségou"
		replace n_pop=	2036209	 if region=="Mopti"
		replace n_pop=	 674793	 if region=="Tombouctou"
		replace n_pop=	 542304	 if region=="Gao"
		replace n_pop=	  67739	 if region=="Kidal"
		replace n_pop=	1810366	 if region=="Bamako"
	
	rename hospitals_count n_hospitals_count 
	rename nonhospitals_count n_nonhospitals_count
	
	gen density=round((n_facilities / n_pop)*1000000)
	lab var density "facility density: number of public or non-profit facilities per 1 million population"
	
	sort xregion 
	list region density 
	
	save facility_density.dta, replace 
*/
	
************************************************************************
* E. MERGE
************************************************************************

use IR_Mali_2018_LinkedAnalysis.dta, clear
	/*
	sort xregion
	merge xregion using facility_density.dta
		tab xregion _merge
			keep if _merge==3 
			drop _merge	
	*/
	sort xregion
	merge xregion using sara.dta
		tab xregion _merge
			keep if _merge==3 /*No Kidal in SARA, thus Kidal excluded from analysis*/
			drop _merge				
save IR_Mali_2018_LinkedAnalysis.dta, replace

use KR_Mali_2018_LinkedAnalysis.dta, clear
	/*
	sort xregion
	merge xregion using facility_density.dta
		tab xregion _merge
			keep if _merge==3 
			drop _merge	
	*/
	sort xregion
	merge xregion using sara.dta
		tab xregion _merge
			keep if _merge==3 /*No Kidal in SARA, thus Kidal excluded from analysis*/
			drop _merge
save KR_Mali_2018_LinkedAnalysis.dta, replace 

*Well done! End of do file
