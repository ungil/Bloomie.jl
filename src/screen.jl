"""
Retrieve the output of a screen as a data frame. The group is GENERAL by default.
The private flag is only required if the name designates as well a public screen.
See the Equity Screening page in the Bloomberg terminal (EQS <GO>).

N.B. If the calculation takes too long the function will timeout (after 2 min by default).
In that case the result has to be retrieved (to avoid issues with later requests) doing
DataFrames.DataFrame(Bloomie.process_tree(Bloomie.retrieve_response()))

#Examples
```julia
beqs("Global Automotive Parts Retailers")
beqs("Fisher Inspired Screen",group="Guru Screens")
```
"""
function beqs(name::String;group::String="General",private::Bool=false,timeout::Int=120)
    global session
    global services
    service = services["refdata"]
    request = @with_pointer request blpapi_Service_createRequest(service,request,"BeqsRequest")
    elements = blpapi_Request_elements(request)
    try
        blpapi_Element_setElementString(elements,"screenName",C_NULL,name)
        if private
            blpapi_Element_setElementString(elements,"screenType",C_NULL,"PRIVATE")
        else
            blpapi_Element_setElementString(elements,"screenType",C_NULL,"GLOBAL")
        end
        blpapi_Element_setElementString(elements,"Group",C_NULL,group)
        correlation_id = blpapi_CorrelationId(0,0)
        blpapi_Session_sendRequest(session,request,Ref(correlation_id),C_NULL,C_NULL,C_NULL,0)
    finally
        blpapi_Request_destroy(request)
    end
    DataFrames.DataFrame(process_tree(retrieve_response(timeout)))
end
