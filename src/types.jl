"""Object life cycle framework

This is interface for handling the life cycle context of an object.
"""
module LifeCycle
    "Abstract life cycle object"
    abstract Object

    @enum(State,
        INITIALIZED,# Initialized but not yet started.
        STARTING,   # In the process of starting.
        STARTED,    # Has started.
        STOPPING,   # Stopping is in progress.
        STOPPED,    # Has stopped.
        INVALID)    # Something happened

    doc"""Life cycle states enumeration"""
    State
end

"Starts a life cycle"
start{T<:LifeCycle.Object}(lco::T) = throw(AssertionError("Function 'start' is not implemented for type $(typeof(lco))"))

"Stops a life cycle"
stop{T<:LifeCycle.Object}(lco::T) = throw(AssertionError("Function 'stop' is not implemented for type $(typeof(lco))"))

"Returns a life cycle state"
state{T<:LifeCycle.Object}(lco::T) = isdefined(lco, :state) ? lco.state : throw(AssertionError("Field 'state' is not defined in type $(typeof(lco))"))

"Sets a life cycle state"
state!{T<:LifeCycle.Object}(lco::T, st::LifeCycle.State) = isdefined(lco, :state) ? (lco.state = st) : throw(AssertionError("Field 'state' is not defined in type $(typeof(lco))"))


""" Abstract log message

Message implementations that can be logged. Messages can act as wrappers
around objects so that user can have control over converting objects to strings
when necessary without requiring complicated formatters and as a way to manipulate
the message based on information available at runtime such as the locale of the system.
"""
abstract Message
typealias MESSAGE Nullable{Message}

""" Returns message format as string. """
format(msg::Message)     = throw(AssertionError("Function 'format' is not implemented"))

""" Returns message formatted as string. """
formatted(msg::Message)  = throw(AssertionError("Function 'formatted' is not implemented"))

""" Returns message parameters, if any. """
parameters(msg::Message) = throw(AssertionError("Function 'parameters' is not implemented"))


""" Log event

Provides contextual information about a logged message.
"""
abstract Event

""" Returns the fully qualified module name (FQMN) of the caller of the logging API """
fqmn(evnt::Event) = isdefined(evnt, :fqmn) ? evnt.fqmn : throw(AssertionError("Define field or method 'fqmn' in type $(typeof(evnt))"))

""" Gets the level. """
level(evnt::Event) = isdefined(evnt, :level) ? evnt.level : throw(AssertionError("Define field or method 'level' in type $(typeof(evnt))"))

""" Gets the logger name. """
logger(evnt::Event) = isdefined(evnt, :logger) ? evnt.logger : throw(AssertionError("Define field or method 'logger' in type $(typeof(evnt))"))

""" Gets the Marker associated with the event. """
marker(evnt::Event) = isdefined(evnt, :marker) ? evnt.marker : throw(AssertionError("Define field or method 'marker' in type $(typeof(evnt))"))

""" Gets the message associated with the event. """
message(evnt::Event) = isdefined(evnt, :message) ? evnt.message : throw(AssertionError("Define field or method 'message' in type $(typeof(evnt))"))

""" Gets event timestamp. """
timestamp(evnt::Event) = isdefined(evnt, :timestamp) ? evnt.timestamp : throw(AssertionError("Define field or method 'timestamp' in type $(typeof(evnt))"))


""" Abstract layout

Lays out a `Event` in different formats.
"""
abstract Layout
typealias LAYOUT Nullable{Layout}

""" Returns the header as byte array for the layout format. """
header(lyt::Layout) = throw(AssertionError("Function 'header' is not implemented for type $(typeof(lyt))"))

""" Returns the footer as byte array for the layout format. """
footer(lyt::Layout) = throw(AssertionError("Function 'footer' is not implemented for type $(typeof(lyt))"))

"""
    serialize(lyt::Layout, evnt::Event) -> Vector{UInt8}

Formats the even suitable for display into byte array.
"""
serialize(lyt::Layout, evnt::Event) = throw(AssertionError("Function 'serialize' is not implemented for type $(typeof(lyt))"))
serialize(lyt::LAYOUT, evnt::Event) = !isnull(lyt) ? serialize(get(lyt), evnt) : convert(Vector{UInt8}, "No layout present!")


""" Returns the content type output by this layout """
contenttype(lyt::Layout) = throw(
    AssertionError("""\n
        Every layout should provide a content type.
        Implement function `contenttype` for type $(typeof(lyt))
        that returns a proper content type (e.g. "text/plain")
    """))


""" Abstract type for layouts that result in a String """
abstract StringLayout <: Layout
contenttype(lyt::StringLayout) = "text/plain"

"""
    string(lyt::Layout, evnt::Event) -> AbstractString

Formats the even suitable for display into string.
"""
string(lyt::StringLayout, evnt::Event) = throw(AssertionError("Function 'string' is not implemented for type $(typeof(lyt))"))
string(lyt::LAYOUT, evnt::Event) = !isnull(lyt) ? string(get(lyt), evnt) : "No layout present!"


""" Abstract event filter """
abstract Filter <: LifeCycle.Object
typealias FILTER Nullable{Filter}

""" Supports event filtering

All filterable types should have `state::LifeCycle.State` and `filter::FILTER` fields.
"""
abstract Filterable <: LifeCycle.Object

module FilterResult
    @enum ResultType ACCEPT NEUTRAL DENY
end

""" Returns `FILTER` object """
filter(fltrbl::Filterable) = isdefined(fltrbl, :filter) ? fltrbl.filter : throw(AssertionError("Define field 'filter' in type $(typeof(fltrbl))"))
"""Determines if the event should be filtered.
Returns `true` if the event should be filtered, `false` otherwise.
"""
isfiltered(flt::FILTER, evnt::Event) = !isnull(flt) && filter(get(flt), evnt) == FilterResult.DENY
isfiltered(fltrbl::Filterable, evnt::Event) = isfiltered(filter(fltrbl), evnt)

""" Abstract appender

Any appender implementation must have two fields:

- `name`::AbstractString - appender name for reference
- `layout`::Nullable{`Layout`} - layout object for output modification

In addition to basic fields, every appender should have a method `append!`:

- append!(apnd::`Appender`, evnt::`Event`) - appends event

*Note:* All derived types should have a constructor which accepts `Dict{Symbol,Any}` object as a parameter.
Passed dictionary object should contain various initialization parameters. One of the parameters should have a key `:layout` with `Layout` object as its value.
"""
abstract Appender <: Filterable
typealias APPENDER Nullable{Appender}
typealias APPENDERS Dict{AbstractString, Appender}

""" Returns name of the appender """
name(apnd::Appender) = isdefined(apnd, :name) ? apnd.name : throw(AssertionError("Define field 'name' in type $(typeof(apnd))"))

""" Returns layout of the appender """
layout(apnd::Appender) = isdefined(apnd, :layout) ? apnd.layout : throw(AssertionError("Define field 'layout' in type $(typeof(apnd))"))

""" Adds event to the appender """
append!(apnd::Appender, evnt::Event) = throw(AssertionError("Function 'append!' is not implemented for type $(typeof(apnd))"))

""" Ignore exception in appender.

Some appenders need to propagate exceptions back to the application.
When `ignoreexceptions` returns `false`, the exception will be allow to percolate.
"""
ignoreexceptions(apnd::Appender) = true

""" Abstract configuration

Any configuration type implementation must have two fields:

- `name`::AbstractString, the configuration name for a reference
- `source`::AbstractString, a source of the configuration
- `state`::LifeCycle.State, a life cycle state
- `root`::LoggerConfig, the root logger configuration

Any configuration must implement following set of methods:

- logger(Configuration, AbstractString) -> LoggerConfig
- appender(Configuration, AbstractString) -> Appender
- loggers(Configuration) -> Dict{AbstractString, LoggerConfig}
- appenders(Configuration) -> Dict{AbstractString, Appender}
"""
abstract Configuration <: Filterable
typealias CONFIGURATION Nullable{Configuration}

show(io::IO, cfg::Configuration) = print(io, """Configuration($(cfg.name), $(isempty(cfg.source) ? "" : cfg.source*", ")$(cfg.state))""")

"Configuration name for a reference"
name(cfg::Configuration) = isdefined(cfg, :name) ? cfg.name : throw(AssertionError("Define field 'name' in type $(typeof(cfg))"))

"Returns the source of this configuration"
source(cfg::Configuration) = isdefined(cfg, :source) ? cfg.source : throw(AssertionError("Define field 'source' in type $(typeof(cfg))"))

"Returns the root logger configuration"
root(cfg::Configuration) = isdefined(cfg, :root) ? cfg.root : throw(AssertionError("Define field 'root' in type $(typeof(cfg))"))

"Return a list of `Logger`s from the configuration"
loggers(cfg::Configuration) = throw(AssertionError("Function 'loggers' is not implemented for type $(typeof(cfg))"))

"Returns  `Appender`  with the specified `name`"
appender(cfg::Configuration, name::AbstractString) = throw(AssertionError("Function 'appender' is not implemented for type $(typeof(cfg))"))

"Returns a list of `Appender`s from the configuration"
appenders(cfg::Configuration) = throw(AssertionError("Function 'appenders' is not implemented for type $(typeof(cfg))"))


"""
Abstract Logger Type

All implementations of this type must have two methods:

- `name`, returns a logger name as string is needed to be implemented
- `message`, returns a message construction type (factory)
"""
abstract AbstractLogger

typealias LOGGERS Dict{AbstractString, AbstractLogger}

"Returns a factory type that generates messages"
message(lgr::AbstractLogger) = throw(AssertionError("Function 'message' is not implemented for type $(typeof(lgr))"))

"Returns a name of the logger"
name(lgr::AbstractLogger) = throw(AssertionError("Function 'name' is not implemented for type $(typeof(lgr))"))

"Returns a status level of the logger"
level(lgr::AbstractLogger) = throw(AssertionError("Function 'level' is not implemented for type $(typeof(lgr))"))

"Sets a status level of the logger"
level!(lgr::AbstractLogger, lvl::Level.EventLevel) = throw(AssertionError("Function 'level!' is not implemented for type $(typeof(lgr))"))


# Aliases
typealias MARKER Nullable{Symbol}
typealias FACTORY Nullable{DataType}
typealias NAME Nullable{AbstractString}
typealias PROPERTIES Dict{AbstractString, AbstractString}
