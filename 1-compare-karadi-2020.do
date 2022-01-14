//Compare my results to Karadi 2020
clear all
use "C:\Users\cuser\ec\1-fomc-shocks.dta"
rename Year year
rename Month month
save "C:\Users\cuser\ec\1-fomc-shocks.dta", replace
clear all
import delimited "C:\Users\cuser\ec\data.csv"
merge 1:1 year month using "C:\Users\cuser\ec\1-fomc-shocks.dta"
drop if _merge!=3
reg ff4_hf Spot
reg ff4_hf Lead1
reg ff4_hf Lead2
reg ff4_hf Lead3
reg ff4_hf Lead4
gen ddd = ym(year,month)
tsset ddd