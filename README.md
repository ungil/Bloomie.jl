# Bloomie

## Overview

[BLPAPI](https://www.bloomberg.com/professional/support/api-library/) wrapper to retrieve data from Bloomberg. Tested only with the Desktop API on Windows.

The following requests implemented: ReferenceData, HistoricalData, IntradayBar, PortfolioData, Beqs (but some of the options for HistoricalData and IntradayBar are not handled).

## Installation

````julia
# Pkg.clone("https://github.com/ungil/Bloomie.jl.git")
````

## Getting started

````julia
using Bloomie

bopen()

bdp(["AAPL US Equity","MSFT US Equity"],["PX_LAST","VOLUME"])

bdp("AAPL US Equity","BEST_PE_RATIO",overrides=Dict("BEST_FPERIOD_OVERRIDE"=>"1BF"))

bdp("AAPL US Equity","BLOOMBERG_PEERS")

bdp(["AAPL US Equity"],"BLOOMBERG_PEERS")

bdp(["AAPL US Equity","IBM US Equity"],"BLOOMBERG_PEERS")

bdp(["TWTR US Equity","SNAP US Equity"],"HIST_TRR_MONTHLY")

bdp("TWTR US Equity","EARN_ANN_DT_TIME_HIST_WITH_EPS")

bdp(["FB US Equity","TWTR US Equity"],"ERN_ANN_DT_AND_PER")

bdp("VRTX US Equity","IEST_BRAND_PRODUCT_LIST")

bdp("TSLA US Equity","BEST_ANALYST_RECS_BULK")

bdp("TSLA US Equity","BEST_ANALYST_RECS_BULK",overrides=Dict("END_DATE_OVERRIDE"=>"20151231"))

bdp("INDU Index","INDEX_MEMBERSHIP_MAINT_DATE")

bdp(["INDU Index","TRAN Index"],"INDX_MEMBERS")

bdp("INDU Index","INDX_MWEIGHT")

bdp("INDU Index","INDX_MWEIGHT_HIST",overrides=Dict("END_DT"=>"20101231"))

bdh("AAPL US Equity","BEST_PE_RATIO","20141231",periodicity="QUARTERLY",overrides=Dict("BEST_FPERIOD_OVERRIDE"=>"1BF"))

bdh("INDU Index",["PX_LAST","VOLUME"],"20170930",periodicity="WEEKLY")

bdh(["INDU Index","SPX Index"],["PX_LAST","VOLUME"],"20170910",end_date="20170930")

bbars("AAPL US Equity","TRADE","2017-09-27",end_date_time="2017-09-29",bar_size_minutes=60)

bbars("AAPL US Equity","BID","2017-09-27T06:00:00",end_date_time="2017-09-27T09:00:00",bar_size_minutes=10)

bport("U12345678-1")

bport("U12345678-1",retrieve="positions")

bport("U12345678-1",retrieve="data")

bport("U12345678-1",date="20170930",retrieve="weights")
    
beqs("Global Automotive Parts Retailers")

beqs("Fisher Inspired Screen",group="Guru Screens")

bclose()
````
