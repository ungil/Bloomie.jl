module Bloomie

export bopen, bclose, bdp, bdh, bbars, bport, beqs

import Match
import DataFrames
import TimeSeries
import TimeSeriesIO
import AbstractTrees

Libdl.dlopen("C:/blp/DAPI/blpapi3_64.dll")

include("blpapi.jl")
include("session.jl")
include("response.jl")
include("static.jl")
include("historical.jl")
include("intraday.jl")
include("port.jl")
include("screen.jl")

end
