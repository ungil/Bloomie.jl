global session = nothing
global services = nothing

function get_version()
    majorVersion = Ref{Cint}(0)
    minorVersion = Ref{Cint}(0)
    patchVersion = Ref{Cint}(0)
    buildVersion = Ref{Cint}(0)
    blpapi_getVersionInfo(majorVersion, minorVersion, patchVersion, buildVersion)
    (majorVersion[], minorVersion[], patchVersion[], buildVersion[])
end

function create_session(;host::String="",port::Int=0)
    event_dispatcher = blpapi_EventDispatcher_create(0)
    session_options = blpapi_SessionOptions_create()
    if length(host) > 0
        blpapi_SessionOptions_setServerHost(session_options,host)
    end
    if length(host) > 0
        blpapi_SessionOptions_setServerPort(session_options,port)
    end
    session = blpapi_Session_create(session_options,C_NULL,event_dispatcher,C_NULL)
    blpapi_SessionOptions_destroy(session_options)
    session
end

function open_service(session,name)
    blpapi_Session_openService(session,name)
    service = @with_pointer service blpapi_Session_getService(session,service,name)
    @printf "SERVICE:   %s\n" blpapi_Service_name(service)
    list_service_operations(service)
    list_service_events(service)
    service
end

function list_service_operations(service)
    for i = 0:(blpapi_Service_numOperations(service)-1)
        oper = @with_pointer oper blpapi_Service_getOperationAt(service,oper,i)
        @printf "Operation: %s\n" blpapi_Operation_name(oper)
    end
end

function get_name_and_destroy(x)
    name = blpapi_Name_string(x)
    blpapi_Name_destroy(x)
    name
end

function list_service_events(service)
    for i = 0:(blpapi_Service_numEventDefinitions(service)-1)
        event = @with_pointer event blpapi_Service_getEventDefinitionAt(service,event,i)
        @printf "Event:     %s\n" get_name_and_destroy(blpapi_SchemaElementDefinition_name(event))
    end
end

"Open a Bloomberg API session. The hostname and port can be specified if required."
function bopen(;host::String="",port::Int=0)
    global session
    global services
    if session == nothing
        version = get_version()
        @printf "BLPAPI DLL version %d.%d.%d.%d\n" version[1] version[2] version[3] version[4]
        services = Dict()
        session = create_session(host=host,port=port)
        blpapi_Session_start(session)
        for name = ["refdata", "apiflds", "instruments", "mktdata", "mktbar", "mktvwap"]
            services[name] = open_service(session,"//blp/"*name)
        end
        retrieve_response(2)
    else
        error("already connected!")
    end
    nothing
end

"Close the current session."
function bclose()
    global session
    global services
    if session == nothing
        error("not connected!")
    else
        blpapi_Session_stop(session)
        # for service = values(services); blpapi_Service_release(service); end
        blpapi_Session_destroy(session)
        services = nothing
        session = nothing
    end
end
