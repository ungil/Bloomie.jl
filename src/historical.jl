"""
Retrieve time series data. Multiple tickers and multiple fields can be specified.
If multiple securities are specified a dictionary ticker => TimeSeries is returned.
The start date is required, the end date is optional (format YYYYMMDD).
Periodicity values: DAILY (default), WEEKLY, MONTHLY, QUARTERLY, SEMI-ANUALLY, YEARLY.

#Examples
```julia
bdh("AAPL US Equity","BEST_PE_RATIO","20141231",periodicity="QUARTERLY",overrides=Dict("BEST_FPERIOD_OVERRIDE"=>"1BF"))
bdh("INDU Index",["PX_LAST","VOLUME"],"20170930",periodicity="WEEKLY")
bdh(["INDU Index","SPX Index"],["PX_LAST","VOLUME"],"20170910",end_date="20170930")
```
"""
function bdh(tickers,fields,start_date;end_date="",periodicity="",overrides=Dict())
    global session
    global services
    if !isa(tickers,Vector); tickers=[tickers]; end
    if !isa(fields,Vector); fields=[fields]; end
    service = services["refdata"]
    request = @with_pointer request blpapi_Service_createRequest(service,request,"HistoricalDataRequest")
    elements = blpapi_Request_elements(request)
    try
        securities_ = @with_pointer securities_ blpapi_Element_getElement(elements,securities_,"securities",C_NULL)
        foreach(ticker -> blpapi_Element_setValueString(securities_,ticker,-1), tickers)
        fields_ = @with_pointer fields_ blpapi_Element_getElement(elements,fields_,"fields",C_NULL)
        foreach(field -> blpapi_Element_setValueString(fields_,field,-1), fields)
        if length(overrides) > 0
            overrides_ = @with_pointer overrides_ blpapi_Element_getElement(elements,overrides_,"overrides",C_NULL)
            for (k,v) in overrides
                new_ = @with_pointer new_ blpapi_Element_appendElement(overrides_,new_)
                blpapi_Element_setElementString(new_, "fieldId", C_NULL, string(k))
                blpapi_Element_setElementString(new_, "value", C_NULL, string(v))
            end
        end
        @assert length(start_date) == 8
        blpapi_Element_setElementString(elements,"startDate",C_NULL,start_date)
        if length(end_date) > 0
            @assert length(end_date) == 8
            blpapi_Element_setElementString(elements,"endDate",C_NULL,end_date)
        end
        if length(periodicity) > 0
            @assert periodicity in ["DAILY" "WEEKLY" "MONTHLY" "QUARTERLY" "SEMI-ANUALLY" "YEARLY"]
            blpapi_Element_setElementString(elements,"periodicitySelection",C_NULL,periodicity)
        end
        correlation_id = blpapi_CorrelationId(0,0)
        blpapi_Session_sendRequest(session,request,Ref(correlation_id),C_NULL,C_NULL,C_NULL,0)
    finally
        blpapi_Request_destroy(request)
    end
    out=process_tree(retrieve_response(),"H")
    if typeof(out) <: Tuple
        if out[2]==nothing; warn(@sprintf "No data retrieved for %s" out[1]); end
        out[2]
    else
        data = filter(x->x[2]!=nothing,out)
        nodata = filter(x->x[2]==nothing,out)
        map(x->warn(@sprintf "No data retrieved for %s" x[1]),nodata)
        if length(data) > 0
            Dict(data)
        else
            nothing
        end
    end
end
