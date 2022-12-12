**********************************************************************
** This is for Mali DHS-SARA linked analysis: AT THE REGIONAL LEVEL **
**********************************************************************
* 	This do file generates figure in REGION-SPECIFIC APEENDIX: Appendices 4-11 

* Table of Contents 
* 	A. SETTING /*THIS MUST BE CHANGED FOR YOUR SETTING for directories*/
* 	B. Create variables: Run "do Mali_DHS_SARA_Region_LinkedAnalysis.do", which generates the analysis dataset
* 	C. Profile 1. Figure A in each appendix
* 	D. Profile 2. Figure B in each appendix

********************************************************************** END OF INTRODUCTION 

clear
clear matrix
clear mata
capture log close

set more off
set mem 300m
set maxvar 9000
numlabel, add

set scheme s1mono

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
do Mali_DHS_SARA_Region_LinkedAnalysis.do
=> generates "Mali_DHS_SARA_Region_2018.dta"
*/

************************************************************************
* C. Profile 1
************************************************************************

******************************
* GLOBAL setting for graphs
******************************

global regionlist "Kayes Koulikoro Sikasso Ségou Mopti Tombouctou Gao Bamako"
global servicelist "fp anc del vac child maldt malipt hivct"
  
******************************
* create graphs
******************************					

capture putdocx clear 
putdocx begin
		
use Mali_DHS_SARA_Region_2018.dta, clear

	*** create range of regional estimates 
	
	foreach service in $servicelist	{	
	*DHS	
		sum dhs_`service'
		gen min_`service'=r(min) /*lowest regional value*/
		gen max_`service'=r(max) /*highest regional value*/
		
		sum dhs_`service' if xregion==10
		return list
		gen nat_`service'=r(mean) /*national average, NOT average of regional averages*/
		
	*Readiness
		sum ready_`service'
		gen saramin_`service'=r(min) /*lowest regional value*/
		gen saramax_`service'=r(max) /*highest regional value*/
		
		sum ready_`service' if xregion==10
		return list
		gen saranat_`service'=r(mean) /*national average, NOT average of regional averages*/		
}

			gen bar1	=dhs_fp
			gen bar2	=dhs_anc
			gen bar3	=dhs_del
			gen bar4	=dhs_vac
			gen bar5	=dhs_child
			gen bar6	=dhs_maldt
			gen bar7	=dhs_malipt
			gen bar8	=dhs_hivct
					
			gen min1	=min_fp
			gen min2	=min_anc
			gen min3	=min_del
			gen min4	=min_vac
			gen min5	=min_child
			gen min6	=min_maldt
			gen min7	=min_malipt
			gen min8	=min_hivct
					
			gen max1	=max_fp
			gen max2	=max_anc
			gen max3	=max_del
			gen max4	=max_vac
			gen max5	=max_child
			gen max6	=max_maldt
			gen max7	=max_malipt
			gen max8	=max_hivct
			
			gen nat1	=nat_fp
			gen nat2	=nat_anc
			gen nat3	=nat_del
			gen nat4	=nat_vac
			gen nat5	=nat_child
			gen nat6	=nat_maldt
			gen nat7	=nat_malipt
			gen nat8	=nat_hivct
			
			gen sarabar1	=ready_fp
			gen sarabar2	=ready_anc
			gen sarabar3	=ready_del
			gen sarabar4	=ready_vac
			gen sarabar5	=ready_child
			gen sarabar6	=ready_maldt
			gen sarabar7	=ready_malipt
			gen sarabar8	=ready_hivct

			gen saramin1	=saramin_fp
			gen saramin2	=saramin_anc
			gen saramin3	=saramin_del
			gen saramin4	=saramin_vac
			gen saramin5	=saramin_child
			gen saramin6	=saramin_maldt
			gen saramin7	=saramin_malipt
			gen saramin8	=saramin_hivct
					
			gen saramax1	=saramax_fp
			gen saramax2	=saramax_anc
			gen saramax3	=saramax_del
			gen saramax4	=saramax_vac
			gen saramax5	=saramax_child
			gen saramax6	=saramax_maldt
			gen saramax7	=saramax_malipt
			gen saramax8	=saramax_hivct
			
			gen saranat1	=saranat_fp
			gen saranat2	=saranat_anc
			gen saranat3	=saranat_del
			gen saranat4	=saranat_vac
			gen saranat5	=saranat_child
			gen saranat6	=saranat_maldt
			gen saranat7	=saranat_malipt
			gen saranat8	=saranat_hivct
		
foreach region in $regionlist{

	preserve	
	keep if region=="`region'"		

		reshape long bar min max nat sarabar saramin saramax saranat, i(xregion) j(axis)		
		
		format bar %9.0f
		format sarabar %9.0f
		
		#delimit; 
		graph twoway 
			(bar bar axis, 
				barw(0.7) bcolor(cranberry*0.4)) ||
			(scatter bar axis, 
				m(i) mlabel(bar) mlabsize(medium) mlabc(black) mlabp(1) )||
			(rcap min max axis, lcolor(gs4)) ||	
			(scatter nat axis, mcolor(gs4) m(s) ), 
				ylab(0(20)100, angle(0) labsize(small))
				xtitle("") ytitle("(%)", size(small)) legend(off)
				xlabel(
					1 "MCPR"
					2 "ANC4"
					3 `" "Delivery" "at" "facilities" "'
					4 `" "All" "vaccinations" "' 
					5 `" "Child" "diarrhea" "treatment" "'
					6 `" "Malaria" "RDT" "among" "children" "with fever" "'
					7 `" "Malaria" "IPT2" "'
					8 `" "HIV" "counseling" "& testing," "antenatal" "' ,
					labsize(vsmall)) 
				saving(graph_dhs.gph, replace)	
			;
			#delimit cr		
			graph save Graph FiguresAppendix\graph_`region'_A_dhs.gph, replace	
		
		#delimit; 
		graph twoway 
			(bar sarabar axis, 
				barw(0.7) bcolor(navy*0.4)) ||
			(scatter sarabar axis, 
				m(i) mlabel(sarabar) mlabsize(medium) mlabc(black) mlabp(1) )||
			(rcap saramin saramax axis, lcolor(gs4)) ||	
			(scatter saranat axis, mcolor(gs4) m(s) ), 
				ylab(0(20)100, angle(0) labsize(small))
				xtitle("") ytitle("(%)", size(small)) legend(off)
				xlabel(
					1 "FP"
					2 "ANC"
					3 "Delivery"
					4 "Vaccination" 
					5 `" "Child" "curative" "and" "preventive" "'
					6 `" "Malaria" "diagnosis" "and" "treatment" "'
					7 `" "Malaria" "IPT2" "'
					8 `" "HIV" "counseling" "& testing," "' ,
					labsize(vsmall)) 
				saving(graph_sara.gph, replace)	
			;
			#delimit cr					
			graph save Graph FiguresAppendix\graph_`region'_A_sara.gph, replace	
		
		#delimit;	
		gr combine graph_dhs.gph graph_sara.gph , 
			col(2) xsize(8) ysize(6)
			note("Vertical line represents range of 8 regional estimates; square shows the national average."
				, size(small))
		;
		#delimit cr
		gr_edit .style.editstyle boxstyle(linestyle(color(black))) editcopy
		graph save Graph FiguresAppendix\graph_`region'_A.gph, replace	
		
		graph export graph.png, replace	
		
		putdocx paragraph
		putdocx text ("`region'"), linebreak	
		putdocx image graph.png			
	
	restore			
}

putdocx save Mali_DHS_SARA_RegionProfile1_$date.docx, replace	

erase graph.png
erase graph_dhs.gph 
erase graph_sara.gph 

************************************************************************
* D. Profile 2
************************************************************************

******************************
* GLOBAL setting for graphs
******************************

global regionlist "Kayes Koulikoro Sikasso Ségou Mopti Tombouctou Gao Bamako"
global graphlist "graph_fp.gph graph_anc.gph graph_del.gph graph_vac.gph graph_child.gph graph_maldt.gph graph_malipt.gph graph_hivct.gph"
				
#delimit;
global graph "
			graph twoway 
			(bar bar axis if axis==5, barw(0.7) bcolor(cranberry*0.4)) ||
			(bar bar axis if axis==2, barw(0.7) bcolor(navy*0.4)) ||	
			(bar bar axis if axis~=5 & axis~=2, barw(0.7) bcolor(navy*0.7)) ||	
			
			";
			#delimit cr		
			
*global option1 "m(o d t s) mcolor(navy navy navy navy)" 

#delimit;
global label "
			1 "Availablity" 
			2 "Readiness" 
			3 `" "Availablity," "adjusted" "for" "readiness" "'
			4 `" "Availablity," "adjusted" "for" "readiness" "& facility" "density" "',
			labsize(vsmall) 
			";
			#delimit cr						
								
global option2 "ysc(range(0, 110)) ylab(0(20)100, angle(0) labsize(small)) ytitle("(%)", size(small)) xtitle("") xsize(4) ysize(2.5) legend(off)"
							
******************************
* create graphs
******************************					
					
capture putdocx clear 
putdocx begin

*global regionlist "Bamako"	
foreach region in $regionlist{
		
		foreach service in fp{
			
			use Mali_DHS_SARA_Region_2018.dta, clear
			keep if region=="`region'"		
				
				gen bar1	=offer_`service'
				gen bar2	=ready_`service'				
				gen bar3	=av_ready_`service'
				gen bar4	=access_av_ready_`service'
				gen bar5	=dhs_`service'
			
				reshape long bar , i(xregion) j(axis)
					
				format bar %9.0f
				
				#delimit;
				$graph
				(scatter bar axis, 
					m(i) mlabel(bar) mlabsize(small) mlabc(black) mlabp(12)  
					xlabel( 
						5 `" "MCPR" "among all" "women" "' 
						$label )) , 
					$option2
					title("Family planning", size(medium))					
					saving(graph_`service', replace)
						
					;
					#delimit cr						
				graph save Graph FiguresAppendix\graph_`region'_B_`service'.gph, replace	
			}
			
		foreach service in anc{
			
			use Mali_DHS_SARA_Region_2018.dta, replace	
			keep if region=="`region'"		
				
				gen bar1	=offer_`service'
				gen bar2	=ready_`service'
				gen bar3	=av_ready_`service'
				gen bar4	=access_av_ready_`service'
				gen bar5	=dhs_`service'
				
				reshape long bar , i(xregion) j(axis)
					
				format bar %9.0f
						
				#delimit;
				$graph
				(scatter bar axis, 
					m(i) mlabel(bar) mlabsize(small) mlabc(black) mlabp(12)  
					xlabel( 
						5 "ANC4+" 
						$label )) , 
					$option2
					title("Antenatal care", size(medium))					
					saving(graph_`service', replace)	
					;
					#delimit cr						
				graph save Graph FiguresAppendix\graph_`region'_B_`service'.gph, replace	
			}			

		foreach service in del{
			
			use Mali_DHS_SARA_Region_2018.dta, replace	
			keep if region=="`region'"		
			
				gen bar1	=offer_`service'
				gen bar2	=ready_`service'
				gen bar3	=av_ready_`service'
				gen bar4	=access_av_ready_`service'
				gen bar5	=dhs_`service'
				
				reshape long bar , i(xregion) j(axis)
					
				format bar %9.0f
				
				#delimit;
				$graph
				(scatter bar axis, 
					m(i) mlabel(bar) mlabsize(small) mlabc(black) mlabp(12)  
					xlabel( 
						5 `" "Institutional" "Delivery" "' 
						$label )) , 
					$option2
					title("Delivery care", size(medium))					
					saving(graph_`service', replace)
					;
					#delimit cr						
				graph save Graph FiguresAppendix\graph_`region'_B_`service'.gph, replace	
			}			

		foreach service in vac{
			
			use Mali_DHS_SARA_Region_2018.dta, replace	
			keep if region=="`region'"		
				
				gen bar1	=offer_`service'
				gen bar2	=ready_`service'
				gen bar3	=av_ready_`service'
				gen bar4	=access_av_ready_`service'
				gen bar5	=dhs_`service'
				
				reshape long bar , i(xregion) j(axis)
					
				format bar %9.0f
						
				#delimit;
				$graph
				(scatter bar axis, 
					m(i) mlabel(bar) mlabsize(small) mlabc(black) mlabp(12)  
					xlabel( 
						5 `" "All" "vaccinations" "' 
						$label )) , 
					$option2
					title("Child vaccination", size(medium))					
					saving(graph_`service', replace)
					;
					#delimit cr						
				graph save Graph FiguresAppendix\graph_`region'_B_`service'.gph, replace	
			}			
			
		foreach service in child{
			
			use Mali_DHS_SARA_Region_2018.dta, replace	
			keep if region=="`region'"		
				
				gen bar1	=offer_`service'
				gen bar2	=ready_`service'
				gen bar3	=av_ready_`service'
				gen bar4	=access_av_ready_`service'
				gen bar5	=dhs_`service'
				
				reshape long bar , i(xregion) j(axis)
					
				format bar %9.0f
						
				#delimit;
				$graph
				(scatter bar axis, 
					m(i) mlabel(bar) mlabsize(small) mlabc(black) mlabp(12)  
					xlabel( 
						5 `" "Treatment" "of diarrhea" "' 
						$label )) , 
					$option2
					title("Child health", size(medium))					
					saving(graph_`service', replace)
					;
					#delimit cr				
				graph save Graph FiguresAppendix\graph_`region'_B_`service'.gph, replace	
			}		
			
		foreach service in maldt{
			
			use Mali_DHS_SARA_Region_2018.dta, replace	
			keep if region=="`region'"		
				
				gen bar1	=offer_`service'
				gen bar2	=ready_`service'
				gen bar3	=av_ready_`service'
				gen bar4	=access_av_ready_`service'
				gen bar5	=dhs_`service'
				
				reshape long bar , i(xregion) j(axis)
					
				format bar %9.0f
						
				#delimit;
				$graph
				(scatter bar axis, 
					m(i) mlabel(bar) mlabsize(small) mlabc(black) mlabp(12)  
					xlabel(
						5 `" "RDT" "among" "children" "with fever" "' 
						$label )) , 
					$option2
					title("Malaria diagnosis and treatment", size(medium))					
					saving(graph_`service', replace)
					;
					#delimit cr						
				graph save Graph FiguresAppendix\graph_`region'_B_`service'.gph, replace	
			}					
			
		foreach service in malipt{
			
			use Mali_DHS_SARA_Region_2018.dta, replace	
			keep if region=="`region'"		
			
				gen bar1	=offer_`service'
				gen bar2	=ready_`service'
				gen bar3	=av_ready_`service'
				gen bar4	=access_av_ready_`service'
				gen bar5	=dhs_`service'
				
				reshape long bar , i(xregion) j(axis)
					
				format bar %9.0f
						
				#delimit;
				$graph
				(scatter bar axis, 
					m(i) mlabel(bar) mlabsize(small) mlabc(black) mlabp(12)  
					xlabel(
						5 `" "IPT2" "' 
						$label )) , 
					$option2
					title("Malaria IPTp", size(medium))					
					saving(graph_`service', replace)
					;
					#delimit cr						
				graph save Graph FiguresAppendix\graph_`region'_B_`service'.gph, replace	
			}		
			
		foreach service in hivct{
			
			use Mali_DHS_SARA_Region_2018.dta, replace	
			keep if region=="`region'"		
				
				gen bar1	=offer_`service'
				gen bar2	=ready_`service'
				gen bar3	=av_ready_`service'
				gen bar4	=access_av_ready_`service'
				gen bar5	=dhs_`service'
				
				reshape long bar , i(xregion) j(axis)
					
				format bar %9.0f
					
				#delimit;
				$graph
				(scatter bar axis, 
					m(i) mlabel(bar) mlabsize(small) mlabc(black) mlabp(12)  
					xlabel(
						5 `" "HIV" "counseling" "& testing" "during" "pregnancy"' 
						$label )) , 
					$option2
					title("HIV counseling and testing", size(medium))					
					saving(graph_`service', replace)
					;
					#delimit cr						
				graph save Graph FiguresAppendix\graph_`region'_B_`service'.gph, replace	
			}		

		gr combine $graphlist , col(2) xsize(8) ysize(11)

		gr_edit .style.editstyle boxstyle(linestyle(color(black))) editcopy
		graph save Graph FiguresAppendix\graph_`region'_B.gph, replace
		
		graph export graph.png, replace	
				
		putdocx paragraph
		putdocx text ("`region'"), linebreak	
		putdocx image graph.png		

	}

putdocx save Mali_DHS_SARA_RegionProfile2_$date.docx, replace	

foreach graph in $graphlist {
	erase `graph'
	}

OKAY STOP HERE
