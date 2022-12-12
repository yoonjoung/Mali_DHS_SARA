# Mali_DHS_SARA
*Availability, Readiness, and Utilization of Services in Mali*
See full report https://dhsprogram.com/pubs/pdf/FA136/FA136.pdf

Data source: 
1. Excel file which has extracted service readiness estimates from a report. *THIS IS INCLUDED IN THE REPO*    
2. SARA facility-level dataset to for background characterisitcs of facilities at the regional level   
2. DHS API indicator data   
3. DHS IR and HR public data for background characterisitcs of population at the regional level   

Stata do files:  
1. API_Mali_DHS.do => this generates "API_Mali_DHS.dta"
2. SARA_tables.do => this generates "SARA_tables.dta"
3. Mali_DHS_SARA_LinkedAnalysis_prep.do => this generates "IR_Mali_2018_LinkedAnalysis.dta". It will be used for Section C.1 and C.2  
4. Mali_DHS_SARA_LinkedAnalysis.do: THIS IS THE MAIN DO FILE FOR THE REPORT
5. Mali_DHS_SARA_RegionProfile.do => this creates appendix figures 