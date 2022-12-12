* This is to generate more detailed and systematic SARA regional-level datasets 
* the following tables from the final report was used 
* across EIGHT areas
*		Tableau I: Calculation of the sample size of health care facilities				
*		Tableau II: Sample by region and type of care facility								
*		Table III: Density of health care facilities by region in 2016					
*		Tableau IV: Inpatient bed density by region in 2016				
*		Tableau VI: Service Availability Index by Region									
*		Tableau XIV: Overall operational capacity of services, by region, type of institution and managing authority, (N=484), Mali SARA, 2018								
*		Tableau XV: Availability of health facilities offering family planning services by region, type of facility, jurisdiction, and setting (N=432)														
*		Tableau  XVI:  Availability of family planning-related markers among health facilities offering this service, by region (N=432)											
*		Tableau XVII: Percentage of Facilities Offering Prenatal Care Services by Region (N=484)							
*		Tableau   XVIII:   Availability of Prenatal Tracers Among Health Facilities Offering Prenatal Care by Region (N=430)						
*		Tableau XIX: Availability of basic obstetric care																						
*		Table XX: Availability of tracers for basic obstetric care among health facilities offering delivery services, by region (N=415)					
*		Tableau XXI: Percentage of facilities offering comprehensive maternity care services, by region (N=103)				
*		Tableau XXIV a: Percentage of facilities offering child immunization services, by region (N=484)									
*		Tableau XXV b: Percentage of facilities offering child immunization services, by region (N=484)					
*		Tableau XXVI a: Availability of child immunization markers among health facilities offering this service, by region (N=328)											
*		Tableau XXVII b : Availability of child immunization markers among health facilities offering this service, by region (N=328)												
*		Tableau XXVIII: Percentage of Facilities Offering Preventive and Curative Care Services for Children by Region (N=484)										
*		Tableau XXIX a: Availability of markers for preventive and curative child care among health facilities offering this service, by region (N=422)											
*		Tableau XXX b: Availability of markers for preventive and curative child care among health facilities offering this service, by region (N=422)														
*		Tableau XXXIV : Distribution of facilities offering malaria treatment services, by region, type, and managing authority, (N=484), Mali SARA, 2018									
*		Tableau XXXV Availability of tracer elements for malaria prevention and treatment among facilities offering this service, by region, type and managing authority (N=462), Mali SARA, 2018. To be inserted												
*		Tableau XXXIX : Availability of HIV/AIDS counselling and testing services		
*		Tableau XL : Distribution of availability of tracers for HIV counselling and testing services in facilities offering the service, by region, type and managing authority (N =249), Mali SARA2018									Tableau XLV : distribution of facilities offering PMTCT services, by Region, type and managing authority (N =484), Mali SARA, 2018									Tableau XLVI : Distribution of availability of tracer elements for PMTCT services in facilities offering the service, according to region, type of facility and managing authority (N=258), Mali SARA, 2018	

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

************************************************************************
* B. IMPORT and clean, clean, and again clean
************************************************************************

import excel SARA_tables.xlsx, sheet("SAR (2)") firstrow

	keep region n_* population density_* hr* gr_* offer_* fp_* anc_* del_* vac_* child_* mal_* ipt_* hivct_* pmtct*
	drop if region==""
	codebook region
	
	* Sample size 
	
			lab var 	n_sample	"number of facilities, sampled"	
			lab var 	n_samplingframe	"number of all faciliities in the sampling frame"	
			lab var 	n_samplerequired	"numner of facilities required for sampling?"	

	* General readiness among all facilities 		
			lab var 	gr_comfrt	"general readiness:	comfort	"
			lab var 	gr_equipment	"general readiness:	equiqpment	"
			lab var 	gr_infection	"general readiness:	infection control	"
			lab var 	gr_diag	"general readiness:	diagnostic capacity	"
			lab var 	gr_drug	"general readiness:	drugs	"
			lab var 	gr_index	"general readiness:	index	"

	* Service-specific availability 				
		
		rename offer_malaria offer_mal
		gen offer_maldt  = offer_mal
		gen offer_malipt = offer_mal	
		
			lab var 	offer_fp	"percent of all facilities offering FP	"
			lab var 	offer_anc	"percent of all facilities offering ANC	"
			lab var 	offer_del	"percent of all facilities offering delivery	"
			lab var 	offer_vac	"percent of all facilities offering childhood vaccination	"
			lab var 	offer_child	"percent of all facilities offering child health services	"
			lab var 	offer_mal	"percent of all facilities offering malaria	"
			lab var 	offer_maldt	"percent of all facilities offering malaria	"
			lab var 	offer_malipt "percent of all facilities offering malaria	"
			lab var 	offer_hivct	"percent of all facilities offering HIV counseling and testing	"
			lab var 	offer_pmtct	"percent of all facilities offering PMTCT	"

	* denominator: missing for delivery  		
	
		lookfor n_
		
		gen n_del=round(n_sample * offer_delivery /100, 0)
		rename n_malaria n_mal
		gen n_maldt = n_mal
		gen n_malipt= n_mal
		
			lab var 	n_fp	"number of facilities offering FP"	
			lab var 	n_anc	"number of facilities offering ANC"	
			lab var 	n_del	"number of facilities offering delivery services"	
			lab var 	n_vac	"number of facilities offering childhood vaccination"	
			lab var 	n_child	"number of facilities offering childhood preventive/curative care"	
			lab var 	n_mal	"number of facilities offering malaria care"	
			lab var 	n_hivct	"number of facilities offering HIV vounseling and testing" 		
			lab var 	n_pmtct	"number of facilities offering PMTCT" 	

	* STAFF: available in all, but too detail in PMTCT  	
		
		egen fp_staffguide = rowmean(fp_guideline fp_aids fp_staff)
		egen vac_staffguide = rowmean(vac_guideline vac_staff)
		egen child_staffguide = rowmean(child_guideline	child_guidelinenut	child_staff	child_staffnut)
		egen mal_staffguide = rowmean(mal_guideline	ipt_guideline	mal_staff	ipt_staff)
		egen maldt_staffguide = rowmean(mal_guideline	mal_staff)
		egen malipt_staffguide = rowmean(ipt_guideline	ipt_staff)
		egen hivct_staffguide = rowmean(hivct_guideline hivct_staff)
		egen pmtct_staffguide = rowmean(pmtct_staff pmtct_feeding_staff pmtct_guideline pmtct_feeding_guideline)
			
			lab var 	fp_staffguide	"Among FP facilities, % with trained staff & guidelines (*average of 3)"		 
			lab var 	anc_staffguide	"Among ANC facilities, % with trained staff & guidelines"
			lab var 	del_staffguide	"Among delivery facilities, % with trained staff & guidelines"
			lab var 	vac_staffguide	"Among child vaccination facilities, % with trained staff & guidelines (*average of 2)"
			lab var 	child_staffguide "Among child health facilities, % with IMCI trained staff (*average of 4)"		
			lab var 	mal_staffguide	"Among malaria facilities, % with trained staff & guidelines (*average of 4)"				
			lab var 	maldt_staffguide "Among malaria facilities, % with trained staff & guidelines for malaria diagnosis/treatment (*average of 2)"				
			lab var 	malipt_staffguide"Among malaria facilities, % with trained staff & guidelines for IPT (*average of 2)"
			lab var 	hivct_staffguide "Among HIV counseling/testing facilities, % with trained staff & guidelines (*average of 2)"
			lab var 	pmtct_staffguide "Among PMTCT facilities, % with trained staff & guidelines (*average of 4)"

	* DIAGNOSTIC capacity 
		
		lookfor diag
		
		egen child_diag = rowmean(child_hg child_parasite child_maldiag)
		gen maldt_diag	=mal_diag
		gen malipt_diag	=mal_diag
		egen pmtct_diag = rowmean(pmtct_diagadult  pmtct_diagnewborn)
		
			lab var 	anc_diag	"Among ANC facilities, % with diagnostic capacity"
			lab var 	child_diag	"Among child health facilities, % with diagnostic capacity (*average of 3)"
			lab var 	mal_diag	"Among malaria facilities, % with diagnostic capacity for malaria diagnosis/treatment"		
			lab var 	maldt_diag	"Among malaria facilities, % with diagnostic capacity for malaria diagnosis/treatment"		
			lab var 	malipt_diag	"Among malaria facilities, % with diagnostic capacity for malaria diagnosis/treatment"					
			lab var 	hivct_diag	"Among HIV counseling/testing facilities, % with diagnostic capacity"
			lab var 	pmtct_diag	"Among PMTCT facilities, % with diagnostic capacity (*average of 2)"
			
	* EQUIPMENT 
	
		lookfor equipment 

		egen fp_equipment 	=rowmean(fp_bp)
		egen vac_equipment 	=rowmean(vac_holderbag	vac_ref	vac_sharp	vac_syringe	vac_tempmonitor	vac_temp	vac_cards	vac_sheet)	
		egen child_equipment=rowmean(child_scale	child_length	child_thermometer	child_stethoscope	child_shakir)
		gen hivct_equipment = hivct_room
		gen pmtct_equipment = pmtct_room
		
			lab var 	fp_equipment 	"Among FP facilities, % with essential equipment (*only BP)"		
			lab var 	anc_equipment "Among ANC facilities, % with essential equipment"
			lab var 	del_equipment "Among delivery facilities, % with essential equipment"
			lab var 	vac_equipment "Among child vaccination facilities, % with essential equipment (*average of 8)"
			lab var 	child_equipment "Among child health facilities, % with essential equipment (*average of 5)"
			lab var 	hivct_equipment	"Among HIV counseling/testing facilities, % with essential equipment (*only room)"
			lab var 	pmtct_equipment	"Among PMTCT facilities, % with essential equipment (*only room)"	
	
	* DRUGS/Commodities
	
	lookfor drug		
	
		gen fp_iud		=100*offer_fp_iud/offer_fp
		gen fp_implant	=100*offer_fp_implant/offer_fp	
		
		egen fp_drug 	=rowmean(fp_pillcomb fp_pillprog fp_inj fp_mcondom fp_implant fp_iud)
		egen vac_drug 	=rowmean(vac_measles  vac_dpt	 vac_poliooral  vac_bcg	 vac_rotavirus	vac_pnemococcal	 vac_polioipv  vac_meningococcala)
		egen child_drug =rowmean(child_ors	child_amox	child_cotrim	child_paracetamol	child_vita	child_mealbendazole	child_zinc)
		egen mal_drug 	=rowmean(mal_antimalarials	mal_paracetamol	ipt_drug	ipt_itn)
		egen maldt_drug =rowmean(mal_antimalarials	mal_paracetamol	)
		egen malipt_drug=rowmean(ipt_drug	ipt_itn)		
		gen hivct_drug	=hivct_condom
		egen pmtct_drug =rowmean(pmtct_zidovudine pmtct_nevirapine pmtct_arvmaternal)
		
			lab var 	fp_drug	"Among FP facilities, % with essential meds (*average of 6)"		
			lab var 	anc_drug	"Among ANC facilities, % with essential meds"
			lab var 	del_drug	"Among delivery facilities, % with essential meds"
			lab var 	vac_drug	"Among child vaccination facilities, % with essential meds (*average of 8)"
			lab var 	child_drug	"Among child health facilities, % with essential meds (*average of 7)" 
			lab var 	mal_drug	"Among malaria facilities, % with essential meds (*average of 4) "				
			lab var 	maldt_drug	"Among malaria facilities, % with essential meds for malaria diagnosis/treatment (*average of 2)"				
			lab var 	malipt_drug	"Among malaria facilities, % with essential meds for IPT (*average of 2)"
			lab var 	hivct_drug	"Among malaria facilities, % with essential meds (*ONLY Condom)"
			lab var 	pmtct_drug	"Among PMTCT facilities, % with essential meds (*average of 3)"

	* WEIGHTED readiness
	*		BEFORE THEN, generate dummy variables for missing elements
	
			gen fp_diag =.
			
			gen del_diag =.

			gen vac_diag =.
			
			gen mal_equipment =.
			gen maldt_equipment=.
			gen malipt_equipment =. 


		global services "fp anc del vac child mal maldt malipt hivct pmtct"
		foreach service in $services{
		egen ready_`service'=rowmean(`service'_staffguide `service'_equipment `service'_diag `service'_drug)
		}
				
	* Availability-adjusted readiness

		foreach service in $services{
		gen av_ready_`service'	 	 = 	ready_`service'	* (	offer_`service'	 / 100)  
		}
		
	* Density-Availability-adjusted readiness

		foreach service in $services{
		gen access_av_ready_`service'	 	 = 	av_ready_`service'	* (	density_score /100)
		}	
		
	* Density-Availability-adjusted readiness

		foreach service in $services{
		gen access2_av_ready_`service'	 	 = 	access_av_ready_`service'	* (	hr_score /100)
		}	

foreach x of varlist gr_* offer_* fp* anc* del* vac* child* mal* ipt* hivct* pmtct*{
	format `x'	%9.0f	
	}
	
foreach x of varlist ready* av_ready* access*{
	format `x'	%9.0f	
	}	
	
sum ready* av_ready* access*		
		
save SARA_tables.dta, replace

*OKAY END OF DO FILE	
