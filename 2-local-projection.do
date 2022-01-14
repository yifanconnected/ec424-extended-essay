//run first time only
clear all
import fred INDPRO CPIAUCSL CSUSHPISA MORTGAGE30US DFF DGS1MO DGS1 DGS2 DGS5 DGS10 DGS30, daterange(2009-06-01 2020-01-31) aggregate(monthly,avg)
gen Year = year(daten)
gen Month = month(daten)
gen ym = ym(year(daten),month(daten))
format ym %tm
tsset ym
save "C:\Users\cuser\ec\2-local-projection.dta", replace

//begin
//begin
clear all
use "C:\Users\cuser\ec\2-local-projection.dta"
tsset ym

merge 1:1 Year Month using "C:\Users\cuser\ec\1-fomc-shocks.dta"
drop if _merge!=3
tsset ym

pca Lead1 Lead2 Lead3 Lead4
predict lead_pc1, score

gen ly = log(INDPRO)
gen lpi = log(CPIAUCSL)
gen lhp = log(CSUSHPISA)

gen d_ly = D.ly
gen d_lpi = D.lpi
gen d_lhp = D.lhp
gen d_ff = D.DFF
gen d_1mo = D.DGS1MO 
gen d_1y = D.DGS1
gen d_2y = D.DGS2

/*
gen dy = INDPRO - INDPRO[_n-1]
gen dpi = CPIAUCSL - CPIAUCSL[_n-1]
gen dhp = CSUSHPISA - CSUSHPISA[_n-1]
gen d_r = DGS1 - DGS1[_n-1]
L.d_sr d_ly L.d_ly d_lpi L.d_lpi
*/



reg d_1y d_1y L(1/12).d_1y L(0/12).d_ly L(0/12).d_lpi,  robust
outreg2 using "C:\Users\cuser\ec\temp-irf-sr.xls", dec(3) replace
forvalues i=2(1)24 {
  gen d`i'_1y = F`i'.DGS1 - L.DGS1
  reg d`i'_1y d_1y L(1/12).d_1y L(0/12).d_ly L(0/12).d_lpi,  robust
  outreg2 using "C:\Users\cuser\ec\temp-irf-sr.xls", dec(3) 
  drop d`i'_1y
}

gen r_sr = DGS1
gen r_lr = MORTGAGE30US

//structural var: cholesky ordering benchmark
var dy dpi d_r, lags(1/2)
irf set "C:\Users\cuser\ec\2-benchmark-irf.irf", replace
irf create benchmark, order(dy dpi d_r)
irf graph irf, impulse(d_r)

svar ly lpi lhp r_sr r_lr, lags(1/12) beq(B5)