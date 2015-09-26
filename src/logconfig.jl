"Logger configuration"
type LoggerConfig
    name::AbstractString
    level::LEVEL
    additive::Bool

    appenders::Dict{AbstractString, Appenders.Reference}
    parent::Nullable{LoggerConfig}
    event::FACTORY
    includelocation::Bool
    #TODO: properties::Dict{Property, Bool}
    #TODO: filter::Filter
end

typealias LOGCONFIGS Dict{AbstractString, LoggerConfig}

# Constructors
function LoggerConfig(name::AbstractString, level::LEVEL, additive::Bool)
    return LoggerConfig(name, level, additive, APPENDERS(),
                        Nullable{LoggerConfig}(), FACTORY(LOG4JL_LOG_EVENT), true)
end
function LoggerConfig(name::AbstractString, level::Level.EventLevel,
                      appenders::APPENDERS=APPENDERS(), additive::Bool = true)
    return LoggerConfig(name, LEVEL(level), additive, appenders,
                        Nullable{LoggerConfig}(), FACTORY(LOG4JL_LOG_EVENT), true)
end
LoggerConfig(level::Level.EventLevel) = LoggerConfig("", level)
LoggerConfig() = LoggerConfig(LOG4JL_DEFAULT_STATUS_LEVEL)

"Returns the logger name"
name(lc::LoggerConfig) = lc.name

"Returns the logging level"
level(lc::Nullable{LoggerConfig}) = isnull(lc) ? LOG4JL_DEFAULT_STATUS_LEVEL : level(get(lc))
level(lc::LoggerConfig) = get(lc.level, level(lc.parent))

"Returns the value of the additive flag"
isadditive(lc::LoggerConfig) = lc.additive

"Logs an event"
function log(lc::LoggerConfig, evnt::Event)
    map(ref->append!(ref, evnt), values(lc.appenders))
    lc.additive && !isnull(lc.parent) && log(get(lc.parent), evnt)
end
function log(lc::LoggerConfig, logger, fqmn, level, marker, msg)
    log(lc, call(LOG4JL_LOG_EVENT, logger, fqmn, marker, level, msg)) #TODO: properties
end

show(io::IO, lc::LoggerConfig) = print(io, "LoggerConfig(", isempty(lc.name) ? "root" : lc.name, ":", level(lc) , ")")

"Check if message could be filtered based on its parameters"
function isenabled(lc::LoggerConfig, lvl, marker, msg, params...)
    level(lc) > lvl && return false
    #TODO: add filters by marker and message content
    return true
end

"Adds an appender reference to configuration"
function reference(lc::LoggerConfig, apndr::Appender, lvl::LEVEL=LEVEL(), filter::FILTER=FILTER())
    apn = name(apndr)
    lvl = get(lvl, Level.ALL)
    lc.appenders[apn] = Appenders.Reference(apndr, lvl, filter)
end