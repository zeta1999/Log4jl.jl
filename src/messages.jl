module Messages

    using Log4jl: Message
    import Log4jl: format, formatted, parameters

    "Message with raw objects"
    type ObjectMessage <: Message
        message::Any
    end
    formatted(msg::ObjectMessage)  = string(msg.message)
    format(msg::ObjectMessage)     = formatted(msg)
    parameters(msg::ObjectMessage) = Any[msg.message]
    show(io::IO, msg::ObjectMessage) = print(io, "ObjectMessage[message=",msg.message,']')


    "Message handles everything as string."
    type SimpleMessage <: Message
        message::AbstractString
        SimpleMessage(msg::AbstractString, params...) = new(msg)
    end
    SimpleMessage(msg::Any) = ObjectMessage(msg)
    formatted(msg::SimpleMessage)  = msg.message
    format(msg::SimpleMessage)     = msg.message
    parameters(msg::SimpleMessage) = nothing
    show(io::IO, msg::SimpleMessage) = print(io, "SimpleMessage[message=",msg.message,']')


    "Message pattern contains placeholders indicated by '{}'"
    type ParameterizedMessage <: Message
        pattern::AbstractString
        params::Vector{Any}
        ParameterizedMessage(ptrn::AbstractString, params...) = new(ptrn, [params...])
    end
    ParameterizedMessage(msg::Any) = ObjectMessage(msg)
    function formatted(msg::ParameterizedMessage)
        length(msg.params) == 0 && return msg.pattern
        offs = map(ss->ss.offset, matchall(r"({})+",msg.pattern))
        @assert length(offs) == length(msg.params) "Pattern does not match parameters"
        sstart = 1
        sformatted = ""
        for (i,send) in enumerate(offs)
            sformatted *= msg.pattern[sstart:send]
            sformatted *= string(msg.params[i])
            sstart = send+3
        end
        sformatted * msg.pattern[sstart:end]
    end
    format(msg::ParameterizedMessage)     = msg.pattern
    parameters(msg::ParameterizedMessage) = msg.params
    show(io::IO, msg::ParameterizedMessage) =
        print(io, "ParameterizedMessage[pattern='",msg.pattern,"', args=",msg.params,']')


    "Message pattern contains 'printf' format string"
    type PrintfFormattedMessage <: Message
        pattern::AbstractString
        params::Vector{Any}
        PrintfFormattedMessage(ptrn::AbstractString, params...) = new(ptrn, [params...])
    end
    PrintfFormattedMessage(msg::Any) = ObjectMessage(msg)
    formatted(msg::PrintfFormattedMessage)  = @eval @sprintf($(msg.pattern), $(msg.params)...)
    format(msg::PrintfFormattedMessage)     = msg.pattern
    parameters(msg::PrintfFormattedMessage) = msg.params
    show(io::IO, msg::PrintfFormattedMessage) =
        print(io, "PrintfFormattedMessage[pattern='",msg.pattern,"', args=",msg.params,']')


    #TODO: MapMessage: XML, JSON, Dict
    #TODO: StructuredDataMessage: RFC 5424

    export ObjectMessage, SimpleMessage, ParameterizedMessage, PrintfFormattedMessage

end
