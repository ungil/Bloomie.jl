# datatypes

mutable struct blpapi_CorrelationId
    # unsigned int  size:8;       // fill in the size of this struct
    # unsigned int  valueType:4;  // type of value held by this correlation id
    # unsigned int  classId:16;   // user defined classification id
    # unsigned int  reserved:4;   // for internal use must be 0
    size_valueType_classId_reserved::UInt32
    value::UInt64 # union not supported
end

mutable struct blpapi_Datetime
    parts::UInt8
    hours::UInt8
    minutes::UInt8
    seconds::UInt8
    milliSeconds::UInt16
    month::UInt8
    day::UInt8
    year::UInt16
    offset::Int16
end

# macros

function blpapi_getLastErrorDescription(resultCode)
    unsafe_string(ccall((:blpapi_getLastErrorDescription, :blpapi3_64), Cstring, (Cint,), Int32(resultCode)))
end

macro check(fn)
    quote
        res = $(esc(fn))
        if res > 0; error(blpapi_getLastErrorDescription(res)); end
    end
end

macro with_pointer(var,body)
    quote
        $(esc(var)) = Ref{Ptr{Void}}(0)
        $(esc(body))
        $(esc(var))[]
    end
end

# session

function blpapi_getVersionInfo(majorVersion, minorVersion, patchVersion, buildVersion)
    ccall((:blpapi_getVersionInfo, :blpapi3_64), Void, (Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}), majorVersion, minorVersion, patchVersion, buildVersion)
end

function blpapi_EventDispatcher_create(numDispatcherThreads)
    ccall((:blpapi_EventDispatcher_create, :blpapi3_64), Ptr{Void}, (Cint,), Int32(numDispatcherThreads))
end

function blpapi_SessionOptions_create()
    ccall((:blpapi_SessionOptions_create, :blpapi3_64), Ptr{Void}, ())
end

function blpapi_SessionOptions_destroy(parameters)
    ccall((:blpapi_SessionOptions_destroy, :blpapi3_64), Void, (Ptr{Void},), parameters)
end

function blpapi_SessionOptions_setServerHost(parameters, serverHost)
    @check ccall((:blpapi_SessionOptions_setServerHost, :blpapi3_64), Cint, (Ptr{Void}, Cstring), parameters, serverHost)
end

function blpapi_SessionOptions_setServerPort(parameters, serverPort)
    @check ccall((:blpapi_SessionOptions_setServerPort, :blpapi3_64), Cint, (Ptr{Void}, UInt16), parameters, UInt16(serverPort))
end

function blpapi_Session_create(parameters, handler, dispatcher, userData)
    ccall((:blpapi_Session_create, :blpapi3_64), Ptr{Void}, (Ptr{Void}, Ptr{Void}, Ptr{Void}, Ptr{Void}), parameters, handler, dispatcher, userData)
end

function blpapi_Session_destroy(session)
    ccall((:blpapi_Session_destroy, :blpapi3_64), Void, (Ptr{Void},), session)
end

function blpapi_Session_start(session)
    @check ccall((:blpapi_Session_start, :blpapi3_64), Cint, (Ptr{Void},), session)
end

function blpapi_Session_stop(session)
    @check ccall((:blpapi_Session_stop, :blpapi3_64), Cint, (Ptr{Void},), session)
end

function blpapi_Session_getService(session, service, serviceName)
    @check ccall((:blpapi_Session_getService, :blpapi3_64), Cint, (Ptr{Void}, Ref{Ptr{Void}}, Cstring), session, service, serviceName)
end

function blpapi_Session_openService(session, serviceName)
    @check ccall((:blpapi_Session_openService, :blpapi3_64), Cint, (Ptr{Void}, Cstring), session, serviceName)
end

function blpapi_Service_name(service)
    unsafe_string(ccall((:blpapi_Service_name, :blpapi3_64), Cstring, (Ptr{Void},), service))
end

function blpapi_Service_release(service)
    ccall((:blpapi_Service_release, :blpapi3_64), Void, (Ptr{Void},), service)
end

function blpapi_Service_numOperations(service)
    ccall((:blpapi_Service_numOperations, :blpapi3_64), Cint, (Ptr{Void},), service)
end

function blpapi_Service_numEventDefinitions(service)
    ccall((:blpapi_Service_numEventDefinitions, :blpapi3_64), Cint, (Ptr{Void},), service)
end

function blpapi_Service_getOperationAt(service, operation, index)
    @check ccall((:blpapi_Service_getOperationAt, :blpapi3_64), Cint, (Ptr{Void}, Ref{Ptr{Void}}, Cint), service, operation, Int32(index))
end

function blpapi_Service_getEventDefinitionAt(service, result, index)
    @check ccall((:blpapi_Service_getEventDefinitionAt, :blpapi3_64), Cint, (Ptr{Void}, Ref{Ptr{Void}}, Cint), service, result, Int32(index))
end

function blpapi_Operation_name(service)
    unsafe_string(ccall((:blpapi_Operation_name, :blpapi3_64), Cstring, (Ptr{Void},), service))
end

function blpapi_SchemaElementDefinition_name(field)
    ccall((:blpapi_SchemaElementDefinition_name, :blpapi3_64), Ptr{Void}, (Ptr{Void},), field)
end

function blpapi_Name_string(name)
    unsafe_string(ccall((:blpapi_Name_string, :blpapi3_64), Cstring, (Ptr{Void},), name))
end

function blpapi_Name_destroy(name)
    ccall((:blpapi_Name_destroy, :blpapi3_64), Void, (Ptr{Void},), name)
end

# response

function blpapi_Session_nextEvent(session, eventPointer, timeoutInMilliseconds)
    @check ccall((:blpapi_Session_nextEvent, :blpapi3_64), Cint, (Ptr{Void}, Ref{Ptr{Void}}, UInt32), session, eventPointer, UInt32(timeoutInMilliseconds))
end

function blpapi_Event_eventType(event)
    ccall((:blpapi_Event_eventType, :blpapi3_64), Cint, (Ptr{Void},), event)
end

function blpapi_Event_release(event)
    @check ccall((:blpapi_Event_release, :blpapi3_64), Cint, (Ptr{Void},), event)
end

function blpapi_Element_getValueAsBool(element, buffer, index)
    @check ccall((:blpapi_Element_getValueAsBool, :blpapi3_64), Cint, (Ptr{Void}, Ref{Int32}, Cint), element, buffer, Int32(index))
end

function blpapi_Element_getValueAsInt32(element, buffer, index)
    @check ccall((:blpapi_Element_getValueAsInt32, :blpapi3_64), Cint, (Ptr{Void}, Ref{Int32}, Cint), element, buffer, Int32(index))
end

function blpapi_Element_getValueAsInt64(element, buffer, index)
    @check ccall((:blpapi_Element_getValueAsInt64, :blpapi3_64), Cint, (Ptr{Void}, Ref{Int64}, Cint), element, buffer, Int32(index))
end

function blpapi_Element_getValueAsFloat32(element, buffer, index)
    @check ccall((:blpapi_Element_getValueAsFloat32, :blpapi3_64), Cint, (Ptr{Void}, Ref{Float32}, Cint), element, buffer, Int32(index))
end

function blpapi_Element_getValueAsFloat64(element, buffer, index)
    @check ccall((:blpapi_Element_getValueAsFloat64, :blpapi3_64), Cint, (Ptr{Void}, Ref{Float64}, Cint), element, buffer, Int32(index))
end

function blpapi_Element_getValueAsString(element, buffer, index)
    @check ccall((:blpapi_Element_getValueAsString, :blpapi3_64), Cint, (Ptr{Void}, Ref{Ptr{UInt8}}, Cint), element, buffer, Int32(index))
end

function blpapi_Element_getValueAsDatetime(element, buffer, index)
    @check ccall((:blpapi_Element_getValueAsDatetime, :blpapi3_64), Cint, (Ptr{Void}, Ref{blpapi_Datetime}, Cint), element, buffer, Int32(index))
end

function blpapi_Element_datatype(element)
    ccall((:blpapi_Element_datatype, :blpapi3_64), Cint, (Ptr{Void},), element)
end

function blpapi_Element_isArray(element)
    ccall((:blpapi_Element_isArray, :blpapi3_64), Cint, (Ptr{Void},), element)
end

function blpapi_Element_nameString(element)
    unsafe_string(ccall((:blpapi_Element_nameString, :blpapi3_64), Cstring, (Ptr{Void},), element))
end

function blpapi_Element_numValues(element)
    ccall((:blpapi_Element_numValues, :blpapi3_64), Cint, (Ptr{Void},), element)
end

function blpapi_Element_numElements(element)
    ccall((:blpapi_Element_numElements, :blpapi3_64), Cint, (Ptr{Void},), element)
end

function blpapi_Element_getElementAt(element, result, position)
    @check ccall((:blpapi_Element_getElementAt, :blpapi3_64), Cint, (Ptr{Void}, Ref{Ptr{Void}}, Cint), element, result, Int32(position))
end

function blpapi_Element_getValueAsElement(element, buffer, index)
    @check ccall((:blpapi_Element_getValueAsElement, :blpapi3_64), Cint, (Ptr{Void}, Ref{Ptr{Void}}, Cint), element, buffer, Int32(index))
end

function blpapi_Element_hasElement(element, nameString, name)
    Bool(ccall((:blpapi_Element_hasElement, :blpapi3_64), Cint, (Ptr{Void}, Cstring, Ptr{Void}), element, nameString, name))
end

function blpapi_Element_appendElement(element, appendedElement)
    @check ccall((:blpapi_Element_appendElement, :blpapi3_64), Cint, (Ptr{Void}, Ref{Ptr{Void}}), element, appendedElement)
end

function blpapi_Element_getChoice(element, result)
    @check ccall((:blpapi_Element_getChoice, :blpapi3_64), Cint, (Ptr{Void}, Ref{Ptr{Void}}), element, result)
end

function blpapi_MessageIterator_create(event)
    ccall((:blpapi_MessageIterator_create, :blpapi3_64), Ptr{Void}, (Ptr{Void},), event)
end

function blpapi_MessageIterator_destroy(iterator)
    ccall((:blpapi_MessageIterator_destroy, :blpapi3_64), Void, (Ptr{Void},), iterator)
end

function blpapi_Message_numCorrelationIds(message)
    ccall((:blpapi_Message_numCorrelationIds, :blpapi3_64), Cint, (Ptr{Void},), message)
end

function blpapi_Message_correlationId(message, index)
    ccall((:blpapi_Message_correlationId, :blpapi3_64), blpapi_CorrelationId, (Ptr{Void}, Cint), message, Int32(index))
end

function blpapi_Message_elements(message)
    ccall((:blpapi_Message_elements, :blpapi3_64), Ptr{Void}, (Ptr{Void},), message)
end

function blpapi_Message_typeString(message)
    unsafe_string(ccall((:blpapi_Message_typeString, :blpapi3_64), Cstring, (Ptr{Void},), message))
end

function blpapi_Message_release(message)
    @check ccall((:blpapi_Message_release, :blpapi3_64), Cint, (Ptr{Void},), message)
end

function blpapi_MessageIterator_next(iterator, result)
    @check ccall((:blpapi_MessageIterator_next, :blpapi3_64), Cint, (Ptr{Void}, Ref{Ptr{Void}}), iterator, result)
end

# request

function blpapi_Element_getElement(element, result, nameString, name)
    @check ccall((:blpapi_Element_getElement, :blpapi3_64), Cint, (Ptr{Void}, Ref{Ptr{Void}}, Cstring, Ptr{Void}), element, result, nameString, name)
end

function blpapi_Element_setElementString(element, nameString, name, value)
    @check ccall((:blpapi_Element_setElementString, :blpapi3_64), Cint, (Ptr{Void}, Cstring, Ptr{Void}, Cstring), element, nameString, name, value)
end

function blpapi_Element_setElementInt32(element, nameString, name, value)
    @check ccall((:blpapi_Element_setElementInt32, :blpapi3_64), Cint, (Ptr{Void}, Cstring, Ptr{Void}, Int32), element, nameString, name, Int32(value))
end

function blpapi_Element_setValueString(element, value, index)
    @check ccall((:blpapi_Element_setValueString, :blpapi3_64), Cint, (Ptr{Void}, Cstring, Cint), element, value, Int32(index))
end

function blpapi_Session_sendRequest(session, request, correlationId, identity, eventQueue, requestLabel, requestLabelLen)
    @check ccall((:blpapi_Session_sendRequest, :blpapi3_64), Cint, (Ptr{Void}, Ptr{Void}, Ref{blpapi_CorrelationId}, Ptr{Void}, Ptr{Void}, Cstring, Cint), session, request, correlationId, identity, eventQueue, requestLabel, Int32(requestLabelLen))
end

function blpapi_Service_createRequest(service, request, operation)
    @check ccall((:blpapi_Service_createRequest, :blpapi3_64), Cint, (Ptr{Void}, Ref{Ptr{Void}}, Cstring), service, request, operation)
end

function blpapi_Request_elements(request)
    ccall((:blpapi_Request_elements, :blpapi3_64), Ptr{Void}, (Ptr{Void},), request)
end

function blpapi_Request_destroy(request)
    ccall((:blpapi_Request_destroy, :blpapi3_64), Void, (Ptr{Void},), request)
end
