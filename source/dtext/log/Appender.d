/*******************************************************************************

    Define the base classes for all Appenders

    Appenders are objects that are responsible for emitting messages sent
    to a particular logger. There may be more than one appender attached
    to any logger.
    The actual message is constructed by another class known as an EventLayout.

    Copyright:
        Copyright (c) 2004 Kris Bell.
        Some parts copyright (c) 2009-2016 dunnhumby Germany GmbH.
        All rights reserved.

    License:
        Tango Dual License: 3-Clause BSD License / Academic Free License v3.0.
        See LICENSE_TANGO.txt for details.

*******************************************************************************/

module dtext.log.Appender;

import dtext.format.Formatter;
import dtext.log.Event;
import dtext.log.ILogger;

version (unittest)
{
    import dtext.Test;
    import dtext.log.Hierarchy;
    import dtext.log.Logger;
}

/// Base class for all Appenders
public class Appender
{
    /// BitMask used for registration
    public alias Mask = ulong;

    private Appender        next_;
    private ILogger.Level   level_;
    private Layout          layout_;
    private static Layout   generic;

    /***************************************************************************

        Interface for all logging layout instances

        Implement this method to perform the formatting of message content.

    ***************************************************************************/

    public interface Layout
    {
        /// Convenience alias for implementing classes
        protected alias FormatterSink = .FormatterSink;

        /***********************************************************************

            Format the provided `event` to the `sink` using `this` layout

            Params:
              event = The log event to format
              sink = Where to output the result

        ***********************************************************************/

        void format (LogEvent event, scope FormatterSink sink);
    }

    /***************************************************************************

        Return the mask used to identify this Appender.

        The mask is used to figure out whether an appender has already been
        invoked for a particular logger.

    ***************************************************************************/

    abstract Mask mask ();

    /// Return the name of this Appender.
    abstract string name ();

    /***************************************************************************

        Append a message to the output.

        The event received is only valid for the duration of the `apppend`
        call and shouldn't outlive the scope of `append`.
        Moreover, as `Logger` use a class-local buffer, its tracing functions
        which use formatting are not re-entrant and should not be called
        from here.

        Params:
            event = Event to log

    ***************************************************************************/

    abstract void append (LogEvent event);

    /// Create an Appender and default its layout to LayoutTimer.
    public this ()
    {
        if (generic is null)
            generic = new LayoutTimer;
        this.layout_ = generic;
    }

    /// Return the current Level setting
    final ILogger.Level level ()
    {
        return this.level_;
    }

    /// Return the current Level setting
    final Appender level (ILogger.Level l)
    {
        this.level_ = l;
        return this;
    }

    /***************************************************************************

        Static method to return a mask for identifying the Appender.

        Each Appender class should have a unique fingerprint so that we can
        figure out which ones have been invoked for a given event.
        A bitmask is a simple an efficient way to do that.

    ***************************************************************************/

    protected Mask register (string tag)
    {
        static Mask mask = 1;
        static Mask[string] registry;

        Mask* p = tag in registry;
        if (p)
            return *p;
        else
        {
            auto ret = mask;
            registry[tag] = mask;

            assert(mask > 0, "Too many unique registrations");

            mask <<= 1;
            return ret;
        }
    }

    /***************************************************************************

        Set the current layout to be that of the argument, or the generic layout
        where the argument is null

    ***************************************************************************/

    void layout (Layout how)
    {
        assert(generic !is null);
        this.layout_ = how ? how : generic;
    }

    /// Return the current Layout
    Layout layout ()
    {
        return this.layout_;
    }

    /// Attach another appender to this one
    void next (Appender appender)
    {
        this.next_ = appender;
    }

    /// Return the next appender in the list
    Appender next ()
    {
        return this.next_;
    }

    /// Close this appender. This would be used for file, sockets, and the like
    void close ()
    {
    }
}


/*******************************************************************************

    An appender that does nothing.

    This is useful for cutting and pasting, and for benchmarking the ocean.log
    environment.

*******************************************************************************/

public class AppendNull : Appender
{
    private Mask mask_;

    /// Create with the given Layout
    this (Layout how = null)
    {
        this.mask_ = this.register(name);
        this.layout(how);
    }

    /// Return the fingerprint for this class
    final override Mask mask ()
    {
        return this.mask_;
    }

    /// Return the name of this class
    final override string name ()
    {
        return this.classinfo.name;
    }

    /// Append an event to the output
    final override void append (LogEvent event)
    {
        this.layout.format(event, (in char[]) {});
    }
}

/*******************************************************************************

    A simple layout comprised only of time(ms), level, name, and message

*******************************************************************************/

public class LayoutTimer : Appender.Layout
{
    /***************************************************************************

        Subclasses should implement this method to perform the formatting
         of the actual message content.

    ***************************************************************************/

    public override void format (LogEvent event, scope FormatterSink dg)
    {
        sformat(dg, "{} {} [{}] {}- {}", event.span, ILogger.convert(event.level),
            event.name, event.host.label, event.msg);
    }
}

unittest
{
    import core.time;

    auto result = new char[](2048);
    result.length = 0;
    assumeSafeAppend(result);

    scope dg = (in char[] v) { result ~= v; };
    scope layout = new LayoutTimer();
    LogEvent event = {
        level: ILogger.Level.Warn,
        name: "Barney",
        host: new Hierarchy("test"),
// https://github.com/dlang/druntime/pull/3752
//        time: LogEvent.startTime + 420.msecs,
        time: LogEvent.startTime,
        msg: "Have you met Ted?",
    };

    testNoAlloc(layout.format(event, dg));
    assert(result == "0 hnsecs Warn [Barney] test- Have you met Ted?");
}
