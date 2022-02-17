# Dtext: Industry proven formatter / logger

Dtext consist of a format package, offering similar capabilities to `std.format`,
and a `log` package, offering a powerful `Logger` class.

Both packages have been extracted from [ocean](https://github.com/sociomantic-tsunami/ocean/),
and have been used in real-time bidding applications for the better part of a decade.

## Formatter

The building block of Dtext is `dtext.format.Formatter`.
It is an implementation as a formatter that is guaranteed to minimally allocate,
and never under some circumstances.

It consists of a few overloads:
```D
/// Pedestrian `format`: Returns a new, GC-allocated string
public string format (Args...) (in char[] fmt, Args args);

/// Building block: Takes a delegate, allow to implement any allocation strategy,
/// including using `malloc` or one of Phobos' allocators
public bool sformat (Args...) (scope FormatterSink sink, in char[] fmt, Args args);

/// Similarly to `sprintf`, will write to `buffer` up to its available length
/// Does not allocate on its own, but might lead to GC allocations if `args`
/// has allocating `toString`.
public char[] snformat (Args...) (char[] buffer, in char[] fmt, Args args)

/// Will append (using `~=`) to `buffer`. Intended to be used with `assumeSafeAppend`.
public char[] sformat (Args...) (ref char[] buffer, in char[] fmt, Args args)
```

If you just intend to replace `std.format`, the basic `format` overload will work well.
`dtext`'s Formatter main utility however comes from its `sformat` overload,
which similarly to `formattedWrite` will output to a sink.

The Formatter uses a different format string than `std.format`:
Instead of following the `printf` convention, which makes little sense in the presence
of compiler-provided type information (as `[{s,sn}]format` use templates),
the simplest way to format an argument is to use `{}`, equivalent to `std.format`'s `%s`.
Double brace ("{{") is formatted as a single brace ("{"), positional arguments
(`assert(format("{2} {1} {0}", 1, 2, 3) == "3 2 1")`), width, and other options are available.

For more details, read [the module's extensive documentation](./source/dtext/format/Formatter.d).

## Logger

Like its Formatter, Dtext's Logger was built for real-time application.
As a result, message formatting takes place in a buffer (1024 chars by default, configurable)
using `snformat` and does not cause per-call invocation,
unless the arguments or `Appender` allocate.

`Logger` is a `class`, and each instance must have a name and belong to a `Hierarchy`.
A `Hierarchy` is built the same way as a module hierarchy is, using dot (`.`) as delimiter.

The common idiom that was used with Loggers was:
```D
module some.awesome.project;

import dtext.log.Logger;

private Logger log;

static this ()
{
    log = Log.lookup(__MODULE__);
}

void main ()
{
    log.info("The answer is: {}", 42);
}
```

In the above example, the first call to `Log.lookup` in the thread will allocate a new `Logger`,
subsequent calls will return the alread-instantiated `Logger`. Hierarchies are thread-local.
Looking up a parent is possible (e.g. `Log.lookup("some.awesome")`), and some configurations / operations
can be set to propagate to children (e.g. e.g. adding an `Appender` or setting a log level).

The root logger of the hierarchy is accessible via `Log.root`.

### Layout & Appenders

`Logger`s work in combination with two other classes: `Appender` and `Layout`.

An `Appender` defines *where* an event will go: this can be a file, the console,
`syslog`, or any custom logic (e.g. the [AppendSterrStdout appender](./source/dtext/log/AppendStderrStdout.d)
will append to `stdout` below a certain level, and to `stderr` afterwards).
A `Logger` can have multiple `Appender` (e.g. a `ConsoleAppender` and `FileAppender` are common),
and `Appender` can be set to propagate when added to parents. 

`Layout` define how the messages will be printed. The most basic layout, `LayoutSimple`,
will just print the event's message, but `log` calls also include the `Level` at which
the message was emitted, the `time`, logger's name, etc...

### Log levels

Loggers have 7 normal log levels: `Debug`, `Trace`, `Verbose`, `Info`, `Warn`, `Error`, `Fatal`,
in that order of importance. A special `None` value exists in `ILogger.Level` to disable any logging.
The `dtext.log.ILogger : ILogger.Level` is aliased as `dtext.log.Logger : Level`.

Each log level has a corresponding lowercase function: `Logger.info`, `Logger.fatal`, etc...
Due to `Debug` being a keyword, the matching function is `Logger.dbg`.
Providing a log level at runtime can be done via `Logger.format(loglevel, format, args)`.

If a `Logger` is `enabled` for a certain level, messages of a higher levels will be emitted,
but messages for a lower level will be discarded without being formatted.
For example, for a `Logger` that is enabled for `Verbose` level,
calling `log.trace` will be  a no-op.

The default `Level` is `Level.Info`.
