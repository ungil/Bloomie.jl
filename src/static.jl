"""
Retrieve static data. Multiple tickers and multiple fields can be specified.
A data frame will be returned with securities as rows and fields as columns.

Bulk data fields return data frames and cannot be combined with other fields.
If multiple securities are given, a dictionary ticker => DataFrame is returned.
These special fields are not detected automatically, a few are predefined but
you may need to update the variable Bloomie.bulk_fields in file src/response.jl

#Examples
```julia
bdp(["AAPL US Equity","MSFT US Equity"],["PX_LAST","VOLUME"])
bdp("AAPL US Equity","BEST_PE_RATIO",overrides=Dict("BEST_FPERIOD_OVERRIDE"=>"1BF"))
bdp(["FB US Equity","TWTR US Equity"],"ERN_ANN_DT_AND_PER")
bdp("TSLA US Equity","BEST_ANALYST_RECS_BULK",overrides=Dict("END_DATE_OVERRIDE"=>"20151231"))
bdp(["INDU Index","TRAN Index"],"INDX_MEMBERS")
bdp("INDU Index","INDX_MWEIGHT_HIST",overrides=Dict("END_DT"=>"20101231"))
```
"""
function bdp(tickers,fields;overrides=Dict())
    global session
    global services
    single_security = false
    if !isa(tickers,Vector); tickers=[tickers]; single_security=true; end
    if !isa(fields,Vector); fields=[fields]; end
    service = services["refdata"]
    request = @with_pointer request blpapi_Service_createRequest(service,request,"ReferenceDataRequest")
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
        correlation_id = blpapi_CorrelationId(0,0)
        blpapi_Session_sendRequest(session,request,Ref(correlation_id),C_NULL,C_NULL,C_NULL,0)
    finally
        blpapi_Request_destroy(request)
    end
    out=process_tree(retrieve_response())
    if typeof(out[1]) <: Dict
        data = [row for row in filter(x->typeof(x)<:Dict,out)]
        nodata = filter(x->!(typeof(x)<:Dict),out)
        map(x->warn(@sprintf "No data retrieved for %s" x[1]),nodata)
        if length(data) > 0
            DataFrames.DataFrame(data)
        else
            nothing
        end
    elseif typeof(out) <: Array
        out = vcat(out...)
        data = filter(x->x[2]!=nothing,out)
        nodata = filter(x->x[2]==nothing,out)
        map(x->warn(@sprintf "No data retrieved for %s" x[1]),nodata)
        if length(data) > 0
            Dict(data)
            if single_security
                data[1][2]
            else
                Dict(data)
            end
        else
            nothing
        end
    else
        error("this should not happen")
    end
end
