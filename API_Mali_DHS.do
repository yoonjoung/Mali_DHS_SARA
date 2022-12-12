* This is for Mali DHS API indicators 
* Investigate of source of care for the six outcomes
*•	Use of modern contraception
*•	Percent of births in last five years receiving at least 4 ANC visits
*•	Percent of children 12-23 receiving BCG vaccination
*•	Prevalence of moderate-to-severe stunting among children under five
*•	Percent of women 15-49 with a birth in the last 2 years receiving SP/Fansidar 2+ doses, at least one during ANC visit (IPTp)
*•	Percent of children under five with fever who took any ACT
* Code from the GitHub https://github.com/DHSProgram/DHS-Indicators-Stata 

clear
clear matrix
clear mata
set more off
set mem 300m
set maxvar 9000

************************************************************************
* A. SETTING 
************************************************************************

cd "C:\Users\YoonJoung Choi\Dropbox\0 iSquared\iSquared_DHS\Mali_DHS_SARA\"

local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)


*******************************************************************
* 1. DEFINE DHS indicators: 
	/*
	http://api.dhsprogram.com/rest/dhs/indicators?returnFields=IndicatorId,Label,Definition&f=html
	*/
	/*
	FP_CUSA_W_MOD	33202001	Current use of any modern method of contraception (all women)	Percentage of women currently using any modern method of contraception
	RH_ANCN_W_N4P	75265003	Antenatal visits for pregnancy: 4+ visits	Percentage of women who had a live birth in the five (or three) years preceding the survey who had 4+ antenatal care visits
	RH_DELP_C_DHF	77282000	Place of delivery: Health facility	Percentage of live births in the five (or three) years preceding the survey delivered at a health facility
	
	CH_VACS_C_BAS	81272010	Received all 8 basic vaccinations	Percentage of children 12-23 months who had received all 8 basic vaccinations	
	CH_VACS_C_BCG	81272001	BCG vaccination received	Percentage of children 12-23 months who had received BCG vaccination	Child Health	Vaccinations by source of information	Children	93836010	1	Children age 12-23 [18-29] months	Percent	I	BCG	32	0	 	CHVACSCBCG	CH_VACS_C_NUM	CH_VACS_C_UNW	 	 	 
	CH_VACS_C_DP3	81272004	DPT 3 vaccination received	Percentage of children 12-23 months who had received DPT 3 vaccination	Child Health	Vaccinations by source of information	Children	93836040	1	Children age 12-23 [18-29] months	Percent	I	DPT 3	32, 80	0	 	CHVACSCDP3	CH_VACS_C_NUM	CH_VACS_C_UNW	 	 	 
	CH_VACS_C_OP3	81272008	Polio 3 vaccination received	Percentage of children 12-23 months who had received Polio 3 vaccination	Child Health	Vaccinations by source of information	Children	93836080	1	Children age 12-23 [18-29] months	Percent	I	Polio 3	32	0	 	CHVACSCOP3	CH_VACS_C_NUM	CH_VACS_C_UNW	 	 	 
	CH_VACS_C_MSL	81272009	Measles vaccination received	Percentage of children 12-23 months who had received Measles vaccination	Child Health	Vaccinations by source of information	Children	93836090	1	Children age 12-23 [18-29] months	Percent	I	Measles	32, 1	0	 	CHVACSCMSL	CH_VACS_C_NUM	CH_VACS_C_UNW	 	 	 

	CH_DIAT_C_ORS	87277001	Treatment of diarrhea: Oral rehydration solution (ORS)	Percentage of children born in the five (or three) years preceding the survey with diarrhea in the two weeks preceding the survey who received oral rehydration solution (ORS), that is either fluid from an ORS packet or a pre-packaged ORS fluid	
	CH_DIAT_C_ADV	Treatment of diarrhea: Taken to a health facility	Percentage of children born in the five (or three) years preceding the survey with diarrhea in the two weeks preceding the survey who were taken for a treatment to a healthy facility
	CH_DIAT_C_ORT	Treatment of diarrhea: Either ORS or RHF	Percentage of children born in the five (or three) years preceding the survey with diarrhea in the two weeks preceding the survey who received either oral rehydration solution (ORS) or recommended home fluids (RHF)
	CH_DIAT_C_ZNC	Treatment of diarrhea: Zinc supplements	Percentage of children born in the five (or three) years preceding the survey with diarrhea in the two weeks preceding the survey who received zinc supplements
	
	ML_IPTP_W_2SP	210499002	SP/Fansidar 2+ doses during pregnancy	Percentage of women age 15-49 with a live birth in the two years preceding the survey who during the pregnancy took two or more doses of SP/Fansidar
	ML_FEVT_C_BLD	 	Children with fever who had blood taken from a finger or heel for testing	Among children under age five with fever in the two weeks preceding the survey, the percentage who had blood taken from a finger or heel for testing
	ML_FEVT_C_ADV	 	Children with fever for whom advice or treatment was sought	Among children under age five with fever in the two weeks preceding the survey, the percentage for whom advice or treatment was sought	Malaria	Diagnosis and treatment of children with fever	Children	124966010	1	Children under age five with fever in the two weeks preceding the survey	Percent	I	Children for whom advice or treatment was sought	77, 5, 7, 79	0	 	MLFEVTCADV	ML_FEVT_C_NUM	ML_FEVT_C_UNW	 	 	 
	ML_FEVT_C_ACT	212495005	Children with fever who took a combination with artemisinin	Among children under age five with fever in the two weeks preceding the survey, the percentage who took a combination with artemisinin	Malaria	Diagnosis and treatment of children with fever	Children	124966040	1	Children under age five with fever in the two weeks preceding the survey	Percent	I	Children who took any ACT	5, 7	0	 	MLFEVTCACT	ML_FEVT_C_NUM	ML_FEVT_C_UNW	 	 	 
	
	HA_CATH_W_CSL	1113002002	Pregnant women counselled for HIV during ANC visit	Percentage of women who were counselled for HIV during antenatal visit for the most recent birth, of all women who gave birth in the two years preceding the survey
	HA_CATH_W_CTR	 	Pregnant women counselled for HIV and tested for HIV during ANC and who received the results	Percentage of women who received counselling for HIV and an HIV test and received the results during antenatal care for the most recent birth, of all women who gave birth in the two years preceding the survey

	*/	
		
#delimit;
global indicatorlist " 	
	FP_CUSA_W_MOD
	FP_CUSM_W_MOD
	FP_NADA_W_PDM
	FP_NADM_W_PDM
	
	RH_ANCN_W_N4P
	RH_DELP_C_DHF
	
	CH_VACS_C_BAS
	CH_VACS_C_BCG
	CH_VACS_C_DP3
	CH_VACS_C_OP3
	CH_VACS_C_MSL
	
	CH_DIAT_C_ADV
	CH_DIAT_C_ORS
	CH_DIAT_C_ORT
	CH_DIAT_C_ZNC	
	
	ML_IPTP_W_2SP
	ML_FEVT_C_BLD
	ML_FEVT_C_ADV
	ML_FEVT_C_ACT
	
	HA_CATH_W_CSL
	HA_CATH_W_CTR

	";
	#delimit cr		

#delimit;
global indicatorlist_minusone " 
	
	FP_CUSM_W_MOD
	FP_NADA_W_PDM
	FP_NADM_W_PDM
	
	RH_ANCN_W_N4P
	RH_DELP_C_DHF
	
	CH_VACS_C_BAS
	CH_VACS_C_BCG
	CH_VACS_C_DP3
	CH_VACS_C_OP3
	CH_VACS_C_MSL
	
	CH_DIAT_C_ADV
	CH_DIAT_C_ORS
	CH_DIAT_C_ORT	
	CH_DIAT_C_ZNC	
	
	ML_IPTP_W_2SP
	ML_FEVT_C_BLD
	ML_FEVT_C_ADV
	ML_FEVT_C_ACT

	HA_CATH_W_CSL
	HA_CATH_W_CTR
	";
	#delimit cr			

*******************************************************************	
* 2. CALL API data for each indicator, save each, and merge	

foreach indicator in $indicatorlist{

	clear
	insheetjson using "http://api.dhsprogram.com/rest/dhs/data?indicatorIds=`indicator'&countryids=ML&breakdown=all&APIkey=USAAID-113824", 

		gen str9  surveyid=""
		gen str30 country=""	
		gen str20 group=""
		gen str20 grouplabel=""
		gen str5  value=""	
		gen str10  numWeighted=""	
		gen str10  numUnweighted=""	

	#delimit; 	
	insheetjson surveyid country group grouplabel value numWeighted numUnweighted 
	using  "http://api.dhsprogram.com/rest/dhs/data?indicatorIds=`indicator'&countryids=ML&breakdown=all&APIkey=USAAID-113824", 
	table(Data) 
	col(SurveyId CountryName CharacteristicCategory CharacteristicLabel Value DenominatorWeighted DenominatorUnweighted);	
	#delimit cr
			
		destring value, replace	
		drop if value==.
		rename value `indicator'
		
		destring numWeighted, replace	
		rename numWeighted nw_`indicator'
		
		destring numUnweighted, replace
		rename numUnweighted nuw_`indicator'
		
		sort surveyid group grouplabel
			egen temp=group(surveyid group grouplabel)
			codebook temp
			sort temp
			drop if temp==temp[_n-1]
			drop temp
	
	replace group ="Total" if group=="Total 15-49"
	replace grouplabel ="Total" if grouplabel=="Total 15-49"
	
	sort surveyid group grouplabel
	save API_`indicator'.dta, replace	
	
	}

*******************************************************************	
* 3. merge API indicator data	

	foreach indicator in $indicatorlist{	
	 	use API_`indicator'.dta,
		tab group surveyid , m 
	}


use API_FP_CUSA_W_MOD.dta, clear	
	sort surveyid group grouplabel
	
	foreach indicator in $indicatorlist_minusone{	
	 
		merge surveyid group grouplabel using API_`indicator'	
			codebook _merge* 
			drop _merge*	
			
		sort surveyid group grouplabel
	}
	
*******************************************************************	
* 4. gen basic variables 	

	gen year=substr(surveyid,3,4)  
		destring year, replace	
		label var year "year of survey"
			
	gen type=substr(surveyid,7,3) 	
		label var type "type of survey"
		tab year type, m
			
	gen grouplabelnum=.
		replace grouplabelnum=17 if group=="Age (5-year groups)" & grouplabel=="15-19" 
		replace grouplabelnum=22 if group=="Age (5-year groups)" & grouplabel=="20-24" 
		replace grouplabelnum=27 if group=="Age (5-year groups)" & grouplabel=="25-29" 
		replace grouplabelnum=32 if group=="Age (5-year groups)" & grouplabel=="30-34" 
		replace grouplabelnum=37 if group=="Age (5-year groups)" & grouplabel=="35-39"
		replace grouplabelnum=42 if group=="Age (5-year groups)" & grouplabel=="40-44" 
		replace grouplabelnum=47 if group=="Age (5-year groups)" & grouplabel=="45-49"		 								
	
		replace grouplabelnum=101 if group=="Wealth quintile" & grouplabel=="Lowest"
		replace grouplabelnum=102 if group=="Wealth quintile" & grouplabel=="Second"
		replace grouplabelnum=103 if group=="Wealth quintile" & grouplabel=="Middle"
		replace grouplabelnum=104 if group=="Wealth quintile" & grouplabel=="Fourth"
		replace grouplabelnum=105 if group=="Wealth quintile" & grouplabel=="Highest" 

		replace grouplabelnum=201 if group=="Education" & grouplabel=="No education"
		replace grouplabelnum=202 if group=="Education" & grouplabel=="Primary"
		replace grouplabelnum=203 if group=="Education" & grouplabel=="Secondary"
		replace grouplabelnum=204 if group=="Education" & grouplabel=="Higher"
			
		replace grouplabelnum=301 if group=="Education (2 groups)" & grouplabel=="No education or prim"
		replace grouplabelnum=302 if group=="Education (2 groups)" & grouplabel=="Secondary or higher"

		replace grouplabelnum=401 if group=="Residence" & grouplabel=="Rural"
		replace grouplabelnum=402 if group=="Residence" & grouplabel=="Urban"
		
		replace grouplabelnum=0 if group=="Total" & grouplabel=="Total"
	
	#delimit;
	lab define grouplabelnum
		0"Total"
		17"15-19" 22"20-24" 27"25-29" 32"30-34" 37"35-39" 42"40-44" 47"45-49" 
		101"Lowest" 102"Second" 103"Middle" 104"Fourth" 105"Highest"
		201"None" 202"Primary" 203"Secondary" 204"Higher"
		301"No education or primary" 302"Secondary or higher"
		401"Rural" 402"Urban"
		;
		#delimit cr
	lab values grouplabelnum grouplabelnum		

*******************************************************************	
* 5. rename API variables and SAVE

	lab var FP_CUSA_W_MOD	"Percentage of women currently using any modern method of contraception"
	lab var FP_CUSM_W_MOD	"Percentage of women in union currently using any modern method of contraception"
	lab var FP_NADA_W_PDM "met demand with modern methods, among all women"
	lab var FP_NADM_W_PDM "met demand with modern methods, among married women"
	
	lab var RH_ANCN_W_N4P	"Percentage of women who had a live birth in the five (or three) years preceding the survey who had 4+ antenatal care visits"
	lab var RH_DELP_C_DHF	"Percentage of live births in the five (or three) years preceding the survey delivered at a health facility"
	
	lab var CH_VACS_C_BAS	"Percentage of children 12-23 months who had received all 8 basic vaccinations"
	lab var CH_VACS_C_BCG	"Percentage of children 12-23 months who had received BCG vaccination"
	lab var CH_VACS_C_DP3	"Percentage of children 12-23 months who had received DPT 3 vaccination"
	lab var CH_VACS_C_OP3	"Percentage of children 12-23 months who had received Polio 3 vaccination"
	lab var CH_VACS_C_MSL	"Percentage of children 12-23 months who had received Measles vaccination"
	lab var CH_DIAT_C_ORS	"Percentage of children born in the five (or three) years preceding the survey with diarrhea in the two weeks preceding the survey who received oral rehydration solution (ORS), that is either fluid from an ORS packet or a pre-packaged ORS fluid"	
	lab var CH_DIAT_C_ORT	"Percentage of children born in the five (or three) years preceding the survey with diarrhea in the two weeks preceding the survey who received either oral rehydration solution (ORS) or recommended home fluids (RHF)"
	lab var CH_DIAT_C_ADV	"Percentage of children born in the five (or three) years preceding the survey with diarrhea in the two weeks preceding the survey who were taken for a treatment to a healthy facility"
	lab var CH_DIAT_C_ZNC	"Percentage of children born in the five (or three) years preceding the survey with diarrhea in the two weeks preceding the survey who received zinc supplements"
	
	lab var ML_IPTP_W_2SP	"Percentage of women age 15-49 with a live birth in the two years preceding the survey who during the pregnancy took two or more doses of SP/Fansidar"
	lab var ML_FEVT_C_BLD	"Among children under age five with fever in the two weeks preceding the survey, the percentage who had blood taken from a finger or heel for testing"
	lab var ML_FEVT_C_ADV 	"Among children under age five with fever in the two weeks preceding the survey, the percentage for whom advice or treatment was sought"
	lab var ML_FEVT_C_ACT 	"Among children under age five with fever in the two weeks preceding the survey, the percentage who took a combination with artemisinin"
	lab var HA_CATH_W_CSL	"Percentage of women who were counselled for HIV during antenatal visit for the most recent birth, of all women who gave birth in the two years preceding the survey"
	lab var HA_CATH_W_CTR	"Percentage of women who received counselling AND received the results during antenatal care for the most recent birth, of all women who gave birth in the two years preceding the survey"
	
	rename FP_CUSA_W_MOD mcpr_all
	rename FP_CUSM_W_MOD mcpr_married
	rename FP_NADA_W_PDM mdm_all
	rename FP_NADM_W_PDM mdm_married
	
	rename RH_ANCN_W_N4P preg_anc4
	rename RH_DELP_C_DHF del_fac
	
	rename CH_VACS_C_BAS vac_basic
	rename CH_VACS_C_BCG vac_bcg
	rename CH_VACS_C_DP3 vac_dpt3
	rename CH_VACS_C_OP3 vac_polio4
	rename CH_VACS_C_MSL vac_measles
	rename CH_DIAT_C_ORS dia_ors
	rename CH_DIAT_C_ADV dia_adv
	rename CH_DIAT_C_ORT dia_ort 	
	rename CH_DIAT_C_ZNC dia_zinc

	rename ML_IPTP_W_2SP preg_iptp2
	rename ML_FEVT_C_BLD fev_test
	rename ML_FEVT_C_ADV fev_consult	
	rename ML_FEVT_C_ACT fev_act
	
	rename HA_CATH_W_CSL preg_counseling
	rename HA_CATH_W_CTR preg_cnt
		
	tab group, m
		tab surveyid group if group=="District" | group=="Regions (states)", m
		replace group="Region" if group=="District"
		replace group="Region" if group=="Regions (states)"		
	bysort group: tab grouplabel, m
		
	/*
	tab group var, m
	tab var varlabel, m
	bysort varlabel: sum mcpr* cpr* unmet*
	drop var varlabel
	*/	

keep if type=="DHS"	
*keep if group=="Region" | group=="Total"	
	
	tab grouplabel surveyid, m

	replace grouplabel ="Gao" 		if grouplabel=="....Gao"
	replace grouplabel ="Kidal" 	if grouplabel=="....Kidal"
	replace grouplabel ="Tombouctou" if grouplabel=="....Tombouctou"
	replace grouplabel ="Kayes"		if grouplabel=="..Kayes"
	replace grouplabel ="Koulikoro"	if grouplabel=="..Koulikoro"
	
	replace grouplabel ="Mopti"		if grouplabel=="..Mopti"
	replace grouplabel ="Sikasso"	if grouplabel=="..Sikasso"
	replace grouplabel ="Ségou"		if grouplabel=="..Ségou"
	
	tab grouplabel surveyid, m	
	
	sort surveyid group grouplabel 	
	save API_Mali_DHS.dta, replace 

	foreach indicator in $indicatorlist{		 
		erase API_`indicator'.dta
	}		
	
	
*End of do file: Good job API data downloaded	
*******************************************************************	

