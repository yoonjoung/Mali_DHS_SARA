**********************************************************************
** This is for Mali DHS-SARA linked analysis: AT THE REGIONAL LEVEL **
**********************************************************************
* 	Outcomes from DHS API - except two services
***		1. ANC4+ withint the last TWO years
***		2. facility delivery within the last TWO years
*	SARA data from the final report.  
***		PDF file was converted to word. then tables extracted to excel. 
***		Did not end up using excel from Gheda, since it did not have domain scores consistently 

* Table of Contents of this do file
* 	A. SETTING /*THIS MUST BE CHANGED FOR YOUR SETTING for directories*/
* 	B. Create variables: Run the THREE prep do files, that generate variables for this report (see below for more info)
* 	C. Further creation of variables using DHS datafiles 
* 		C.1 Create a dataset for regional background characteristics from DHS recode files: HR and IR
* 		C.2 Create a dataset for the two outcomes variables that are not included in the DHS API 
* 		C.3 Merge the above two datasts 
* 	D. Further creation of variables using SARA datafiles  
* 	E. Merge all datasets created above. Resulting file will be at the REGIONAL level (i.e., each row=region)  
* 	F. Analysis 
* 		F.1 PART 1: SARA regional variation
*		F.1 PART 2: Correlation between utilization and service environment	
* 	G. Additional figures for background, methods, and discussion 
* 	H. Appendix 3

********************************************************************** END OF INTRODUCTION 

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
global data "C:\Users\YoonJoung Choi\Dropbox\0 Data\DHS\"
cd "C:\Users\YoonJoung Choi\Dropbox\0 iSquared\iSquared_DHS\Mali_DHS_SARA\"

local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)

************************************************************************
* B. Run the prep do file, 
************************************************************************
/*
NOTE: 
1. THE FOLLOWING THREE DO FILES MUST BE IN THE SAME DIRECTORY WITH THIS DO FILE.
2. IN EACH OF THE DO FILE, REVISE DIRECTORY SETTING
*/

*1. create variables for service utilization outcomes (DHS API)
*=> this generates "API_Mali_DHS.dta"
do API_Mali_DHS.do 

*2. create variables for service environment (SARA)
*=> this generates "SARA_tables.dta"
do SARA_tables.do 

*3. Create service utilization variables using DHS recode files. 
*=> this generates "IR_Mali_2018_LinkedAnalysis.dta". It will be used for Section C.1 and C.2  
*=> this also generates "sara.dta"	/*this is from Gheda's excel file. Don't use this for this study*/
do Mali_DHS_SARA_LinkedAnalysis_prep.do 

************************************************************************
* C.1 Generate regional background characteristics 
************************************************************************

use HR_Mali_2018_LinkedAnalysis.dta, clear
		collapse (mean) xurban xtop2 xelectricity [iw=xweight], by(xregion)
		sort xregion
		save temp.dta, replace
	use HR_Mali_2018_LinkedAnalysis.dta, clear
		collapse (mean) xurban xtop2 xelectricity [iw=xweight], 
			gen xregion=10
			append using temp.dta 
			
		lab var xurban "% HH in urban"
		lab var xtop2 "% HH in top 2 quintiles"
		lab var xelec "% HH with electrivity"
		
		sort xregion
		save temp.dta, replace	

use IR_Mali_2018_LinkedAnalysis.dta, clear
			gen byte xedupri=xedu3>=1
			gen byte xedusec=xedu3>=2
		collapse (mean) yfp_cruse_mod xedupri xedusec [iw=xweight], by(xregion)
		sort xregion
		save temp2.dta, replace
	use IR_Mali_2018_LinkedAnalysis.dta, clear
			gen byte xedupri=xedu3>=1
			gen byte xedusec=xedu3>=2
		collapse (mean) yfp_cruse_mod xedupri xedusec [iw=xweight], 
			gen xregion=10
			append using temp2.dta 
			
		sort xregion
		merge xregion using temp.dta 
			tab _merge, m
		keep if _merge==3
			drop _merge
		
		rename yfp_cruse_mod	mcpr_all
		lab var mcpr_all "mcpr among all women"
		lab var xedupri "% 15-9 women who attended primary school"
		lab var xedusec "% 15-9 women who attended secondary school"			
			
		sort xregion
		save temp.dta, replace		
		
************************************************************************
* C.2 Generate non-API outcome data
************************************************************************

use KR_Mali_2018_LinkedAnalysis.dta, clear
	keep if xcage_yr<24
	
		collapse (mean) yrh_anc_4vs yrh_facilitydel [iw=xweight], by(xregion)
		sort xregion
		save temp2.dta, replace
		
use KR_Mali_2018_LinkedAnalysis.dta, clear
	keep if xcage_yr<24
	
		collapse (mean) yrh_anc_4vs yrh_facilitydel [iw=xweight], 
			gen xregion=10
			append using temp2.dta 

************************************************************************
* C.3 Merge above two datasets 
************************************************************************
			
		sort xregion
		merge xregion using temp.dta 
			tab _merge, m
		keep if _merge==3
			drop _merge
	
		rename yrh_anc_4vs 		anc4
		rename yrh_facilitydel  facilitydel
		
		lab var anc4 "% pregnant women with 4+ anc (WITHIN 2 years)"
		lab var facilitydel "% births at facilities (WITHIN 2 years)"
		
		foreach x of varlist mcpr_all anc4 facilitydel xedu* xurban xtop2 xelec{
			replace `x'=`x'*100
			format `x' %9.1f
			}
			
		sort xregion 
		save temp.dta, replace	

	/*
	*** CHECK unweighted denominator for DHS indicators
	
	use API_Mali_DHS.dta, clear
	keep if year==2018
	keep if group=="Region" | group=="Total"
	sum nuw_*	
	
	use KR_Mali_2018_LinkedAnalysis.dta, clear
	tab xregion if yrh_anc_num~=. 
	tab xregion if xcage_yr==12
	*/	
		
************************************************************************
* D. SDP sample distribution 
************************************************************************
	
use "fromICF\SARAdata\SARA Mali 2018.dta", clear

		/*
		codebook Q005_NAME Q007 Q008 Q009
		
		tab Q007
		tab Q007 Q009, m
		tab Q007 Q008, m
		
		CODE for Q007 facility type
		1 CHU: Centre Hospitalo-Universitaire
		2 EPH: Établissement Public Hospitalier
		3 CSRéf: Centre de Santé de Référence [Reference Health Center] 
		4 CSCom: Centre de Santé Communautaire  [Community Health Center]
		5 CMIE: Centre Medical Inter-Enterprise 
		6 INFIRMERIE 
		7 POLYCLINIQUE 
		8 CLINIQUE 
		9 CABINET MEDICAL 
		96 AUTRE (PRECISER) 
		
						 |        Managing authority
		Type of facility |    Public      Privé  Confessio |     Total
		-----------------+---------------------------------+----------
					 CHU |         4          0          0 |         4 
					 EPH |         7          0          0 |         7 
				   CSRéf |        56          0          0 |        56 
				   CSCom |       275          0          4 |       279 
					CMIE |         5          0          0 |         5 
			  INFIRMERIE |         6          2          0 |         8 
			POLYCLINIQUE |         0          5          0 |         5 
				CLINIQUE |         1         30          0 |        31 
		 CABINET MEDICAL |         1         86          1 |        88 
		AUTRE (PRECISER) |         0          1          0 |         1 
		-----------------+---------------------------------+----------
				   Total |       355        124          5 |       484 

		
		*/

		gen 	nsdp_CHU	 		= 1 if Q007 ==1
		gen 	nsdp_EPH	 		= 1 if Q007 ==2
		gen 	nsdp_hospitals	 	= 1 if Q007 >=1 & Q007 <= 2
		gen 	nsdp_CSRrf	 		= 1 if Q007 ==3
		gen 	nsdp_CSCom	 		= 1 if Q007 ==4
		gen 	nsdp_CMIE	 		= 1 if Q007 ==5
		gen 	nsdp_INFIRMERIE	 	= 1 if Q007 ==6
		gen 	nsdp_polyclinic		= 1 if Q007 ==7
		gen 	nsdp_clinic	 		= 1 if Q007 ==8		
		gen 	nsdp_clinics 		= 1 if Q007 >=7 & Q007 <=8
		gen 	nsdp_CABINETMEDICAL	= 1 if Q007 ==9
		gen 	nsdp_other		  	= 1 if Q007 ==96
						
		gen 	nsdp_pub	 = 1 if Q008 ==	1
		gen 	nsdp_nonpub	 = 1 if Q008 ~=	1
						
		gen 	nsdp_urban	 = 1 if Q009 ==	1
		gen 	nsdp_rural	 = 1 if Q009 ==	2
		
		gen region=Q005_NAME
			replace region="Ségou" if region=="S!gou"
			
		gen nnpub3=1 if nsdp_hospitals ==1
		gen nnpub2=1 if nsdp_CSRrf==1
		gen nnpub1=1 if nsdp_CSCom==1 | nsdp_INFIRMERIE==1 
		gen nnprv3=1 if nsdp_polyclinic==1	 	  
		gen nnprv2=1 if nsdp_clinic==1	 	 
		gen nnprv1=1 if nsdp_CABINETMEDICAL==1 | nsdp_CMIE==1	 
		gen nnother=1 if nsdp_other==1	
			
		save tempsdp.dta, replace	
		
	use tempsdp.dta,clear
	collapse (count) nsdp_* nn*, by(region)
		sort region
		save temp2.dta, replace

	use tempsdp.dta,clear
	collapse (count) nsdp_* nn*, 
		gen region="Total" 
		append using temp2.dta 
	
	sort region
	save tempsdpsummary.dta, replace	
		
************************************************************************
* E. Merge all datasets created above and clean little more.
************************************************************************

/* merge FOUR datasets at the regional level that were creted so far

1. SARA_tables.dta, clear /*created in section B*/
2. API_Mali_DHS.dta, clear /*created in section B*/
3. temp.dta /*created in section C*/
4. tempsdpsummary.dta /*created in section D*/

*/
	
use SARA_tables.dta, clear 
	tab region, m /* no Kidal in SARA 2018*/
	sort region
	save SARA_tables.dta, replace		

use API_Mali_DHS.dta, clear

	keep if year==2018
	keep if group=="Region" | group=="Total"
	drop nw_* nuw_*
	
	/*double check two indicators that do not have regional-level estimates
		
		use API_Mali_DHS.dta, clear
		keep if year==2018
		list group grouplabel vac_basic nuw_CH_VACS_C_BAS if vac_basic~=.
		
		use API_Mali_DHS.dta, clear
		keep if year==2018
		list group grouplabel preg_anc4 nuw_RH_ANCN_W_N4P if preg_anc4~=.	
	*/
	
	*IMPORT DHS estimates for the variable that do not have regional-level estimate 
	*From Gheda's excel file. 
	***VAC_ALL
	***		Age-appropriate vaccines for children 12-23 months include: 
	***		BCG, three doses of DPT, four doses of Polio vaccine; one dose of IPV, three doses of pneumococcal vaccine, three doses of rotavirus vaccine, one dose of measles vaccine, one dose of meningitis vaccine and one dose of yellow fever vaccine."							
	***		Source: Mali DHS 2018 Key Indicators,Table 10	
	*** 	This is for all vaccines, thus the level is much lower than the "basic 8"
	
		replace preg_anc4 =	72.0	if grouplabel=="Bamako"
		replace preg_anc4 =	37.0	if grouplabel=="Gao"
		replace preg_anc4 =	42.6	if grouplabel=="Kayes"
		replace preg_anc4 =	48.8	if grouplabel=="Koulikoro"
		replace preg_anc4 =	27.1	if grouplabel=="Mopti"
		replace preg_anc4 =	36.0	if grouplabel=="Ségou"
		replace preg_anc4 =	34.8	if grouplabel=="Sikasso"
		replace preg_anc4 =	28.3	if grouplabel=="Tombouctou"
		replace preg_anc4 =	43.3	if grouplabel=="Total"
		
		gen vac_all=.
		replace vac_all =	23.2	if grouplabel=="Bamako"
		replace vac_all =	8.5		if grouplabel=="Gao"
		replace vac_all =	12.7	if grouplabel=="Kayes"
		replace vac_all =	15.9	if grouplabel=="Koulikoro"
		replace vac_all =	11.7	if grouplabel=="Mopti"
		replace vac_all =	29.9	if grouplabel=="Ségou"
		replace vac_all =	15.1	if grouplabel=="Sikasso"
		replace vac_all =	19.7	if grouplabel=="Tombouctou"
		replace vac_all =	17.8	if grouplabel=="Total"	
	
	foreach var of varlist mcpr_all  - preg_cnt{
	rename `var' api_`var'
	}
	
	tab grouplabel, m
	gen region=grouplabel
	sort region
	
	merge region using SARA_tables.dta
		tab _merge surveyid, m
		bysort _merge: tab region surveyid, m 
	keep if _merge==3
		drop _merge
		
	gen regioncode=substr(region, 1, 3)
	tab regioncode,		
		                         
	gen xregion=.
		replace xregion=9 if region=="Bamako"
		replace xregion=7 if region=="Gao"
		replace xregion=1 if region=="Kayes"
		replace xregion=2 if region=="Koulikoro"
		replace xregion=5 if region=="Mopti"
		replace xregion=3 if region=="Sikasso"
		replace xregion=4 if region=="Ségou"
		replace xregion=6 if region=="Tombouctou"
		replace xregion=10 if region=="Total"

	sort xregion
	merge xregion using temp.dta /*THIS IS from Section C: further DHS variables*/
		tab _merge
	keep if _merge==3
		drop _merge
	
	list region api_mcpr_all mcpr_all 
	pwcorr mcpr_all api_mcpr_all api_mcpr_married api_mdm_all api_mdm_married, sig
	
	/*
	** COMPARE variables from PIA vs. 2-year constructed values
	twoway scatter api_del facilitydel facilitydel,
	twoway scatter api_preg_anc4 anc4 anc4,
	*/

	drop api_mcpr_all api_mcpr_married api_mdm_all api_mdm_married api_preg_anc4 api_del  
	*drop api_vac*

	/*
	***** Different DHS variables for utilization  
	drop if xregion==10

		** Malaria utilization variables
		sum api_fev*
		twoway scatter api_fev_test api_fev_consult api_fev_act api_fev_test , legend(off) mlab(region)
		pwcorr api_fev_test api_fev_consult api_fev_act ready_maldt av_ready_maldt access_av_ready_maldt, sig

		** HIV counseling and testing 
		sum api_preg_counseling api_preg_cnt
		twoway scatter api_preg_counseling api_preg_cnt api_preg_counseling , legend(off) mlab(region)
		pwcorr api_preg_counseling api_preg_cnt ready_hiv av_ready_hiv access_av_ready_hiv, sig
		
		** Diarrhea treatmetn 
		sum api_dia* 
		twoway scatter api_dia_adv api_dia_ors api_dia_ort api_dia_zinc api_dia_adv , legend(off) mlab(region)
		pwcorr api_dia_adv api_dia_ors api_dia_ort api_dia_zinc api_dia_adv ready_child av_ready_child access_av_ready_child, sig

	*/	
		
	gen dhs_fp 		= mcpr_all
	gen dhs_anc		= anc4
	gen dhs_del		= facilitydel 
	gen dhs_vac		= vac_all 
	gen dhs_child	= api_dia_adv 
	gen dhs_maldt	= api_fev_test 
	gen dhs_malipt	= api_preg_iptp2 
	gen dhs_hivct	= api_preg_cnt 
	gen dhs_pmtct	= api_preg_cnt 
	
	global servicelist "fp anc del vac child maldt malipt hivct pmtct"
	foreach service in $servicelist {
		gen diff_`service'=offer_`service' - av_ready_`service'
		format diff_`service' %4.0f
		}
	
	sort region 
	
	merge region using tempsdpsummary.dta, /*bring in NSDP: this is from Section D*/

		tab _merge, m
		drop _merge

	#delimit;
	lab define xregion
	1 "Kayes"
	2 "Koulikoro"
	3 "Sikasso"
	4 "Ségou"
	5 "Mopti"
	6 "Tombouctou"
	7 "Gao"
	9 "Bamako"
	;
	#delimit cr
	lab values xregion xregion
		
save Mali_DHS_SARA_Region_2018.dta, replace	

erase temp.dta
erase temp2.dta
erase tempsdp.dta
erase tempsdpsummary.dta

*GREAT stop here

/*
***** CHECK: variation

graph box mcpr_all api*
graph box dhs_* , legend(pos(3) col(1))
graph box ready_* , legend(pos(3) col(1))
graph box offer_fp offer_anc offer_del offer_vac offer_child offer_mal offer_hivct offer_pmtct , legend(off)
graph box av_ready_* , legend(pos(3) col(1))
graph box access_av_ready_* , legend(pos(3) col(1))
*/

/*
***** CHECK: index given vs. created 	
	
	graph bar fp_all fp_average ready_fp , over(region)	
	graph bar anc_index  ready_anc , over(region)	
	graph bar del_index  ready_del , over(region)	
	graph bar vac_all vac_average ready_vac , over(region)	
	graph bar child_all child_average ready_child , over(region)	
	*graph bar $sara_mal , over(region)
	*graph bar $sara_ipt , over(region)	
	graph bar hivct_all hivct_average ready_hivct , over(region)	
	graph bar pmtct_all pmtct_average ready_pmtct , over(region)	
*/


************************************************************************
* F. Analysis  
************************************************************************
use Mali_DHS_SARA_Region_2018.dta, replace	
keep region xregion dhs*
foreach var of varlist dhs*{
format `var' %4.0f
}
sort xregion
browse /*TABLE 3*/

************************************************************************
* F.1 PART 1: SARA regional variation
************************************************************************

set scheme s1color

capture putdocx clear 
putdocx begin

putdocx paragraph
putdocx text ("PART 1: SARA regional variation"), linebreak bold 
putdocx text ("")
putdocx text ("Service readiness by element: regional variation"), linebreak bold /*figure 5*/

use Mali_DHS_SARA_Region_2018.dta, replace	
drop if xregion==10

	#delimit; 
	global option "
			box(1, bcolor(navy*0.8))
			box(2, bcolor(cranberry*0.8))
			box(3, bcolor(dkgreen*0.8))
			box(4, bcolor(dkorange*0.8))
			box(5, bcolor(gray*0.8))
			marker(1, mcolor(navy*0.8))
			marker(2, mcolor(cranberry*0.8))
			marker(3, mcolor(dkgreen*0.8))
			marker(4, mcolor(dkorange*0.8))
			marker(5, mcolor(gray*0.8))
			ylab (0 (20) 100, angle(0) labsize(small))  
			xsize(4) ysize(2.5)"
			; 
			#delimit cr
			
	#delimit; 
	global legend "
			legend(row(1) size(vsmall) pos(6) ring(0) lcolor(white) rowgap(5) stack
					label(1 "Staff" "& guideliens")	
					label(2 "Equipment")		
					label(3 "Diagnostics")
					label(4 "Medicines" "& commodities")
					label(5 "Service" "readiness"))		"
			; 
			#delimit cr		
			
		*global servicelist "fp anc del vac child maldt malipt hivct pmtct"
		foreach service in fp{
			#delimit;
			graph box `service'_staffguide `service'_equipment `service'_diag `service'_drug ready_`service' , 
				$option $legend
				title("Family planning", size(medium))
				;
				#delimit cr
			*gr_edit legend.style.editstyle boxstyle(linestyle(color(white))) editcopy
			graph save graph_`service'.gph, replace
			graph save Graph Figures\Figure5_`service'.gph, replace	
		}

		foreach service in anc{
			#delimit;
			graph box `service'_staffguide `service'_equipment `service'_diag `service'_drug ready_`service' , 
				$option legend(off) 
				title("Antenatal care", size(medium))
				;
				#delimit cr
			graph save graph_`service'.gph, replace
			graph save Graph Figures\Figure5_`service'.gph, replace	
		}

		foreach service in del{
			#delimit;
			graph box `service'_staffguide `service'_equipment `service'_diag `service'_drug ready_`service' , 
				$option legend(off)
				title("Delivery care", size(medium))
				;
				#delimit cr
			graph save graph_`service'.gph, replace
			graph save Graph Figures\Figure5_`service'.gph, replace	
		}

		foreach service in vac{
			#delimit;
			graph box `service'_staffguide `service'_equipment `service'_diag `service'_drug ready_`service' , 
				$option legend(off)
				title("Child vaccination", size(medium))
				;
				#delimit cr
			graph save graph_`service'.gph, replace
			graph save Graph Figures\Figure5_`service'.gph, replace	
		}

		foreach service in child{
			#delimit;
			graph box `service'_staffguide `service'_equipment `service'_diag `service'_drug ready_`service' , 
				$option legend(off)
				title("Child health", size(medium))
				;
				#delimit cr
			graph save graph_`service'.gph, replace
			graph save Graph Figures\Figure5_`service'.gph, replace	
		}
		
		foreach service in maldt{
			#delimit;
			graph box `service'_staffguide `service'_equipment `service'_diag `service'_drug ready_`service' , 
				$option legend(off)
				title("Malaria diagnosis and treatment", size(medium))
				;
				#delimit cr
			graph save graph_`service'.gph, replace
			graph save Graph Figures\Figure5_`service'.gph, replace	
		}
		
		foreach service in malipt{
			#delimit;
			graph box `service'_staffguide `service'_equipment `service'_diag `service'_drug ready_`service' , 
				$option legend(off)
				title("Malaria IPTp", size(medium))
				;
				#delimit cr
			graph save graph_`service'.gph, replace
			graph save Graph Figures\Figure5_`service'.gph, replace	
		}

		foreach service in hivct{
			#delimit;
			graph box `service'_staffguide `service'_equipment `service'_diag `service'_drug ready_`service' , 
				$option legend(off)
				title("HIV counseling and testing", size(medium))
				;
				#delimit cr
			graph save graph_`service'.gph, replace
			graph save Graph Figures\Figure5_`service'.gph, replace	
		}

	global graphlist "graph_fp.gph graph_anc.gph graph_del.gph graph_vac.gph graph_child.gph graph_maldt.gph graph_malipt.gph graph_hivct.gph"
	gr combine $graphlist , col(2) xsize(8) ysize(11)
	gr_edit .style.editstyle boxstyle(linestyle(color(black))) editcopy
	graph save Graph Figures\Figure5.gph, replace	
	
graph export graph.png, replace	
putdocx paragraph
putdocx image graph.png	
		
putdocx pagebreak		
putdocx paragraph
putdocx text ("Service readiness by domain: regional variation"), linebreak bold /*Figure 4*/

/*for Figure 4*/	
use Mali_DHS_SARA_Region_2018.dta, replace	
drop if xregion==10

	sort xregion
	global domainlist "staffguide equipment diag drug"
	foreach domain in $domainlist{
		preserve
		collapse (median) fp_`domain' anc_`domain' del_`domain' vac_`domain' child_`domain' maldt_`domain' malipt_`domain' hivct_`domain', 
		egen median=rowmedian(fp_`domain' anc_`domain' del_`domain' vac_`domain' child_`domain' maldt_`domain' malipt_`domain' hivct_`domain')
		egen min=rowmin(fp_`domain' anc_`domain' del_`domain' vac_`domain' child_`domain' maldt_`domain' malipt_`domain' hivct_`domain')
		egen max=rowmax(fp_`domain' anc_`domain' del_`domain' vac_`domain' child_`domain' maldt_`domain' malipt_`domain' hivct_`domain')
		gen range=max-min
		list
		restore
		}
		
use Mali_DHS_SARA_Region_2018.dta, replace	
drop if xregion==10

	sort xregion
	global domainlist "staffguide equipment diag drug"
	foreach domain in $domainlist{
		sum fp_`domain' anc_`domain' del_`domain' vac_`domain' child_`domain' maldt_`domain' malipt_`domain' hivct_`domain', 
		list region fp_`domain' anc_`domain' del_`domain' vac_`domain' child_`domain' maldt_`domain' malipt_`domain' hivct_`domain', 
		}

use Mali_DHS_SARA_Region_2018.dta, replace	
drop if xregion==10
		
	sum ready* 
	drop ready_mal ready_pmtct
	list region ready*
					
	#delimit;
	global option "
	
			box(1, bcolor(navy*0.8))
			box(2, bcolor(cranberry*0.8))
			box(3, bcolor(cranberry*0.5))
			box(4, bcolor(dkgreen*0.8))
			box(5, bcolor(dkgreen*0.5))
			box(6, bcolor(dkorange*0.8))
			box(7, bcolor(dkorange*0.5))
			box(8, bcolor(gray*0.8))
				
			marker(1, mcolor(navy*0.8))
			marker(2, mcolor(cranberry*0.8))
			marker(3, mcolor(cranberry*0.5))
			marker(4, mcolor(dkgreen*0.8))
			marker(5, mcolor(dkgreen*0.5))
			marker(6, mcolor(dkorange*0.8))
			marker(7, mcolor(dkorange*0.5))
			marker(8, mcolor(gray*0.8))
			
			legend(row(1) size(vsmall) stack 
				label(1 "FP")
				label(2 "ANC")
				label(3 "Delivery")
				label(4 "Vaccination")
				label(5 "Child health")
				label(6 "Malaria" "diagnosis &" "treatment")
				label(7 "Malaria" "IPTp")
				label(8 "HIV" "counseling &" "testing") )
				
			ylab (0 (20) 100, angle(0) labsize(small))
			xsize(4) ysize(2.5)	"
		;
		#delimit cr
		
	*global domainlist "staffguide equipment diag drug"
	foreach domain in staffguide{
		#delimit;
		graph box fp_`domain' anc_`domain' del_`domain' vac_`domain' child_`domain' maldt_`domain' malipt_`domain' hivct_`domain', 
			$option
			title("Staff and guideline", size(medium))
			;
			#delimit cr
		gr_edit legend.style.editstyle boxstyle(linestyle(color(white))) editcopy	
		graph save graph_1.gph, replace
		graph save Graph Figures\Figure4_`domain'.gph, replace	
}

foreach domain in equipment{
		#delimit;
		graph box fp_`domain' anc_`domain' del_`domain' vac_`domain' child_`domain' maldt_`domain' malipt_`domain' hivct_`domain', 
			$option
			title("Equipment", size(medium))
			;
			#delimit cr
		gr_edit legend.style.editstyle boxstyle(linestyle(color(white))) editcopy	
		graph save graph_2.gph, replace	
		graph save Graph Figures\Figure4_`domain'.gph, replace	
}

foreach domain in diag{
		#delimit;
		graph box fp_`domain' anc_`domain' del_`domain' vac_`domain' child_`domain' maldt_`domain' malipt_`domain' hivct_`domain', 
			$option
			title("Diagnostics", size(medium))
			;
			#delimit cr
		gr_edit legend.style.editstyle boxstyle(linestyle(color(white))) editcopy	
		graph save graph_3.gph, replace	
		graph save Graph Figures\Figure4_`domain'.gph, replace	
}

foreach domain in drug{
		#delimit;
		graph box fp_`domain' anc_`domain' del_`domain' vac_`domain' child_`domain' maldt_`domain' malipt_`domain' hivct_`domain', 
			$option
			title("Medicine and commodities", size(medium))
			;
			#delimit cr
		gr_edit legend.style.editstyle boxstyle(linestyle(color(white))) editcopy
		graph save graph_4.gph, replace	
		graph save Graph Figures\Figure4_`domain'.gph, replace	
}
	
	global graphlist "graph_1.gph graph_2.gph graph_3.gph graph_4.gph"
	gr combine $graphlist , col(2) xsize(11) ysize(8)
	gr_edit .style.editstyle boxstyle(linestyle(color(black))) editcopy
		
	gr combine graph_1.gph graph_2.gph, col(1) xsize(8) ysize(10)
	gr_edit .style.editstyle boxstyle(linestyle(color(black))) editcopy
	graph save Graph Figures\Figure4_A.gph, replace	
	
graph export graph.png, replace	
putdocx paragraph
putdocx image graph.png	
		
	gr combine graph_3.gph graph_4.gph, col(1) xsize(8) ysize(10)
	gr_edit .style.editstyle boxstyle(linestyle(color(black))) editcopy
	graph save Graph Figures\Figure4_B.gph, replace	
	
graph export graph.png, replace	
putdocx paragraph
putdocx image graph.png	

global graphlist "graph_1.gph graph_2.gph graph_3.gph graph_4.gph"
foreach graph in $graphlist{
	erase `graph'
	}

putdocx pagebreak	
putdocx paragraph		
putdocx text ("ADUSTED Service readiness by element: regional variation"), linebreak bold /*figure 6*/

/*for Figure 6*/	
use Mali_DHS_SARA_Region_2018.dta, replace	
drop if xregion==10

	sum offer* ready* av_ready* access_av_ready*
	sort xregion
	list region offer_hivct

use Mali_DHS_SARA_Region_2018.dta, replace	
drop if xregion==10

	sort xregion
	drop diff_pmtct
	sum diff*
	list region diff*
	
	#delimit; 
	global legend "
			legend(row(2) size(vsmall) order(1 2 3 4) ring(0) stack pos(7)
				label(1 "Availability")	
				label(2 "Readiness")	
				label(3 "Availability" "adjusted for" "readiness")		
				label(4 "Availability" "adjusted for" "readiness and" "facility density") ) "			
			; 
			#delimit cr
	
	#delimit; 
	global option "
			box(1, bcolor(navy*0.8))
			box(2, bcolor(cranberry*0.8))
			box(3, bcolor(navy*0.6))
			box(4, bcolor(navy*0.4))
			marker(1, mcolor(navy*0.8))
			marker(2, mcolor(cranberry*0.8))
			marker(3, mcolor(navy*0.6))
			marker(4, mcolor(navy*0.4))
			ylab (0 (20) 100, angle(0) labsize(small))
			xsize(4) ysize(2.5)"
			; 
			#delimit cr

		foreach service in fp{
			#delimit;
			graph box offer_`service' ready_`service' av_ready_`service' access_av_ready_`service' , 
				$option legend(off)
				title("Family planning", size(medium))
				;
				#delimit cr
			*gr_edit legend.style.editstyle boxstyle(linestyle(color(white))) editcopy
			graph save graph_`service'.gph, replace
			graph save Graph Figures\Figure6_`service'.gph, replace	
		}

		foreach service in anc{
			#delimit;
			graph box offer_`service' ready_`service' av_ready_`service' access_av_ready_`service' , 
				$option legend(off) 
				title("Antenatal care", size(medium))
				;
				#delimit cr
			graph save graph_`service'.gph, replace
			graph save Graph Figures\Figure6_`service'.gph, replace	
		}

		foreach service in del{
			#delimit;
			graph box offer_`service' ready_`service' av_ready_`service' access_av_ready_`service' , 
				$option $legend
				title("Delivery care", size(medium))
				;
				#delimit cr
			graph save graph_`service'.gph, replace
			graph save Graph Figures\Figure6_`service'.gph, replace	
		}

		foreach service in vac{
			#delimit;
			graph box offer_`service' ready_`service' av_ready_`service' access_av_ready_`service' , 
				$option legend(off)
				title("Child vaccination", size(medium))
				;
				#delimit cr
			graph save graph_`service'.gph, replace
			graph save Graph Figures\Figure6_`service'.gph, replace	
		}

		foreach service in child{
			#delimit;
			graph box offer_`service' ready_`service' av_ready_`service' access_av_ready_`service' , 
				$option legend(off)
				title("Child health", size(medium))
				;
				#delimit cr
			graph save graph_`service'.gph, replace
			graph save Graph Figures\Figure6_`service'.gph, replace	
		}
		
		foreach service in maldt{
			#delimit;
			graph box offer_`service' ready_`service' av_ready_`service' access_av_ready_`service' , 
				$option legend(off)
				title("Malaria diagnosis and treatment", size(medium))
				;
				#delimit cr
			graph save graph_`service'.gph, replace
			graph save Graph Figures\Figure6_`service'.gph, replace	
		}
		
		foreach service in malipt{
			#delimit;
			graph box offer_`service' ready_`service' av_ready_`service' access_av_ready_`service' , 
				$option $legend
				title("Malaria IPTp", size(medium))
				;
				#delimit cr
			graph save graph_`service'.gph, replace
			graph save Graph Figures\Figure6_`service'.gph, replace	
		}

		foreach service in hivct{
			#delimit;
			graph box offer_`service' ready_`service' av_ready_`service' access_av_ready_`service' , 
				$option legend(off)
				title("HIV counseling and testing", size(medium))
				;
				#delimit cr
			graph save graph_`service'.gph, replace
			graph save Graph Figures\Figure6_`service'.gph, replace	
		}
		
	global graphlist "graph_fp.gph graph_anc.gph graph_del.gph graph_vac.gph "
	gr combine $graphlist, col(2) xsize(11) ysize(8)
	gr_edit .style.editstyle boxstyle(linestyle(color(black))) editcopy
	graph save Graph Figures\Figure6_A.gph, replace	

graph export graph.png, replace	
putdocx paragraph
putdocx image graph.png	
		
	global graphlist "graph_child.gph graph_maldt.gph graph_malipt.gph graph_hivct.gph"
	gr combine $graphlist, col(2) xsize(11) ysize(8)
	gr_edit .style.editstyle boxstyle(linestyle(color(black))) editcopy
	graph save Graph Figures\Figure6_B.gph, replace	
	
graph export graph.png, replace	
putdocx paragraph
putdocx image graph.png	
				

************************************************************************
* F.1 PART 2: Correlation between utilization and service environment
************************************************************************
				
set scheme s1mono

putdocx pagebreak 
putdocx paragraph
putdocx text ("PART 2: Correlaton between readiness and utilization"), linebreak bold /*figure 7*/
	
use Mali_DHS_SARA_Region_2018.dta, replace	
drop if xregion==10

	global servicelist "fp anc del vac child maldt malipt hivct"	
	foreach service in $servicelist{
		pwcorr dhs_`service' offer_`service', sig 
	}
	
	global servicelist "fp anc del vac child maldt malipt hivct"	
	foreach service in $servicelist{
		pwcorr dhs_`service' av_ready_`service', sig 
	}
	
	global servicelist "fp anc del vac child maldt malipt hivct"	
	foreach service in $servicelist{
		pwcorr dhs_`service' access_av_ready_`service', sig 
	}
	
	
	#delimit;  	
	global option "
				xsize(3) ysize(3) legend(off)
				ytitle("Service utilization (%)" , size(large)) 
				xtitle("Availability, adjusted for readiness" "and relative facility density", size(large))
				ylab(0 (20) 100) xlab(0 (20) 100)  " 			
				;
				#delimit cr
	
	global servicelist "fp anc del vac child maldt malipt hivct pmtct"	
	*global servicelist "child"
	foreach service in $servicelist{
	
		** Utilization & readiness  	
		gen bamako_y 	=dhs_`service' 	 if region=="Bamako"
		gen bamako_x	=offer_`service' if region=="Bamako"
		
		reg dhs_`service' offer_`service'
		local r2: display %5.3f e(r2)		
		local f: display %5.3f e(F)
		corr dhs_`service' offer_`service'
		local coeff: display %5.3f r(rho)
				
		#delimit; 
		twoway 	(scatter dhs_`service' offer_`service', m(o) mc(navy) ) || 
				(scatter bamako_y bamako_x, m(T) mc(cranberry)) || 
				(lfit dhs_`service' offer_`service'), 
			$option
			text( 90 10  
					"correlation coefficient: `coeff'"
					, 
					box just(left) place(se) bc(white) size(large))
			saving(graph1.gph, replace)
			;
			#delimit cr
		drop bamako*

		** Utilization & av_readiness 		
		gen bamako_y 	=dhs_`service' 	 if region=="Bamako"
		gen bamako_x	=av_ready_`service' if region=="Bamako"
		
		reg dhs_`service' av_ready_`service'
		local r2: display %5.3f e(r2)		
		local f: display %5.3f e(F)
		corr dhs_`service' av_ready_`service'
		local coeff: display %5.3f r(rho)
		
		#delimit; 
		twoway 	(scatter dhs_`service' av_ready_`service', m(o) mc(navy)) || 
				(scatter bamako_y bamako_x, m(T) mc(cranberry)) || 
				(lfit dhs_`service' av_ready_`service'),
			$option
			text( 90 10  
					"correlation coefficient: `coeff'"
					, 
					box just(left) place(se) bc(white) size(large))
			saving(graph2.gph, replace)
			;
			#delimit cr
		drop bamako*

		** Utilization & access_av_readiness 		
		gen bamako_y	=dhs_`service' 	 if region=="Bamako"
		gen bamako_x	=access_av_ready_`service' if region=="Bamako"

		reg dhs_`service' access_av_ready_`service'
		local r2: display %5.3f e(r2)		
		local f: display %5.3f e(F)
		corr dhs_`service' access_av_ready_`service'
		local coeff: display %5.3f r(rho)
		
		#delimit; 
		twoway 	(scatter dhs_`service' access_av_ready_`service', m(o)  mc(navy)) || 
				(scatter bamako_y bamako_x, m(T) mc(cranberry)) || 
				(lfit dhs_`service' access_av_ready_`service'), 
			$option
			text( 90 10  
					"correlation coefficient: `coeff'"
					, 
					box just(left) place(se) bc(white) size(large))
			saving(graph3.gph, replace)
			;
			#delimit cr
		drop bamako*

		#delimit;	
		gr combine graph1.gph graph2.gph graph3.gph , 
			row(1) xsize(8) ysize(2.7)
		;
		#delimit cr
		gr_edit .style.editstyle boxstyle(linestyle(color(black))) editcopy
		graph export graph.png, replace	
		graph save Graph Figures\Figure7_`service'.gph, replace	
		
putdocx paragraph
putdocx text ("`service'"), linebreak bold 
putdocx image graph.png	
}			

global graphlist "graph1.gph graph2.gph graph3.gph" 
foreach graph in $graphlist{
	erase `graph'	
	}

************************************************************************
* G. Additional figures for background, methods, and discussion 
************************************************************************

***** SARA sample composision 

set scheme s1mono

putdocx pagebreak
putdocx paragraph
putdocx text ("SARA sample characteristics by region"), linebreak bold 

use Mali_DHS_SARA_Region_2018.dta, clear	
	keep xregion region n_sample nsdp* 
	drop nsdp_hospitals nsdp_clinics nsdp_pub - nsdp_rural
	sort xregion
	browse /*Appendix 1*/
	
use Mali_DHS_SARA_Region_2018.dta, clear	
	drop if xregion==10
	keep xregion region n_sample nn* 
		
		/* FIGURE 1*/
		#delimit;
		graph bar nn*,
			over(xregion) stack percent
			bar(1, color(navy*0.9)) 
			bar(2, color(navy*0.6)) 
			bar(3, color(navy*0.4)) 
			bar(4, color(cranberry*0.9))  
			bar(5, color(cranberry*0.6))  
			bar(6, color(cranberry*0.4)) 
			bar(7, color(green*0.9)) 
			ytitle("Percentage of sampled facilities") 
			legend(pos(3) col(1) size(vsmall) order(8 7 6 5 4 3 2 1) stack
				label(1 "Public tertiary")	
				label(2 "Public secondary")	
				label(3 "Public primary")	
				label(4 "Non-public tertiary")	
				label(5 "Non-public secondary")	
				label(6 "Non-public primary")	
				label(7 "Other")	
				)
			xsize(8) ysize(5)	
		;
		#delimit cr	
		gr_edit .style.editstyle boxstyle(linestyle(color(black))) editcopy
		graph save Graph Figures\Figure1.gph, replace	
		
		graph export graph.png, replace	
		putdocx paragraph
		putdocx image graph.png							

***** Distribution of households vs. facilities by residential area	
		
use Mali_DHS_SARA_Region_2018.dta, clear	
	drop if xregion==10
	keep xregion region nsdp*
	
		#delimit;
		graph bar nsdp_urban nsdp_rural, 
			over(region)  stack percent
			blabel(bar, format(%4.0f) position(inside))
			bar(1, color(navy*0.4)) 
			bar(2, color(cranberry*0.4))  
			legend(pos(3) col(1) size(small) order(2 1) stack
				label(1 "Urban")	
				label(2 "Rural")	
				)
		;
		#delimit cr			
		gr_edit .style.editstyle boxstyle(linestyle(color(black))) editcopy
		
		graph export graph.png, replace	
		putdocx paragraph
		putdocx image graph.png			


use Mali_DHS_SARA_Region_2018.dta, clear	
	drop if xregion==10
	keep xregion region nsdp* xurban n_sample
	
	gen pctsdp_urban = 100*(nsdp_urban/n_sample)
		
		/*FIgure 8*/
		#delimit;
		graph bar xurban pctsdp_urban , 
			over(region, sort(1) descending label(labsize(small)) ) 
			blabel(bar, format(%4.0f))
			ylab(, angle(0) labsize(small))
			ytitle("(%)")
			bar(1, color(navy*0.4)) 
			bar(2, color(cranberry*0.4))  
			legend(pos(6) row(1) size(small) 
				label(1 "Households in" "urban areas")	
				label(2 "Facilities in" "urban areas")	
				)	
				xsize(8) ysize(4)
		;
		#delimit cr		
		gr_edit .style.editstyle boxstyle(linestyle(color(black))) editcopy
		graph save Graph Figures\Figure8.gph, replace	
		
		graph export graph.png, replace	
		putdocx paragraph
		putdocx image graph.png			

***** Facility density 
		
use Mali_DHS_SARA_Region_2018.dta, clear	
	drop if xregion==10
	keep xregion region density_*
		
		/* FIGURE 2*/
		#delimit;
		graph bar density_total , 
			over(region, sort(1) descending label(labsize(small)) ) 
			blabel(bar, format(%4.1f))
			ylab(0(0.5)2.5, angle(0) labsize(small))
			yline(2, lcol(black))
			ytitle("Facility density (per 10,000 population)", size(small))
			bar(1, color(navy*0.4)) 
			legend(off)
			text( 2.15 50 
				"WHO standard for facility density"
				, 
				box just(left) place(se) bc(white) )
		;
		#delimit cr			
		graph save Graph Figures\Figure2.gph, replace

		graph export graph.png, replace	
		putdocx paragraph
		putdocx image graph.png			

***** Illustrative example of service environment measures

use Mali_DHS_SARA_Region_2018.dta, clear		
sum offer* if xregion==10
			
				clear
				set obs 1
				gen xregion = 1 in 1

				gen staff2 = 90
				gen equip2 = 95
				gen diag2 = 70
				gen drug2 = 65
				
				gen bar1	=75 /*availability*/
				egen bar2	=rowmean(staff equip diag drug)
				gen bar3	=bar1 * (bar2/100)
				gen bar4	=bar1 * (bar2/100) * (0.9/2) /*national average*/
				
				reshape long bar staff equip diag drug, i(xregion) j(axis)
					
				foreach x of varlist bar staff equip diag drug{
					replace `x' = int(`x')
					}
				
				/*Figure 3*/
				#delimit;
				graph twoway 
				(bar bar axis if axis==5, barw(0.7) bcolor(cranberry*0.4)) ||
				(bar bar axis if axis==2, barw(0.7) bcolor(navy*0.4)) ||	
				(bar bar axis if axis~=5 & axis~=2, barw(0.7) bcolor(navy*0.7)) ||		
				(scatter bar axis, m(i) mlabel(bar) mlabc(black) mlabp(12) mlabsize(medium medium medium medium)   ) ||	
				(scatter staff equip diag drug axis,  
					m(o d t s) mcolor(blue blue blue blue) 
					xlabel( 
						1 "Availablity" 
						2 "Readiness" 
						3 `" "Availablity," "adjusted for" "readiness" "'
						4 `" "Availablity," "adjusted for" "readiness &" "facility density" "',
						)
					), 
					text(90 2.05 "Staff: 90"
						 95 2.05 "Equipment: 95"
						 70 2.05 "Diagnostic: 70"
						 65 2.05 "Commodity: 65" , 
						box just(left) bc(none) placement(e) color(blue*1.2)  )
					yline(75, lpattern(-) lcolor(black))
					ylab(0(20)100, angle(0) labsize(small)) ytitle("(%)", size(small)) xtitle("") 
					xsize(6) ysize(3.5) legend(off)
					;
					#delimit cr						
					
				gr_edit .style.editstyle boxstyle(linestyle(color(black))) editcopy
				graph save Graph Figures\Figure3.gph, replace

		graph export graph.png, replace	
		putdocx paragraph
		putdocx image graph.png							

erase graph.png				

************************************************************************
* H. Appendix 3: regional sara values by domain  
************************************************************************
	
use Mali_DHS_SARA_Region_2018.dta, replace		

	keep region xregion anc_staffguide - anc_drug  del_staffguide - del_drug  fp_staffguide - ready_pmtct hivct_diag
	keep region xregion fp* anc* del* vac* child* maldt* malipt* hivct*
	drop fp_iud fp_implant
	order region xregion fp* anc* del* vac* child* maldt* malipt* hivct*
	
	sort xregion
	browse

	
END OF DO FILE 	
/*	
************************************************************************
* DISCUSSION: SES and utilization 
************************************************************************

use Mali_DHS_SARA_Region_2018.dta, replace	
	keep xregion region population x*
	sort xregion 
	foreach var of varlist x* {
	format `var' %4.0f
	}	
	replace population=population/1000
	format population %6.0f
	browse /*Table 4*/
	
use Mali_DHS_SARA_Region_2018.dta, replace	
	keep xregion region dhs* xedu* xtop2
	sort xregion 
	browse	
	
	pwcorr dhs* xedu* xtop2, sig
	
	foreach var of varlist dhs* xedu* xtop2 {
	format `var' %4.0f
	}
		
	#delimit;  	
	global option "
				xsize(3) ysize(3) legend(off)
				ytitle("Service utilization (%)" , size(large)) 
				xtitle("Female secondary education (%)", size(large))
				ylab(0 (20) 100) xlab(0 (20) 100)  " 			
				;
				#delimit cr	
	
	global servicelist "fp anc del vac child maldt malipt hivct pmtct"
	*foreach service in fp{
	foreach service in $servicelist{
	
		** Utilization & readiness  	
		gen bamako_y 	=dhs_`service' 	 if region=="Bamako"
		gen bamako_x	=xedusec if region=="Bamako"
		
		reg dhs_`service' xedusec
		local r2: display %5.3f e(r2)		
		local f: display %5.3f e(F)
		corr dhs_`service' xedusec
		local coeff: display %5.3f r(rho)
				
		#delimit; 
		twoway 	(scatter dhs_`service' xedusec, m(o) mc(navy) ) || 
				(scatter bamako_y bamako_x, m(T) mc(cranberry)) || 
				(lfit dhs_`service' xedusec), 
			$option
			text( 90 10  
					"correlation coefficient: `coeff'"
					, 
					box just(left) place(se) bc(white) size(large))
			saving(graph_`service'.gph, replace)
			;
			#delimit cr
		drop bamako*
		graph export graph.png, replace	
		
putdocx paragraph
putdocx text ("`service'"), linebreak bold 
putdocx image graph.png	
	
	}
	
putdocx save Mali_DHS_SARA_Region_$date.docx, replace				
	
	global graphlist "graph_fp.gph graph_anc.gph graph_del.gph graph_vac.gph graph_child.gph graph_maldt.gph graph_malipt.gph graph_hivct.gph"
	gr combine $graphlist, col(3) xsize(11) ysize(11)
	gr_edit .style.editstyle boxstyle(linestyle(color(black))) editcopy /* FIGURE 8*/
	
foreach graph in $graphlist{
	erase `graph'	
	}
	