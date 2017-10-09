"""
Retrieve intraday bar data (size 30 minutes by default) as a time series.
The start date is required, the end date is optional. These arguments may be
dates of the form YYYY-MM-DD or times of the form YYYY-MM-DDTHH:MM:SS.
The event type can be one of TRADE, BID, ASK, BEST_BID, BEST_ASK.

#Examples
```julia
bbars("AAPL US Equity","TRADE","2017-09-27",end_date_time="2017-09-29")
bbars("AAPL US Equity","BID","2017-09-27T06:00:00",end_date_time="2017-09-27T09:00:00",bar_size_minutes=10)
```
"""
function bbars(ticker::String,event::String,start_date_time::String;end_date_time::String="",bar_size_minutes::Int=30,overrides=Dict())
    global session
    global services
    @assert event in ["TRADE", "BID", "ASK", "BEST_BID", "BEST_ASK"]
    service = services["refdata"]
    request = @with_pointer request blpapi_Service_createRequest(service,request,"IntradayBarRequest")
    elements = blpapi_Request_elements(request)
    try
        blpapi_Element_setElementString(elements,"security",C_NULL,ticker)
        blpapi_Element_setElementString(elements,"eventType",C_NULL,event)
        blpapi_Element_setElementInt32(elements,"interval",C_NULL,bar_size_minutes)
        @assert length(start_date_time) >= 10
        blpapi_Element_setElementString(elements,"startDateTime",C_NULL,start_date_time)
        if length(end_date_time) > 0
            @assert length(end_date_time) >= 10
            blpapi_Element_setElementString(elements,"endDateTime",C_NULL,end_date_time)
        end
        if length(overrides) > 0
            overrides_ = @with_pointer overrides_ blpapi_Element_getElement(elements,overrides_,"overrides",C_NULL)
            for (k,v) in overrides
                new_ = @with_pointer new_ blpapi_Element_appendElement(overrides_,new_)
                blpapi_Element_setElementString(new_, "fieldId", C_NULL, string(k))
                blpapi_Element_setElementString(new_, "value", C_NULL, string(v))
            end
        end
        correlation_id = blpapi_CorrelationId(0,0)
        blpapi_Session_sendRequest(session,request,Ref(correlation_id),C_NULL,C_NULL,C_NULL,0)
    finally
        blpapi_Request_destroy(request)
    end
    out = process_tree(retrieve_response())
    if length(out) > 0
        TimeSeriesIO.TimeArray(out, colnames=[:open, :high, :low, :close, :volume, :numEvents, :value], timestamp=:time)
    end
end
