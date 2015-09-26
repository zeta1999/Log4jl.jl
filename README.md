# Log4jl - a logging framework for Julia

[![Build Status](https://travis-ci.org/wildart/Log4jl.jl.svg?branch=master)](https://travis-ci.org/wildart/Log4jl.jl)[![Coverage Status](https://coveralls.io/repos/wildart/Log4jl.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/wildart/Log4jl.jl?branch=master)

**Log4jl** is a comprehensive and flexible logging framework for Julia programs.

## Usage

To create logger call `@Log4jl.logger` macro after importing `Log4jl` module.
This macro call initializes and configures the logging framework. Also it creates logger object which cab be used by any of logging functions or macros to perform logging operations.

```julia
using Log4jl

const logger = @Log4jl.logger

error(logger, "Error in my code")

# or

@error "Error in my code"
```

See usage in [example/simple.jl](example/simple.jl).

**Note:** If you use logging macros, make sure that constant `logger` exists in your current module.

## Dev Notes

### Architecture
[Log4jl](http://github.comwildart/Log4jl.jl) has similar architecture as [Apache Log4j 2](http://logging.apache.org/log4j/2.x/manual/architecture.html) framework.

- Loggers are wrappers around configuration
- Loggers would change behavior if configuration is changed
- Logger hierarchy based on hierarchy of configurations
- Global logger context keeps track of all loggers
- Root logger has no name and additivity, its default level is ERROR
- Logging functions support:
    - plaint text
    - markers
    - objects

### Implementation details
- 'isenabled' checks if logger allowed to process event at specified level

### Missing
- On-fly reconfiguration
- Multi-threading/processing support
- Custom log levels
- Filters
    - Accept: no filters called, accept event
    - Deny: ignore event, return to caller
    - Neutral: pass event to other filters
- Lookups
- Appended additivity: event processed by logger and all its ancestors.
- Configuration formats: JSON, XML, DSL (macro based)
- Handle configuration recursion

### Logger

In order to create logger, call macro `@Log4jl.logger [<name>] [MSG=<message_type>] [URI=<config_location>] [begin <config_code_block> end]`.

```julia
# get the root logger
const logger = @Log4jl.rootlogger

# get the configured logger by name (uses FQMN by default)
const logger = @Log4jl.logger

# get the configured logger by name explicitly
const logger = @Log4jl.logger "TestLogger"

# get the configured logger by name that will use parameterized messages
const logger = @Log4jl.logger "TestLogger" MSG=ParameterizedMessage

# get the configured logger by from file specified in the parameter
const logger = @Log4jl.logger URI="myconfig.xml"

# get the configured logger from a programmatic configuration
const logger = @Log4jl.logger begin
    Configuration("Custom",
        PROPERTIES(),
        APPENDERS(),
        LOGCONFIGS()
    )
end
```

Macro `@Log4jl.logger` creates logger instance. It accepts following parameters:

1. `name`: a string which specifies a logger name from a configuration
2. `MSG=<message_type>`: a message type used for configuring a logger
3. `URI=<config_location>`: a configuration location
4. `begin <configuration> end`: a configuration program (must return `Configuration` object)

If the root logger is required use macro `Log4jl.rootlogger` with the same parameters as for `Log4jl.logger` with one exception: root logger does not have a name.

The default configuration file is `log4jl.*`. An extension of the configuration file determines format in which configuration is described.

Currently supported configuration formats: YAML.

Configuration file should be located in:
- For stand-alone module: a directory where a source code file of the module is located.
- For package: a package root directory.

### Message

- For custom formated messages, create two functions with the same name and following signatures:
    - <message_type_function>(msg::AbstractString, params...) => Message
    - <message_type_function>(msg::Any) => Message

## Loading sequence

1. Module `Log4jl` is referenced
2. Function `Log4jl.__init__` is called
    1. A logger context selector is initialized as object and assigned to global constant `LOG4JL_CONTEXT_SELECTOR` from an environment variable with the same name. Default context selector type is `Log4jl.ModuleContextSelector`.
    2. Default status level is initialized as `LOG4JL_DEFAULT_STATUS_LEVEL` global constant from an environment variable with the same name.  Default status level is `Log4jl.Level.ERROR`.
    3. A logger event type is is initialized as `LOG4JL_LOG_EVENT` global constant from an environment variable with the same name. Default logger event type is `Log4jl.Log4jlEvent`.
3. Macro `Log4jl.logger` is called with(out) parameters
    1. Parameters parsed
    2. Context selector is used to create a logging context
    3. Configuration is created
        a. Programmatic configuration is evaluated
        b. Configuration file is located, loaded and parsed
    4. Logging context is initialized with the created configuration
    5. Logging context is started
        1. Shutdown hook is created.
    6. Configuration is started
        1. Configuration is setup (properties and appenders are created)
        2. Configuration is configured (loggers are created and referenced to appenders)
        3. All appenders are started
    7. Logging context used to create a logger wrapper
    8. Logger object is returned
4. Logger object is used in logging functions.

## Shutdown sequence

TODO: proper shutdown when `workspace` is called.