//run first time only
import fred DFF DGS1MO DGS6MO DGS1 DGS2 DGS5 DGS10 DGS30, daterange(2009-01-01 2020-01-31) aggregate(daily)
drop if missing(DGS1MO)
gen Year = year(daten)
gen Month = month(daten)
gen Day = day(daten)
save "C:\Users\cuser\ec\1-rates-raw.dta", replace

//begin
clear all
use "C:\Users\cuser\ec\1-rates-raw.dta"
tsset daten

merge 1:1 Year Month Day using "C:\Users\cuser\ec\1-fomc-shocks-raw-daily.dta"
drop if _merge!=3
tsset daten

pca Lead1 Lead2 Lead3 Lead4
screeplot
predict lead_pc1, score

local dailydiffvars "DFF DGS1MO DGS1 DGS2 DGS5 DGS10 DGS30"
foreach x of local dailydiffvars {
gen d_`x' = `x' - `x'[_n-1]
}

reg d_DFF Spot, nocon
outreg2 using "C:\Users\cuser\ec\results\1-instrument-relevance.xls", dec(3) replace
local policyindicators "d_DFF d_DGS1MO d_DGS1 d_DGS2 d_DGS5"
local fomcshocks "Spot Lead1 Lead2 Lead3 Lead4"
foreach i of local policyindicators {
foreach j of local fomcshocks {
reg `i' `j', nocon robust
outreg2 using "C:\Users\cuser\ec\results\1-instrument-relevance.xls", dec(3)
}
}

ivreg2 d_DGS1 (d_DFF = Spot), nocon robust
outreg2 using "C:\Users\cuser\ec\results\1-iv-daily.xls", dec(3) replace
local outcomes "d_DGS5 d_DGS10 d_DGS30"
local policyindicators "d_DGS1 d_DGS2"
local instruments "Lead1 Lead2 Lead3 Lead4 lead_pc1"
foreach i of local outcomes {
foreach j of local policyindicators {
foreach k of local instruments{
ivreg2 `i' (`j'=`k'), nocon robust
outreg2 using "C:\Users\cuser\ec\results\1-iv-daily.xls", dec(3)
}
}
}

/*
reg d_DGS5 d_DGS1, nocon
outreg2 using "C:\Users\cuser\ec\temp-second-stage.xls", dec(3) replace
local policyindicators "d_DGS5 d_DGS10 d_DGS30"
local fomcshocks "d_DGS1 d_DGS2"
foreach i of local policyindicators {
foreach j of local fomcshocks {
reg `i' `j', nocon robust
outreg2 using "C:\Users\cuser\ec\temp-second-stage.xls", dec(3)
}
}
*/


