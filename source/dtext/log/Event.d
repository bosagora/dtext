/*******************************************************************************

    Common struct to store `ocean.util.log` event internally

    Contains all information about a logging event, and is passed around
    between methods once it has been determined that the invoking logger
    is enabled for output.

    Note that Event instances are maintained in a freelist rather than
    being allocated each time, and they include a scratchpad area for
    EventLayout formatters to use.

    Copyright:
        Copyright (c) 2004 Kris Bell.
        Some parts copyright (c) 2009-2016 dunnhumby Germany GmbH.
        All rights reserved.

    License:
        Tango Dual License: 3-Clause BSD License / Academic Free License v3.0.
        See LICENSE_TANGO.txt for details.

*******************************************************************************/

module dtext.log.Event;

import dtext.log.ILogger;

import std.datetime.systime;
import core.time;

shared static this ()
{
    cast()LogEvent.startTime = Clock.currTime();
}

///
public struct LogEvent
{
    /// Program start time
    public static immutable SysTime startTime;

    /// Level at which this even happened
    public ILogger.Level   level;

    /// Name of the logger emitting this event
    public const(char)[]   name;

    /// Host of the Logger emitting this event
    public ILogger.Context host;

    /// Time at which this event was recorded
    public SysTime         time;

    /// Message emitted
    public const(char)[]   msg;

    /// Returns: The difference between the program start time and the event time
    public Duration span () const scope @safe nothrow @nogc pure
    {
        return this.time - startTime;
    }
}
