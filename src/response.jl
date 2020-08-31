global bulk_fields = ["IEST_BRAND_PRODUCT_LIST","BLOOMBERG_PEERS",
                      "HIST_TRR_MONTHLY","BEST_ANALYST_RECS_BULK",
                      "ERN_ANN_DT_AND_PER","EARN_ANN_DT_TIME_HIST_WITH_EPS",
                      "INDX_MEMBERS","INDX_MWEIGHT","INDX_MWEIGHT_HIST",
                      "PORTFOLIO_MEMBERS","PORTFOLIO_MPOSITION",
                      "PORTFOLIO_MWEIGHT","PORTFOLIO_DATA"]

function flatten_all(a)
    while any(x-> !(typeof(x)==String) && (typeof(x)<:Array || typeof(x)<:Tuple), a)
        a = vcat([typeof(x)==String ? [x] : collect(Base.Iterators.flatten([x])) for x in a]...)
    end
    a
end

function date(val)
    # BLPAPI_DATETIME_YEAR_PART | ..._MONTH_PART | ..._DAY_PART
    @assert val.parts == 0x01 | 0x02 | 0x04
    Dates.DateTime(val.year,val.month,val.day)
end

function datetime(val)
    # BLPAPI_DATETIME_YEAR_PART | ..._MONTH_PART | ..._DAY_PART | ..._HOURS_PART | ..._MINUTES_PART | ..._SECONDS_PART | ..._MILLISECONDS_PART
    @assert val.parts == 0x01 | 0x02 | 0x04 | 0x10 | 0x20 | 0x40 | 0x80
    Dates.DateTime(val.year,val.month,val.day,val.hours,val.minutes,val.seconds,val.milliSeconds)
end

function decode_value(element,datatype,i)
    @Match.match datatype begin
        1 => begin val=Ref{Int32}(0); blpapi_Element_getValueAsBool(element,val,i); Bool(val[]) end
        2 => error("BLPAPI_DATATYPE_CHAR")
        3 => error("BLPAPI_DATATYPE_BYTE")
        4 => begin val=Ref{Int32}(0); blpapi_Element_getValueAsInt32(element,val,i); val[] end
        5 => begin val=Ref{Int64}(0); blpapi_Element_getValueAsInt64(element,val,i); val[] end
        6 => begin val=Ref{Float32}(0); blpapi_Element_getValueAsFloat32(element,val,i); val[] end
        7 => begin val=Ref{Float64}(0); blpapi_Element_getValueAsFloat64(element,val,i); val[] end
        8 => begin val=Ref{Ptr{UInt8}}(0); blpapi_Element_getValueAsString(element,val,i); unsafe_string(val[]) end
        9 => error("BLPAPI_DATATYPE_BYTEARRAY")
        10 => begin val=blpapi_Datetime(0,0,0,0,0,0,0,0,0); blpapi_Element_getValueAsDatetime(element,val,i); date(val); end
        11 => error("BLPAPI_DATATYPE_TIME")
        12 => error("BLPAPI_DATATYPE_DECIMAL")
        13 => begin val=blpapi_Datetime(0,0,0,0,0,0,0,0,0); blpapi_Element_getValueAsDatetime(element,val,i); datetime(val); end
    end
end

function decode_element(element)
    name=blpapi_Element_nameString(element)
    datatype = blpapi_Element_datatype(element)
    if datatype <= 13
        (name,[decode_value(element,datatype,i) for i in 0:(blpapi_Element_numValues(element)-1)])
    elseif datatype == 14
        error("BLPAPI_DATATYPE_ENUMERATION")
    elseif datatype == 15
        if Bool(blpapi_Element_isArray(element))
            (name,[decode_element(@with_pointer val blpapi_Element_getValueAsElement(element,val,i)) for i in 0:(blpapi_Element_numValues(element)-1)])
        else
            (name,[decode_element(@with_pointer val blpapi_Element_getElementAt(element,val,i)) for i in 0:(blpapi_Element_numElements(element)-1)])
        end
    elseif datatype == 16
        decode_element(@with_pointer choice blpapi_Element_getChoice(element,choice))
    elseif datatype == 17
        error("BLPAPI_CORRELATION_ID")
    end
end

function process_message(msg)
    messageType = blpapi_Message_typeString(msg)
    contents = blpapi_Message_elements(msg)
    #@show AbstractTrees.Tree(decode_element(contents))
    if blpapi_Element_hasElement(contents,"responseError",C_NULL)
        response_error = process_tree(decode_element(@with_pointer err blpapi_Element_getElement(contents,err,"responseError",C_NULL)))
        error(response_error["message"])
    end
    return decode_element(contents)
end

function process_event(event)
    iterator = blpapi_MessageIterator_create(event)
    done = false
    out = []
    try
        while !done
            msg = @with_pointer msg blpapi_MessageIterator_next(iterator,msg)
            if msg == C_NULL
                done = true
            else
                try
                    out = vcat(out,process_message(msg))
                finally
                    blpapi_Message_release(msg)
                end
            end
        end
    finally
        blpapi_MessageIterator_destroy(iterator)
    end
    out
end

function retrieve_response(timeout=10)
    done = false
    out = []
    while !done
        event = @with_pointer event blpapi_Session_nextEvent(session,event,1000*timeout)
        try
            event_type = @Match.match blpapi_Event_eventType(event) begin
                1 => :ADMIN
                2 => :SESSION_STATUS
                3 => :SUBSCRIPTION_STATUS
                4 => :REQUEST_STATUS
                5 => :RESPONSE
                6 => :PARTIAL_RESPONSE
                8 => :SUBSCRIPTION_DATA
                9 => :SERVICE_STATUS
                10 => :TIMEOUT
                11 => :AUTHORIZATION_STATUS
                12 => :RESOLUTION_STATUS
                13 => :TOPIC_STATUS
                14 => :TOKEN_STATUS
                15 => :REQUEST
            end
            if event_type == :TIMEOUT || event_type == :RESPONSE
                done = true
            end
            if event_type == :RESPONSE || event_type == :PARTIAL_RESPONSE
                out = vcat(out,process_event(event))
            elseif event_type == :TIMEOUT
                @warn (event_type,)
            else
                @warn (event_type,flatten_all(process_event(event)))
            end
        finally
            blpapi_Event_release(event)
        end
    end
    out
end

function security_data(x)
    global bulk_fields
    #@show AbstractTrees.Tree(x)
    if length(x["fieldData"]) == 0
        (x["security"][1],nothing)
    elseif x["fieldData"][1][1] in bulk_fields
        if length(x["fieldData"]) > 1
            error("Bulk data fields have to be retrieved alone")
        else
            (x["security"][1],
             DataFrames.DataFrame(map(a->Dict([Symbol(k)=>process_tree(v) for (k,v) in a[2]]), x["fieldData"][1][2])))
        end
    else
        merge(Dict(:security=>x["security"][1]),
              Dict([Symbol(k)=> process_tree(v) for (k,v) in x["fieldData"]]))
    end
end

function security_data_hist(x)
    df = DataFrames.DataFrame(map(row->Dict([Symbol(k)=> process_tree(v) for (k,v) in row[2]]),x["fieldData"]))
    if size(df,1) > 0
        (x["security"][1],TimeSeries.TimeArray(df,timestamp=:date))
    else
        (x["security"][1],nothing)
    end
end

function bar_data(x)
    rows = map(x->x[2],x["barTickData"])
    DataFrames.DataFrame(map(row->Dict([Symbol(k)=>process_tree(v) for (k,v) in row]),rows))
end

function process_tree(x::Any,context="")
    if typeof(x) == Int32 && x == -2147483648
        NaN
    elseif typeof(x) == Float64 && x == -2.4245362661989844e-14
        NaN
    else
        x
    end
end

function process_tree(x::Tuple,context="")
    @Match.match x[1] begin
        "securityData" => context=="H" ? security_data_hist(Dict(x[2])) : map(x->security_data(Dict(x[2])),x[2])
        "barData" => bar_data(Dict(x[2]))
        "responseError" => Dict([k=>process_tree(v) for (k,v) in x[2]])
        "data" => map(a->Dict([Symbol(k)=>process_tree(v) for (k,v) in a[2][3][2]]),x[2][2][2])
        _ => @warn ["cannot handle",x]
    end
end

function process_tree(x::Array,context="")
    if length(x) == 1
        process_tree(x[1],context)
    else
        map(x->process_tree(x,context),x)
    end
end
