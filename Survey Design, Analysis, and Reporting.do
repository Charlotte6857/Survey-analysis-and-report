/*************************************************************************
Created by: Chuck Huber
Created on: 16jul2021
Last modified: 16jul2021
Modified by: Chuck Huber
Project: GPH-GU 2397 Survey Design, Analysis, and Reporting
Analysis: Lecture 4 Examples
Data Source: https://wwwn.cdc.gov/nchs/nhanes/continuousnhanes/default.aspx?BeginYear=2015
*****************************************************************************/

version 17
clear all
capture cd "$GoogleDriveWork"
capture cd "$GoogleDriveLaptop"
capture cd "$LinuxDriveWork"
capture cd "$Presentations"
capture cd "$GoogleDriveNYU"
cd ".\OldClassNotes\NYU_SurveySampling\Fall2021\Lectures\Lecture04\examples\"

capture log close
log using Lecture04, replace

// Define global macros for graph dimensions
global Width16x9  = 1920*2
global Height16x9 = 1080*2
global Width4x3   = 1440*2
global Height4x3  = 1080*2
// set the graph scheme 
set scheme s1color
// Define the local macro "GraphNum" so that graphs are numbered sequentially
local GraphNum = 1

// Delete all .png files from the "graphs" folder
shell erase .\graphs\*.png /Q
// Define the local macro "GraphNum" so that graphs are numbered sequentially
local GraphNum = 1

use NHANES2015.dta, clear

describe psu strata wt_interview wt_mec wt_fasting wt_diet 
       
notes psu
notes strata
notes wt_interview
notes wt_mec
notes wt_fasting
notes wt_diet       
       
// svyset command for MEC (lab) data
svyset psu, strata(strata)       ///
            weight(wt_mec)       ///
            vce(linearized)      /// 
            singleunit(missing)
            
// svyset command for diet data
svyset psu, strata(strata)       ///
            weight(wt_diet)      ///
            vce(linearized)      /// 
            singleunit(missing)            
  
// svyset command for fasting lab data
svyset psu, strata(strata)       ///
            weight(wt_fasting)   ///
            vce(linearized)      /// 
            singleunit(missing)    
  
// svyset command for interview data
svyset psu, strata(strata)       ///
            weight(wt_interview) ///
            vce(linearized)      /// 
            singleunit(missing)            


            
// =============================================================================
// /\/\/\/\/\/\/\/\/\/\/\/\      LINEAR REGRESSION        /\/\/\/\/\/\/\/\/\/\/\
// =============================================================================            

// svyset command for MEC (lab) data
svyset psu, weight(wt_mec) strata(strata) vce(linearized) singleunit(missing)  

// SAMPLE MEAN
// =============================================================================
svy: mean sbp
svy: regress sbp



// BINARY PREDICTOR
// =============================================================================
svy: mean sbp, over(female) cformat(%9.2f)
svy: mean sbp, over(female) cformat(%9.2f) coeflegend
test   _b[c.sbp@0bn.female] = _b[c.sbp@1.female]
lincom _b[c.sbp@0bn.female] - _b[c.sbp@1.female]


svy: regress sbp female
svy: regress sbp female, coeflegend
test _b[female] = 0

svy: regress sbp i.female
svy: regress sbp i.female, coeflegend
test _b[1.female] = 0


lincom _b[0.female] - _b[1.female]

list female i.female in 1/10

margins female, vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_LinearFemale.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum             
marginsplot, recast(bar) plotopts(barw(.8))
graph export ./graphs/`GraphNum'_LinearFemaleBar.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum


// CATEGORICAL PREDICTOR
// =============================================================================

// Compare to reference category
svy: mean sbp, over(race) cformat(%9.2f)
svy: mean sbp, over(race) cformat(%9.2f) coeflegend
test (_b[c.sbp@1bn.race] = _b[c.sbp@2.race])  ///
     (_b[c.sbp@1bn.race] = _b[c.sbp@3.race])  ///
     (_b[c.sbp@1bn.race] = _b[c.sbp@4.race])  ///
     (_b[c.sbp@1bn.race] = _b[c.sbp@5.race])


list race i.race in 1/15

contrast race
     
svy: regress sbp i.race
// Note that this version of -test- is equivalent to a likelihood ratio test
test (_b[1bn.race] = _b[2.race])  ///
     (_b[1bn.race] = _b[3.race])  ///
     (_b[1bn.race] = _b[4.race])  ///
     (_b[1bn.race] = _b[5.race])

     
// Compare all means to zero
svy: mean sbp, over(race) cformat(%9.2f) coeflegend
test (_b[c.sbp@1bn.race] = 0)  ///
     (_b[c.sbp@2.race]   = 0)  ///
     (_b[c.sbp@3.race]   = 0)  ///
     (_b[c.sbp@4.race]   = 0)  ///
     (_b[c.sbp@5.race]   = 0)

svy: regress sbp bn.race, noconstant coeflegend
test (_b[1bn.race] = 0)  ///
     (_b[2.race]   = 0)  ///
     (_b[3.race]   = 0)  ///
     (_b[4.race]   = 0)  ///
     (_b[5.race]   = 0)
     
svy: regress sbp i.race
     
// Marginal predictions
margins race, vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_LinearRace.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum

marginsplot, recast(bar) plotopts(barw(.8)) 
graph export ./graphs/`GraphNum'_LinearRaceBar.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  

marginsplot, recast(scatter) horizontal    ///
             plotregion(margin(t=10 b=10)) ///
             ytitle("")
graph export ./graphs/`GraphNum'_LinearRace.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

 
// Contrasts
svy: regress sbp i.race
contrast r.race, noeffect
matrix list r(L)
contrast {race -1 1 0 0 0}  ///
         {race -1 0 1 0 0}  ///
         {race -1 0 0 1 0}  ///
         {race -1 0 0 0 1}  ///
         , noeffects
        

contrast g.race, noeffects
contrast g.race, mcompare(scheffe) noeffects
contrast g.race, mcompare(scheffe) nowald

// Contrasts of marginal predictions
margins g.race, contrast mcompare(scheffe)
margins g.race, contrast(nowald effects) mcompare(scheffe)
marginsplot
graph export ./graphs/`GraphNum'_LinearRaceContrast.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  
marginsplot, recast(scatter) horizontal xline(0)
graph export ./graphs/`GraphNum'_LinearRaceContrast.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 
marginsplot, recast(scatter) horizontal    ///
             xline(0) xlabel(-6(2)6)       ///
             ytitle("")                    ///
             plotregion(margin(t=10 b=10))
graph export ./graphs/`GraphNum'_LinearRaceContrast.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

// Pairwise comparisons
pwcompare race
pwcompare race, mcompare(bonferroni)

// Pairwise comparisons of marginal predictions
margins race, mcompare(bonferroni) pwcompare
marginsplot
graph export ./graphs/`GraphNum'_LinearRacePwcompare.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 
marginsplot, xdimension(_pw) yline(0)
graph export ./graphs/`GraphNum'_LinearRacePwcompare.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

marginsplot, recast(scatter) horizontal    ///
             xdimension(_pw) xline(0)      ///
             plotregion(margin(t=5 b=5))   ///
             unique
graph export ./graphs/`GraphNum'_LinearRacePwcompare.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 
     

// CONINUOUS PREDICTOR
// =============================================================================
svy: regress sbp age
test age=0

margins, at(age==(20(10)80)) vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_LinearAge.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 








// INTERACTIONS BETWEEN BINARY AND CONTINUOUS PREDICTORS
// ============================================================================= 
svy: regress sbp i.female c.age i.female#c.age
svy: regress sbp i.female##c.age
margins female, at(age==(20(10)80)) vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_LinearAgeFemale.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum   



// INTERACTIONS BETWEEN CATEGORICAL AND CONTINUOUS PREDICTORS
// =============================================================================      
svy: regress sbp i.race##c.age
svy: regress sbp i.race##c.age, coeflegend
// TEST THE MAIN EFFECT OF race USING -test-
test (_b[1bn.race] = _b[2.race])  ///
     (_b[1bn.race] = _b[3.race])  ///
     (_b[1bn.race] = _b[4.race])  ///
     (_b[1bn.race] = _b[5.race])

// TEST THE MAIN EFFECT OF race USING -contrast-     
contrast r.race, noeffects     

// TEST THE INTERACTION OF age AND race USING -test-
test (_b[1.race#c.age]=_b[2.race#c.age])  ///
     (_b[1.race#c.age]=_b[3.race#c.age])  ///
     (_b[1.race#c.age]=_b[4.race#c.age])  ///
     (_b[1.race#c.age]=_b[5.race#c.age])

     
svy: regress sbp i.race##c.age     
     
// TEST THE INTERACTION OF age AND race USING -contrast-     
contrast r.race#c.age, noeffects  


margins race, at(age==(20(10)80)) vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_LinearAgeRace.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 
marginsplot, recast(line) noci ///
             plotopts(lwidth(thick))
graph export ./graphs/`GraphNum'_LinearAgeRace.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum              







// INTERACTIONS BETWEEN CATEGORICAL PREDICTORS
// =============================================================================     
svy: regress sbp i.female i.race i.female#i.race
svy: regress sbp i.female##i.race


svy: regress sbp i.female##i.race, coeflegend

// TEST THE MAIN EFFECT OF race
test (_b[1bn.race] = _b[2.race])  ///
     (_b[1bn.race] = _b[3.race])  ///
     (_b[1bn.race] = _b[4.race])  ///
     (_b[1bn.race] = _b[5.race])
     
// TEST THE MAIN EFFECT OF race USING -contrast-     
contrast r.race, noeffects      

// TEST THE INTERACTION OF female AND race
test (_b[1.female#1.race]=_b[1.female#2.race])  ///
     (_b[1.female#1.race]=_b[1.female#3.race])  ///
     (_b[1.female#1.race]=_b[1.female#4.race])  ///
     (_b[1.female#1.race]=_b[1.female#5.race])

     
svy: regress sbp i.female##i.race     
     
// TEST THE INTERACTION OF female AND race USING -contrast-     
contrast r.female#r.race, noeffects       
     
svy: regress sbp i.female##i.race
margins female#race,  vce(unconditional)
// Default
marginsplot
graph export ./graphs/`GraphNum'_LinearFemaleRace.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 
// Bar chart 
marginsplot, recast(bar)
graph export ./graphs/`GraphNum'_LinearFemaleRace.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  

// Vertical scatterplot (yuck!)
marginsplot, recast(scatter)                   ///
             xdimension(female race)           ///
             xlabel(,labsize(small) alternate) ///
             xscale(range(0.5 6.5))
graph export ./graphs/`GraphNum'_LinearFemaleRace.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

// Horizontal scatterplot (female race)            
marginsplot, recast(scatter)           ///
             horizontal                ///
             xdimension(female race)   ///
             xlabel(,labsize(small))   ///
             ytitle("")
graph export ./graphs/`GraphNum'_LinearFemaleRace.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

// Horizontal scatterplot (race female)             
marginsplot, recast(scatter)                ///
             horizontal                     ///
             xdimension(race female)        ///
             xlabel(,labsize(small))        ///
             xtitle("Predicted SBP (mmHg)") ///
             ytitle("")                     ///
             title("Predicted SBP by Race and Sex")
graph export ./graphs/`GraphNum'_LinearFemaleRace.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum

 
   
     
     
// INTERACTIONS BETWEEN TWO CONTINUOUS PREDICTORS
// =============================================================================     
clear all
frame create nhanes
frame change nhanes
use NHANES2015.dta, clear
// svyset command for MEC (lab) data
svyset psu, weight(wt_interview) strata(strata) vce(linearized) singleunit(missing) 

svy: regress sbp c.age##c.bmi

quietly margins, vce(unconditional)           /// 
                 at(age=(20(5)80)             ///
                    bmi=(15(5)60))            ///
                 saving(predictions, replace)

frame create predictions

frame change predictions

use predictions, clear

describe _at1 _at2 _margin

list _at1 _at2 _margin in 1/8, sep(0)
rename _at1 age
rename _at2 bmi
rename _margin pr_sbp
list age bmi pr_sbp in 1/8, sep(0)


twoway (contour pr_sbp bmi age, ccuts(100(4)140)),                ///	
	   xlabel(20(10)80)                                           ///
	   ylabel(15(5)60, angle(horizontal))                         ///
	   xtitle("Age (years)", margin(small))                       ///
	   ytitle("Body Mass Index", margin(large))                   ///
	   ztitle("Predicted SBP (mmHg)")                             ///
	   title("Predicted Systolic Blood Pressure by Age and BMI")

graph export ./graphs/`GraphNum'_LinearInteractAgeBmi.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  



     
// VARIABLE SELECTION
// =============================================================================      
clear all
frame create nhanes
frame change nhanes
use NHANES2015.dta, clear
// svyset command for MEC (lab) data
svyset psu, weight(wt_interview) strata(strata) vce(linearized) singleunit(missing)      
     
svy: regress sbp age
margins, at(age==(20(10)80)) vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_LinearAge.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum      
    
svy: regress sbp c.age##i.female c.age##c.bmi i.female##i.race

contrast r.race, noeffects  
margins race, contrast
marginsplot, recast(scatter) horizontal xline(0)      ///
             plotregion(margin(t=10 b=10)) ytitle("")
graph export ./graphs/`GraphNum'_LinearAdjRaceContrast.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

contrast r.race#r.female, noeffects  
margins race#female, contrast
marginsplot, recast(scatter) horizontal xline(0)        ///
             plotregion(margin(t=10 b=10)) ytitle("")
graph export ./graphs/`GraphNum'_LinearAdjSexContrast.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

gen black = (race==4 & !missing(race))
label define black 0 "Non Black" 1 "Black"
label values black black
label var black "Black"
svy: regress sbp c.age##i.female c.age#c.bmi i.black#c.age

// Line plot for age and female adjusted for bmi and black
margins female, at(age==(20(10)80)) vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_LinearAdjSexAge.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum   

// Lineplot for age and black adjusted for bmi and sex
margins black, at(age==(20(10)80)) vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_LinearAdjBlackAge.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

// Contour plot for age#bmi adjusted for female and black
quietly margins, vce(unconditional)           /// 
                 at(age=(20(5)80)             ///
                    bmi=(15(5)60))            ///
                 saving(predictions, replace)

frame create predictions
frame change predictions
use predictions, clear

describe _margin _at1 _at2 _at3 _at4

list _margin _at1 _at2 _at3 _at4 in 1/8, sep(0)
rename _at1 age
rename _at3 bmi
rename _margin pr_sbp
list age bmi pr_sbp in 1/8
summ pr_sbp


twoway (contour pr_sbp bmi age, ccuts(110(4)150)),                ///	
	   xlabel(20(10)80)                                           ///
	   ylabel(15(5)60, angle(horizontal))                         ///
	   xtitle("Age (years)", margin(small))                       ///
	   ytitle("Body Mass Index", margin(large))                   ///
	   ztitle("Predicted SBP (mmHg)")                             ///
	   title("Predicted Systolic Blood Pressure by Age and BMI")  ///
       subtitle("Adjusted for Sex and Race")
graph export ./graphs/`GraphNum'_LinearAdjAgeBmi.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

             
// Contour plot for age#bmi by female adjusted for black             
frame change nhanes             
quietly margins female, vce(unconditional)           /// 
                        at(age=(20(5)80)             ///
                           bmi=(15(5)60))            ///
                        saving(predictions, replace)

frame change predictions
use predictions, clear

describe _margin _m1 _at1 _at2 _at3 _at4

list _margin _m1 _at1 _at2 _at3 _at4 in 1/8, sep(0)
rename _m1  female
rename _at1 age
rename _at3 bmi
rename _margin pr_sbp
list female age bmi pr_sbp in 1/8
summ pr_sbp


twoway (contour pr_sbp bmi age, ccuts(110(4)150)),                   ///	
	   xlabel(20(10)80)                                              ///
	   ylabel(15(5)60, angle(horizontal))                            ///
	   xtitle("Age (years)", margin(small))                          ///
	   ytitle("Body Mass Index", margin(small))                      ///
	   ztitle("Predicted SBP (mmHg)")                                ///
	   by(female, cols(2)                                            ///
          title("Predicted Systolic Blood Pressure by Age and BMI")  ///
          subtitle("Adjusted for Race"))
graph export ./graphs/`GraphNum'_LinearAdjAgeBmiSex.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum            
             
             
// Contour plot for age#bmi by female adjusted for black             
frame change nhanes             
quietly margins female#black, vce(unconditional)           /// 
                              at(age=(20(5)80)             ///
                                 bmi=(15(5)60))            ///
                              saving(predictions, replace)

frame change predictions
use predictions, clear

describe _margin _m1 _m2 _at1 _at2 _at3 _at4

list _margin _m1 _at1 _at2 _at3 _at4 in 1/8, sep(0)
rename _m1  female
rename _m2  black
rename _at1 age
rename _at3 bmi
rename _margin pr_sbp
list female black age bmi pr_sbp in 1/8
summ pr_sbp


twoway (contour pr_sbp bmi age, ccuts(110(4)150)),       ///	
	   xlabel(20(10)80)                                  ///
	   ylabel(15(10)60, angle(horizontal))               ///
       xtitle("Age (years)", margin(small))              ///
	   ytitle("Body Mass Index", margin(small))          ///
	   ztitle("Predicted SBP (mmHg)")                    ///
	   by(black female, cols(2)                          ///
          title("Predicted Systolic Blood Pressure")     ///
          subtitle("by Age, BMI, Female, and Black") )
graph export ./graphs/`GraphNum'_LinearAdjAgeBmiSexBlack.png, as(png)           ///
             width($Width4x3) height($Height4x3) replace
local ++GraphNum    
             
 


// COMPARE "ADJUSTED" AND "UNADJUSTED" MODELS
// ============================================================================= 
frame change nhanes

// Fit the unadjusted model and save the marginal predictions
svy: regress sbp c.age
quietly margins, vce(unconditional)           /// 
                 at(age=(20(5)80))            ///
                 saving(predictions_unadj, replace)

// Fit the adjusted model and save the marginal predictions                 
svy: regress sbp c.age##i.female c.age#c.bmi i.black#c.age
quietly margins, vce(unconditional)           /// 
                 at(age=(20(5)80))            ///
                 saving(predictions_adj, replace)
                 
frame create unadj
frame create adj
frame change unadj
use predictions_unadj
rename _at1 age
rename _margin pr_sbp_unadj

frame change adj
use predictions_adj
rename _at1 age
rename _margin pr_sbp_adj

frlink 1:1 age, frame(unadj)
frget pr_sbp_unadj, from(unadj)

list age pr_sbp_unadj pr_sbp_adj, abbrev(12) sep(0)


twoway (line pr_sbp_unadj age, lwidth(thick))            ///
       (line pr_sbp_adj age, lwidth(thick)),             ///
       ytitle(Predicted Systolic Blood Pressure (mmHg))  ///
       ylabel(, angle(horizontal))                       ///
       xlabel(20(10)80)                                  ///
       title(Predicted Systolic Blood Pressure by Age)   ///
       subtitle(Unadjusted and Adjusted* Models)         ///
       note("*Adjusted for Sex, Race, and BMI")          ///
       legend(order(1 "Unadjusted" 2 "Adjusted")         ///
              cols(1) position(11) ring(0))
graph export ./graphs/`GraphNum'_LinearAdjUnadjust.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum   

                 

    

// CHECKING MODEL ASSUMPTIONS
// =============================================================================
frame change nhanes


// Fit the final model
svy: regress sbp c.age##i.female c.age#c.bmi i.black#c.age

// Create a variable for the predicted residuals
predict residuals, residuals

// Create a variable for the linear prediction (xb)
predict xb, xb

// Check the normality of the residuals
histogram residuals, normal   normopts(lcolor(green)  lwidth(thick))  ///
                     kdensity kdenopts(lcolor(orange) lwidth(thick))
graph export ./graphs/`GraphNum'_LinearResidHistogram.png, as(png)    ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum   

// Create a residuals-by-fitted plot
twoway (scatter residuals xb, msize(small)), yline(0)
graph export ./graphs/`GraphNum'_LinearResidScatterXB.png, as(png)   ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

 
// Create a residuals-by-age plot
twoway (scatter residuals age, msize(small)), yline(0)
graph export ./graphs/`GraphNum'_LinearResidScatterAge.png, as(png)   ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  
 
// Create a residuals-by-bmi plot
twoway (scatter residuals bmi, msize(small)), yline(0)
graph export ./graphs/`GraphNum'_LinearResidScatterBmi.png, as(png)   ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum   

// Create a residuals-by-female Box plot  
graph hbox residuals, over(female)
graph export ./graphs/`GraphNum'_LinearResidBoxFemale.png, as(png)      ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum

// Create a residuals-by-black Box plot                
graph hbox residuals, over(black) 
graph export ./graphs/`GraphNum'_LinearResidBoxBlack.png, as(png)      ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum               
 
drop residuals xb






// =============================================================================
// /\/\/\/\/\/\/\/\      MULTIVARIATE MODELS WITH gsem       \/\/\/\/\/\/\/\/\/\
// =============================================================================


clear all
frame create nhanes
frame change nhanes
use NHANES2015.dta, clear
// svyset command for MEC (lab) data
svyset psu, weight(wt_interview) strata(strata) vce(linearized) singleunit(missing)      
 
svy: gsem (sbp <- c.age##i.female) ///
          (dbp <- c.age##i.female) ///
          , cov(e.sbp*e.dbp)
          
contrast c.age#r.female, overall atequations noeffects        

margins female, at(age==(20(10)80)) vce(unconditional)
marginsplot, title("Predicted SBP and DBP by Age and Sex", margin(medium)) /// 
             ytitle("Predicted SBP and DBP", margin(medium))               ///  
             ylabel(, angle(horizontal))                                   ///        
             legend(order(2 "SBP,Male" 4 "SBP, Female"                     ///
                          1 "DBP,Male"  3 "DBP,Female" )                   ///
              rows(1) position(12) ring(1) size(vsmall))
                
graph export ./graphs/`GraphNum'_Gsem_SbpDbp_AgeFemale.png, as(png)      ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 





// =============================================================================
// /\/\/\/\/\/\/\/\      LOG-TRANSFORMATIONS WITH gsem       \/\/\/\/\/\/\/\/\/\
// =============================================================================

gen wt_trig = round(wt_fasting, 1.0)
histogram triglyceride [fweight = wt_trig], normal
graph export ./graphs/`GraphNum'_LinearLnTrig_Histogram1.png, as(png)      ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

gen ln_trig = ln(triglyceride)
histogram ln_trig [fweight = wt_trig], normal
graph export ./graphs/`GraphNum'_LinearLnTrig_Histogram2.png, as(png)      ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

svy: regress ln_trig c.age##i.female i.race
margins female,  at(age=(20(10)80))  
marginsplot, title("Predicted Log-Triglycerides by Age and Sex", margin(medium)) /// 
             ytitle("Predicted Log-Triglycerides", margin(medium)) 
graph export ./graphs/`GraphNum'_LinearLnTrig_AgeFemale.png, as(png)      ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

svy: gsem ln_trig <- c.age##i.female i.race
svy: gsem ln_trig <- c.age##i.female i.race, coeflegend

margins female,  at(age=(20(10)80))                                 ///
        expression(exp(predict(eta))*(exp((_b[/var(e.ln_trig)])/2))) 
marginsplot, title("Predicted Triglycerides by Age and Sex")           ///
             subtitle("Adjusted for Race")                             ///
             ytitle("Predicted Triglycerides (mg/dL)", margin(medium)) ///  
             ylabel(, angle(horizontal))                               ///
             legend(cols(1) position(10) ring(0) size(medium))
graph export ./graphs/`GraphNum'_Gsem_LnTrig_AgeFemale.png, as(png)      ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum         
         
drop ln_trig



// =============================================================================
// /\/\/\/\/\/\/\/\/\/\/\      LOGISTIC REGRESSION        /\/\/\/\/\/\/\/\/\/\/\
// ============================================================================= 
// svyset command for interview data
frame change nhanes
svyset psu, weight(wt_interview) strata(strata) vce(linearized) singleunit(missing) 

// svy: proportion diabetes, over(female) cformat(%9.4f)
// svy: proportion diabetes, over(female) cformat(%9.4f) coeflegend
// test   _b[1.diabetes@0bn.female] = _b[1.diabetes@1.female]
// lincom _b[1.diabetes@0bn.female] - _b[1.diabetes@1.female]

svy: tabulate diabetes, count obs format(%19.0fc)


// Binary predictor
// =================
svy: logistic diabetes i.female

margins female, vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_LogisticFemale.png, as(png)      ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

marginsplot, recast(bar) plotopts(barw(.8))
graph export ./graphs/`GraphNum'_LogisticFemaleBar.png, as(png)      ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 


// Categorical predictor
// =====================
svy: logistic diabetes i.race

contrast r.race, noeffects

margins race, vce(unconditional)
marginsplot, recast(scatter) horizontal plotregion(margin(t=10 b=10))
graph export ./graphs/`GraphNum'_LogisticRace.png, as(png)      ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 


// Continuous predictor
// ====================
svy: logistic diabetes age
margins, at(age=(20(10)80)) vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_LogisticAge.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum



// Interaction of a categorical predictor and a continuous predictor
// =================================================================
svy: logistic diabetes c.age##i.female

margins female, at(age==(20(10)80)) vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_LogisticAgeFemale.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum

svy: logistic diabetes c.age##i.race

// Test the main effect of race
contrast r.race, noeffects 
// Test the interaction of female and race
contrast c.age#r.race, noeffects 

margins race, at(age==(20(10)80)) vce(unconditional)
marginsplot, legend(cols(1) size(medium) position(11) ring(0)) ///
                      ylabel(0(0.1)0.7, angle(horizontal))
                      
graph export ./graphs/`GraphNum'_LogisticAgeRace.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum




// Interaction of two categorical predictors
// =========================================
svy: logistic diabetes i.female##i.race

// Test the main effect of race
contrast r.race, noeffects 
// Test the interaction of female and race
contrast r.female#r.race, noeffects 

// Horizontal scatterplot (race female)  
margins female#race, vce(unconditional)
marginsplot, recast(scatter)                ///
             horizontal                     ///
             xdimension(race female)        ///
             xlabel(,labsize(small))        ///
             ytitle("")                     ///
             plotregion(margin(t=5 b=5))
graph export ./graphs/`GraphNum'_LogisticFemaleRace.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum





// INTERACTIONS BETWEEN TWO CONTINUOUS PREDICTORS
// =============================================================================     
frame change nhanes
svyset psu, weight(wt_interview) strata(strata) vce(linearized) singleunit(missing) 

svy: logistic diabetes c.age##c.bmi

quietly margins, vce(unconditional)           /// 
                 at(age=(20(5)80)             ///
                    bmi=(15(5)60))            ///
                 saving(predictions, replace)

frame create predictions
frame change predictions
use predictions, clear

describe _at1 _at2 _margin
list _at1 _at2 _margin in 1/8, sep(0)
rename _at1 age
rename _at2 bmi
rename _margin pr_diabetes
list age bmi pr_diabetes in 1/8

twoway (contour pr_diabetes bmi age, ccuts(0.0(0.1)1.0)),         ///	
	   xlabel(20(10)80)                                           ///
	   ylabel(15(5)60, angle(horizontal))                         ///
	   xtitle("Age (years)", margin(small))                       ///
	   ytitle("Body Mass Index", margin(medium))                  ///
	   ztitle("Predicted Pr(Diabetes)")                           ///
	   title("Predicted Pr(Diabetes by Age and BMI")

graph export ./graphs/`GraphNum'_LogisticInteractAgeBmi.png, as(png)    ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  









// =============================================================================
// /\/\/\/\/\/\/\/\/\      ORDINAL LOGISTIC REGRESSION        /\/\/\/\/\/\/\/\/\
// ============================================================================= 
// svyset command for interview data
frame change nhanes
svyset psu, weight(wt_interview) strata(strata) vce(linearized) singleunit(missing) 

svy: proportion healthstat, over(female) cformat(%9.4f)

svy: tabulate healthstat, count obs format(%19.0fc)


svy: ologit healthstat c.age##i.female i.race 

margins, vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_Ologit.png, as(png)    ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  

marginsplot, recast(bar) plotopts(barw(.8))                                 ///
             title("Probability of Health Status Categories")               ///
             xtitle(Health Status, margin(medsmall))                        ///
             xlabel(1 "Excellent" 2 "Very Good" 3 "Good" 4 "Fair" 5 "Poor") ///
             ytitle("Probability of Health Status Category")                ///
             ylabel(, angle(horizontal))
graph export ./graphs/`GraphNum'_Ologit.png, as(png)    ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum               


margins race, vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_OlogitRace.png, as(png)    ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  

marginsplot, recast(scatter) horizontal plotregion(margin(t=5 b=5)) ///
             title("Probability of Health Status Category by Race") ///
             xtitle("Probability of Health Status Category")        ///
             ytitle("")                                             ///
             ylabel(, labsize(small))                               ///
             legend(order(1 "Excellent"                             /// 
                          2 "Very Good"                             ///
                          3 "Good"                                  ///  
                          4 "Fair"                                  ///
                          5 "Poor")                                 /// 
                    rows(1) size(vsmall)  position(12))
graph export ./graphs/`GraphNum'_OlogitRace.png, as(png)    ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  


margins, at(age==(20(10)80)) vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_OlogitAge.png, as(png)    ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  

marginsplot, title("Predicted Probability of Health Status Category Over Age") ///
             ytitle("Predicted Probability of Health Status Category"          ///
                    , margin(medium))                                          ///
             ylabel(0(0.1)0.5, labsize(small) angle(horizontal))               ///
             legend(order(1 "Excellent"                                        /// 
                          2 "Very Good"                                        ///
                          3 "Good"                                             ///  
                          4 "Fair"                                             ///
                          5 "Poor")                                            /// 
                    rows(1) size(small)  position(12))
graph export ./graphs/`GraphNum'_OlogitAge.png, as(png)    ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  

margins female, at(age==(20(10)80)) vce(unconditional) predict(outcome(1))
marginsplot, title("Predicted Probability of 'Excellent' Health Status")  ///
             subtitle("by Age and Sex")                                   ///
             ytitle("Predicted Probability of 'Excellent' Health Status") ///
             ylabel(0.0(0.05)0.2, angle(horizontal))                      ///
             legend(rows(1) size(small)  position(1) ring(0))
graph export ./graphs/`GraphNum'_OlogitAgeSex_Excellent.png, as(png)    ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  

margins female, at(age==(20(10)80)) vce(unconditional) predict(outcome(5))
marginsplot, title("Predicted Probability of 'Poor' Health Status")  ///
             subtitle("by Age and Sex")                              ///
             ytitle("Predicted Probability of 'Poor' Health Status") ///
             ylabel(0.0(0.02)0.08, angle(horizontal))                ///
             legend(rows(1) size(small)  position(1) ring(0))
graph export ./graphs/`GraphNum'_OlogitAgeSex_Poor.png, as(png)    ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  

margins female, at(age==(20(10)80)) vce(unconditional) ///
                predict(outcome(3)) predict(outcome(4))
marginsplot, title("Predicted Probability of Health Status Category Over Age") ///
             ytitle("Predicted Probability of Health Status Category"          ///
                    , margin(medium))                                          ///
             ylabel(0(0.1)0.5, labsize(small) angle(horizontal))               ///
             legend(order(1 "Good,Male"                                        /// 
                          3 "Good,Female"                                      ///
                          2 "Fair,Male"                                        ///  
                          4 "Fair, Female")                                    ///
                    rows(1) size(vsmall)  position(12))
graph export ./graphs/`GraphNum'_OlogitAgeSex_GoodFair.png, as(png)    ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  


// =============================================================================
// /\/\/\/\/\/\/\/\      MULTINOMIAL LOGISTIC REGRESSION       \/\/\/\/\/\/\/\/\
// ============================================================================= 

frame change nhanes
svyset psu, weight(wt_interview) strata(strata) vce(linearized) singleunit(missing) 


svy: tabulate married, count obs format(%19.0fc)

svy: mlogit married i.female##c.age

margins
marginsplot
graph export ./graphs/`GraphNum'_Mlogit.png, as(png)        ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  

marginsplot, recast(bar) horizontal plotopts(barw(.8))                    ///
             title("Predicted Probability of Marriage Categories")        ///
             xtitle(Health Status, margin(medsmall))                      ///
             xtitle("Predicted Probability of Marriage Categories")       ///
             xlabel(0(0.1)0.6)                                            ///
             ylabel(1 "Married" 2 "Widowed" 3 "Divorced"                  ///
                    4 "Separated" 5 "Never Married" 6 "Live w/ Partner")  ///
             ytitle("")       
graph export ./graphs/`GraphNum'_Mlogit.png, as(png)    ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  


margins female, at(age==(20(10)80)) vce(unconditional) predict(outcome(2))
marginsplot, title("Predicted Probability of Being Widowed")    ///
             subtitle("by Age and Sex")                         ///
             ytitle("Predicted Probability of Being Widowed")   ///
             ylabel(0.0(0.1)0.6, angle(horizontal))             ///
             legend(rows(1) size(small)  position(12) ring(0))
graph export ./graphs/`GraphNum'_MlogitAgeSex_Widowed.png, as(png)    ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  





// =============================================================================
// /\/\/\/\/\/\/\/\/\/\/\       POISSON REGRESSION        /\/\/\/\/\/\/\/\/\/\/\
// =============================================================================

frame change nhanes
svyset psu, weight(wt_interview) strata(strata) vce(linearized) singleunit(missing) 


describe smokenum

histogram smokenum [fweight = wt_trig], discrete
graph export ./graphs/`GraphNum'_PoissonHistogram.png, as(png)     ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

svy: poisson smokenum i.poverty##c.smokeage
margins poverty, at(smokeage=(10(10)50)) vce(unconditional)
marginsplot, title("Predicted Cigarettes Smoked Per Day")           ///
             subtitle("by Poverty Status and Age Started Smoking")  ///
             ytitle("Predicted Cigarettes Smoked Per Day")          ///
             ylabel(, angle(horizontal))                            ///
             legend(order(1 "Poverty" 2 "No Poverty")               ///
                    rows(1) size(small)  position(12) ring(0))
graph export ./graphs/`GraphNum'_PoissonAgePoverty.png, as(png)     ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

svy: nbreg smokenum i.poverty##c.smokeage
margins poverty, at(smokeage=(10(10)50)) vce(unconditional)
marginsplot, title("Predicted Cigarettes Smoked Per Day")           ///
             subtitle("by Poverty Status and Age Started Smoking")  ///
             ytitle("Predicted Cigarettes Smoked Per Day")          ///
             ylabel(, angle(horizontal))                            ///
             legend(order(1 "Poverty" 2 "No Poverty")               ///
                    rows(1) size(small)  position(12) ring(0))
graph export ./graphs/`GraphNum'_NbregAgePoverty.png, as(png)     ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 





// Remove temporary variables and files
capture drop black
rm predictions.dta
rm predictions_adj.dta
rm predictions_unadj.dta
log close



/*************************************************************************
Created by: LianLian Chen
Created on: 02oct2021
Last modified: 02oct2021
Modified by: LianLian Chen
Project: GPH-GU 2397 Survey Design, Analysis, and Reporting
Analysis: Homework 04
Data Source: https://wwwn.cdc.gov/nchs/nhanes/continuousnhanes/default.aspx?BeginYear=2015
*****************************************************************************/


use "/Users/jessiechen/Downloads/NHANES2015.dta", clear

describe psu strata wt_interview wt_mec wt_fasting wt_diet 
       
notes psu
notes strata
notes wt_interview
notes wt_mec
notes wt_fasting
notes wt_diet       
       
// svyset command for MEC (lab) data
svyset psu, strata(strata)       ///
            weight(wt_mec)       ///
            vce(linearized)      /// 
            singleunit(missing)
            
// svyset command for diet data
svyset psu, strata(strata)       ///
            weight(wt_diet)      ///
            vce(linearized)      /// 
            singleunit(missing)            
  
// svyset command for fasting lab data
svyset psu, strata(strata)       ///
            weight(wt_fasting)   ///
            vce(linearized)      /// 
            singleunit(missing)    
  
// svyset command for interview data
svyset psu, strata(strata)       ///
            weight(wt_interview) ///
            vce(linearized)      /// 
            singleunit(missing)            

			

// Define global macros for graph dimensions
global Width16x9  = 1920*2
global Height16x9 = 1080*2
global Width4x3   = 1440*2
global Height4x3  = 1080*2
// set the graph scheme 
set scheme s1color
// Define the local macro "GraphNum" so that graphs are numbered sequentially
local GraphNum = 1


// =============================================================================
// /\/\/\/\/\/\/\/\/\/\/\/\      LINEAR REGRESSION        /\/\/\/\/\/\/\/\/\/\/\
// =============================================================================   


// svyset command for MEC (lab) data
svyset psu, weight(wt_mec) strata(strata) vce(linearized) singleunit(missing)  


// SAMPLE MEAN
// =============================================================================
svy: mean diabetes
svy: regress diabetes

// BINARY PREDICTOR
// =============================================================================
svy: mean diabetes, over(female) cformat(%9.2f)
svy: mean diabetes, over(female) cformat(%9.2f) coeflegend
test   _b[c.diabetes@0bn.female] = _b[c.diabetes@1.female]
lincom _b[c.diabetes@0bn.female] - _b[c.diabetes@1.female]


svy: regress diabetes female
svy: regress diabetes female, coeflegend
test _b[female] = 0

svy: regress diabetes i.female
svy: regress diabetes i.female, coeflegend
test _b[1.female] = 0


lincom _b[0.female] - _b[1.female]

list female i.female in 1/10

margins female, vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_LinearFemale.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum             
marginsplot, recast(bar) plotopts(barw(.8))
graph export ./graphs/`GraphNum'_LinearFemaleBar.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum




// CATEGORICAL PREDICTOR
// =============================================================================

// Compare to reference category
svy: mean diabetes, over(education) cformat(%9.2f)
svy: mean diabetes, over(education) cformat(%9.2f) coeflegend
test (_b[c.diabetes@1bn.education] = _b[c.diabetes@2.education])  ///
     (_b[c.diabetes@1bn.education] = _b[c.diabetes@3.education])  ///
     (_b[c.diabetes@1bn.education] = _b[c.diabetes@4.education])  ///
     (_b[c.diabetes@1bn.education] = _b[c.diabetes@5.education])


list education i.education in 1/15

contrast education
     
svy: regress diabetes i.education
// Note that this version of -test- is equivalent to a likelihood ratio test
test (_b[1bn.education] = _b[2.education])  ///
     (_b[1bn.education] = _b[3.education])  ///
     (_b[1bn.education] = _b[4.education])  ///
     (_b[1bn.education] = _b[5.education])

     
// Compare all means to zero
svy: mean diabetes, over(education) cformat(%9.2f) coeflegend
test (_b[c.diabetes@1bn.education] = 0)  ///
     (_b[c.diabetes@2.education]   = 0)  ///
     (_b[c.diabetes@3.education]   = 0)  ///
     (_b[c.diabetes@4.education]   = 0)  ///
     (_b[c.diabetes@5.education]   = 0)

svy: regress diabetes bn.education, noconstant coeflegend
test (_b[1bn.education] = 0)  ///
     (_b[2.education]   = 0)  ///
     (_b[3.education]   = 0)  ///
     (_b[4.education]   = 0)  ///
     (_b[5.education]   = 0)
     
svy: regress diabetes i.education


// Marginal predictions
margins education, vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_LinearEducation.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum

marginsplot, recast(bar) plotopts(barw(.8)) 
graph export ./graphs/`GraphNum'_LinearEducationBar.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  

marginsplot, recast(scatter) horizontal    ///
             plotregion(margin(t=10 b=10)) ///
             ytitle("")
graph export ./graphs/`GraphNum'_LinearEducation.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 



// Contrasts
svy: regress diabetes i.education
contrast r.education, noeffect
matrix list r(L)
contrast {education -1 1 0 0 0}  ///
         {education -1 0 1 0 0}  ///
         {education -1 0 0 1 0}  ///
         {education -1 0 0 0 1}  ///
         , noeffects
        

contrast g.education, noeffects
contrast g.education, mcompare(scheffe) noeffects
contrast g.education, mcompare(scheffe) nowald

// Contrasts of marginal predictions
margins g.education, contrast mcompare(scheffe)
margins g.education, contrast(nowald effects) mcompare(scheffe)
marginsplot
graph export ./graphs/`GraphNum'_LinearEducationContrast.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  
marginsplot, recast(scatter) horizontal xline(0)
graph export ./graphs/`GraphNum'_LinearEducationContrast.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 
marginsplot, recast(scatter) horizontal    ///
             xline(0) xlabel(-6(2)6)       ///
             ytitle("")                    ///
             plotregion(margin(t=10 b=10))
graph export ./graphs/`GraphNum'_LinearEducationContrast.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

// Pairwise comparisons
pwcompare education
pwcompare education, mcompare(bonferroni)

// Pairwise comparisons of marginal predictions
margins education, mcompare(bonferroni) pwcompare
marginsplot
graph export ./graphs/`GraphNum'_LinearEducationPwcompare.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 
marginsplot, xdimension(_pw) yline(0)
graph export ./graphs/`GraphNum'_LinearEducationPwcompare.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

marginsplot, recast(scatter) horizontal    ///
             xdimension(_pw) xline(0)      ///
             plotregion(margin(t=5 b=5))   ///
             unique
graph export ./graphs/`GraphNum'_LinearEducationPwcompare.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 
     


// CONINUOUS PREDICTOR
// =============================================================================
svy: regress diabetes income
test income=0

margins, at(income==(20(10)80)) vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_LinearIncome.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 






// INTERACTIONS BETWEEN BINARY AND CONTINUOUS PREDICTORS
// ============================================================================= 
svy: regress diabetes i.female c.income i.female#c.income
svy: regress diabetes i.female##c.income
margins female, at(income==(20(10)80)) vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_LinearIncomeFemale.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum   



// INTERACTIONS BETWEEN CATEGORICAL AND CONTINUOUS PREDICTORS
// =============================================================================      
svy: regress diabetes i.education##c.income
svy: regress diabetes i.education##c.income, coeflegend
// TEST THE MAIN EFFECT OF education USING -test-
test (_b[1bn.race] = _b[2.education])  ///
     (_b[1bn.race] = _b[3.education])  ///
     (_b[1bn.race] = _b[4.education])  ///
     (_b[1bn.race] = _b[5.education])

// TEST THE MAIN EFFECT OF education USING -contrast-     
contrast r.education, noeffects     

// TEST THE INTERACTION OF income AND race USING -test-
test (_b[1.education#c.income]=_b[2.education#c.income])  ///
     (_b[1.education#c.income]=_b[3.education#c.income])  ///
     (_b[1.education#c.income]=_b[4.education#c.income])  ///
     (_b[1.education#c.income]=_b[5.education#c.income])

     
svy: regress diabetes i.education##c.income     
     
// TEST THE INTERACTION OF income AND education USING -contrast-     
contrast r.education#c.income, noeffects  


margins education, at(income==(20(10)80)) vce(unconditional)
marginsplot
graph export ./graphs/`GraphNum'_LinearIncomeEducation.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 
marginsplot, recast(line) noci ///
             plotopts(lwidth(thick))
graph export ./graphs/`GraphNum'_LinearIncomeEducation.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  




// INTERACTIONS BETWEEN CATEGORICAL PREDICTORS
// =============================================================================     
svy: regress diabetes i.female i.education i.female#i.education
svy: regress diabetes i.female##i.education


svy: regress diabetes i.female##i.education, coeflegend

// TEST THE MAIN EFFECT OF education
test (_b[1bn.education] = _b[2.education])  ///
     (_b[1bn.education] = _b[3.education])  ///
     (_b[1bn.race] = _b[4.education])  ///
     (_b[1bn.race] = _b[5.education])
     
// TEST THE MAIN EFFECT OF education USING -contrast-     
contrast r.education, noeffects      

// TEST THE INTERACTION OF female AND education
test (_b[1.female#1.education]=_b[1.female#2.education])  ///
     (_b[1.female#1.education]=_b[1.female#3.education])  ///
     (_b[1.female#1.education]=_b[1.female#4.education])  ///
     (_b[1.female#1.education]=_b[1.female#5.education])

     
svy: regress sbp i.female##i.education     
     
// TEST THE INTERACTION OF female AND education USING -contrast-     
contrast r.female#r.education, noeffects       
     
svy: regress sbp i.female##i.education
margins female# education,  vce(unconditional)
// Default
marginsplot
graph export ./graphs/`GraphNum'_LinearFemaleEducation.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 
// Bar chart 
marginsplot, recast(bar)
graph export ./graphs/`GraphNum'_LinearFemaleEducation.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum  

// Vertical scatterplot (yuck!)
marginsplot, recast(scatter)                   ///
             xdimension(female education)           ///
             xlabel(,labsize(small) alternate) ///
             xscale(range(0.5 6.5))
graph export ./graphs/`GraphNum'_LinearFemaleEducation.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

// Horizontal scatterplot (female education)            
marginsplot, recast(scatter)           ///
             horizontal                ///
             xdimension(female education)   ///
             xlabel(,labsize(small))   ///
             ytitle("")
graph export ./graphs/`GraphNum'_LinearFemaleEducation.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum 

// Horizontal scatterplot (education female)             
marginsplot, recast(scatter)                ///
             horizontal                     ///
             xdimension(education female)        ///
             xlabel(,labsize(small))        ///
             xtitle("Predicted SBP (mmHg)") ///
             ytitle("")                     ///
             title("Predicted SBP by Race and Sex")
graph export ./graphs/`GraphNum'_LinearFemaleEducation.png, as(png)           ///
             width($Width16x9) height($Height16x9) replace
local ++GraphNum








