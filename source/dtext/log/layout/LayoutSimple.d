/*******************************************************************************

    Simple Layout to be used with the logger

    Copyright:
        Copyright (c) 2009-2016 dunnhumby Germany GmbH.
        All rights reserved.

    License:
        Boost Software License Version 1.0. See LICENSE_BOOST.txt for details.
        Alternatively, this file may be distributed under the terms of the Tango
        3-Clause BSD License (see LICENSE_BSD.txt for details).

*******************************************************************************/

module dtext.log.layout.LayoutSimple;

import dtext.format.Formatter;
import dtext.log.Appender;
import dtext.log.Event;
import dtext.log.ILogger;

version (unittest)
{
    import dtext.Test;
}

/*******************************************************************************

    A simple layout, prefixing each message with the log level and
    the name of the logger.

    Example:
    ------
    module foobar;

    import dtext.log.layout.LayoutSimple;
    import dtext.log.Logger;
    import dtext.log.AppendConsole;

    void main ()
    {
        Log.root.clear;
        Log.root.add(new AppendConsole(new LayoutSimple));

        auto logger = Log.lookup("Example");

        logger.trace("Trace example");
        logger.error("Error example");
        logger.fatal("Fatal example");
    }
    -----

    Produced output:
    -----
    Trace [Example] - Trace example
    Error [Example] - Error example
    Fatal [Example] - Fatal example
    ----

*******************************************************************************/

public class LayoutSimple : Appender.Layout
{
    /***************************************************************************

        Subclasses should implement this method to perform the formatting
        of the actual message content.

    ***************************************************************************/

    public override void format (LogEvent event, scope FormatterSink dg)
    {
        sformat(dg, "{} [{}] - {}",
                ILogger.convert(event.level), event.name, event.msg);
    }
}

version(LDC) {}
else unittest
{
    auto result = new char[](2048);
    result.length = 0;
    assumeSafeAppend(result);

    scope dg = (in char[] v) { result ~= v; };
    scope layout = new LayoutSimple();
    LogEvent event = {
        level: ILogger.Level.Warn,
        name: "Barney",
        msg: "Have you met Ted?",
    };

    testNoAlloc(layout.format(event, dg));
    assert(result == "Warn [Barney] - Have you met Ted?");
}
