//run first time only
//stage 0
clear all
use "C:\Users\cuser\ec\1-fomc-shocks-raw-daily.dta"
gen Week = week(date(FOMCDate, "YMD"))
gen daten = date(FOMCDate, "YMD")
save "C:\Users\cuser\ec\1-fomc-shocks-raw-daily.dta", replace

//stage 1
clear all
import fred MORTGAGE30US MORTGAGE15US MORTGAGE5US, daterange(2009-06-01 2020-01-31) aggregate(weekly)
gen Year = year(daten)
gen Week = week(daten)
gen yw = yw(year(daten),week(daten))
format yw %tw
save "C:\Users\cuser\ec\3-1-weekly-raw.dta", replace

//stage 2a mortgage diffs
clear all
use "C:\Users\cuser\ec\3-1-weekly-raw.dta"
drop if missing(MORTGAGE30US)

merge m:m daten using "C:\Users\cuser\ec\1-fomc-shocks-raw-daily.dta", keepusing(FOMCDate Spot Lead1 Lead2 Lead3 Lead4)
sort daten

gen FOMCDateN = date(FOMCDate, "YMD")

local mortgagevars "MORTGAGE30US MORTGAGE15US MORTGAGE5US"
foreach x of local mortgagevars {
/*big window
gen d`x'v1 = `x'[_n+2] - `x'[_n-1] if (!missing(Spot)) & (daten[_n+1] - daten <= 1) //75
replace d`x'v1 = `x'[_n+1] - `x'[_n-1] if (!missing(Spot)) & (daten[_n+1] - daten > 1) //16
*/
gen d`x'v1 = `x'[_n+2] - `x'[_n+1] if (!missing(Spot)) & (daten[_n+1] - daten <= 2) //75
replace d`x'v1 = `x'[_n+1] - `x'[_n-1] if (!missing(Spot)) & (daten[_n+1] - daten > 2) //16
}

drop if missing(dMORTGAGE30USv1)
keep FOMCDate dMORTGAGE30USv1 dMORTGAGE15USv1 dMORTGAGE5USv1

save "C:\Users\cuser\ec\3-2a-mortgage-raw.dta", replace

//stage 2b balance sheet loan diffs
clear all
use "C:\Users\cuser\ec\3-1-weekly-raw.dta"
rename RREACBW027SBOG res_re_loan
drop if missing(res_re_loan)
gen l_res_re_loan = log(res_re_loan)

merge m:m daten using "C:\Users\cuser\ec\1-fomc-shocks-raw-daily.dta", keepusing(FOMCDate Spot Lead1 Lead2 Lead3 Lead4)
sort daten

gen FOMCDateN = date(FOMCDate, "YMD")

/*conventional
gen dl_res_re_loan = (l_res_re_loan[_n+1] - l_res_re_loan[_n-1])*100 if (!missing(Spot))
*/
gen dl_res_re_loan = (l_res_re_loan[_n+1] - l_res_re_loan)*100 if (_merge == 3) & (!missing(Spot))
replace dl_res_re_loan = (l_res_re_loan[_n+1] - l_res_re_loan[_n-1])*100 if (_merge != 3) & (!missing(Spot))

drop if missing(dl_res_re_loan)
keep FOMCDate dl_res_re_loan

save "C:\Users\cuser\ec\3-2b-re-loan-raw.dta", replace

//stage 3 results
clear all
use "C:\Users\cuser\ec\1-rates-raw.dta"
tsset daten

merge 1:1 Year Month Day using "C:\Users\cuser\ec\1-fomc-shocks-raw-daily.dta"
drop if _merge!=3
tsset daten

drop _merge
merge 1:1 FOMCDate using "C:\Users\cuser\ec\3-2a-mortgage-raw.dta"

drop _merge
merge 1:1 FOMCDate using "C:\Users\cuser\ec\3-2b-re-loan-raw.dta"

drop _merge

drop if missing(daten)

pca Lead1 Lead2 Lead3 Lead4
predict lead_pc1, score

local dailydiffvars "DFF DGS1MO DGS1 DGS2 DGS5 DGS10 DGS30"
foreach x of local dailydiffvars {
gen d_`x' = `x' - `x'[_n-1]
}

ivreg2 d_DGS1 (d_DFF = Spot), nocon robust
outreg2 using "C:\Users\cuser\ec\temp-3-iv-mortgate.xls", dec(3) replace
local outcomes "dMORTGAGE30USv1 dMORTGAGE15USv1 dMORTGAGE5USv1 dl_res_re_loan"
local policyindicators "d_DGS1 d_DGS2 d_DGS5"
local instruments "Lead1 Lead2 Lead3 Lead4 lead_pc1"
foreach i of local outcomes {
foreach j of local policyindicators {
foreach k of local instruments{
ivreg2 `i' (`j'=`k'), nocon robust
outreg2 using "C:\Users\cuser\ec\temp-3-iv-mortgate.xls", dec(3)
}
}
}

reg d_DGS1 Spot, nocon robust
outreg2 using "C:\Users\cuser\ec\temp-3-ols-mortgate.xls", dec(3) replace
local outcomes "dMORTGAGE30USv1 dMORTGAGE15USv1 dMORTGAGE5USv1 dl_res_re_loan"
local instruments "Lead1 Lead2 Lead3 Lead4 lead_pc1"
foreach i of local outcomes {
foreach k of local instruments{
reg `i' `k', nocon robust
outreg2 using "C:\Users\cuser\ec\temp-3-ols-mortgate.xls", dec(3)
}
}