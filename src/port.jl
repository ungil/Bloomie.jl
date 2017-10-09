"""
Retrieve the composition of a user-defined portfolio as a data frame.
The name of the portfolio is something like U12345678-1 (see PRTU <GO>).
Four kinds of requests exist: members (default), positions, weights, data.
Use the date argument to retrieve historical compositions (YYYYMMDD format).

#Examples
```julia
bport("U12345678-1")
bport("U12345678-1",retrieve="data") 
bport("U12345678-1",date="20170930")
```
"""
function bport(name::String;retrieve::String="members",date::String="",overrides::Dict=Dict())
    global session
    global services
    field = @Match.match retrieve begin
        "members" => "PORTFOLIO_MEMBERS"
        "positions" => "PORTFOLIO_MPOSITION"
        "weights" => "PORTFOLIO_MWEIGHT"
        "data" => "PORTFOLIO_DATA"
        _ => error("the retrieve parameter has to be one of [members, positions, weights, data]")
    end
    service = services["refdata"]
    request = @with_pointer request blpapi_Service_createRequest(service,request,"PortfolioDataRequest")
    elements = blpapi_Request_elements(request)
    try
        securities_ = @with_pointer securities_ blpapi_Element_getElement(elements,securities_,"securities",C_NULL)
        blpapi_Element_setValueString(securities_,name*" Client",-1)
        fields_ = @with_pointer fields_ blpapi_Element_getElement(elements,fields_,"fields",C_NULL)
        blpapi_Element_setValueString(fields_,field,-1)
        if length(date) > 0 || length(overrides) > 0
            overrides_ = @with_pointer overrides_ blpapi_Element_getElement(elements,overrides_,"overrides",C_NULL)
            new_ = @with_pointer new_ blpapi_Element_appendElement(overrides_,new_)
            if length(date) > 0
                blpapi_Element_setElementString(new_, "fieldId", C_NULL, "REFERENCE_DATE")
                blpapi_Element_setElementString(new_, "value", C_NULL, date)
            end
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
    process_tree(retrieve_response())[1][2]
end
