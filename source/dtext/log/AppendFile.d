/*******************************************************************************

    An `Appender` to write to a file using Phobos' `std.file

   Copyright:
       Copyright (c) 2004 Kris Bell.
       Some parts copyright (c) 2009-2016 dunnhumby Germany GmbH.
       All rights reserved.

   License:
       Tango Dual License: 3-Clause BSD License / Academic Free License v3.0.
       See LICENSE_TANGO.txt for details.

   Version: Initial release: May 2004

   Authors: Kris

*******************************************************************************/

module dtext.log.AppendFile;

import dtext.log.Appender;
import dtext.log.Event;

import std.file;
import std.path;
import std.stdio;

/*******************************************************************************

    Append log messages to a file. This basic version has no rollover support,
    so it just keeps on adding to the file.

    There is also an AppendFiles that may suit your needs.

*******************************************************************************/

public class AppendFile : Appender
{
   private Mask mask_;

    /// File to append to
    private File file;

    /***************************************************************************

        Create a basic FileAppender to a file with the specified path.

    ***************************************************************************/

    public this (string path, Appender.Layout how = null)
    {
        // Get a unique fingerprint for this instance
        this.mask_ = this.register(path);
        this.layout(how);

        path.dirName.mkdirRecurse();
        this.file = File(path, "a");
    }

    /***************************************************************************

        Returns:
            the fingerprint for this class

    ***************************************************************************/

    final override Mask mask ()
    {
        return mask_;
    }

    /***************************************************************************

        Return the name of this class

    ***************************************************************************/

    final override string name ()
    {
        return this.classinfo.name;
    }

    /***********************************************************************

        Append an event to the output.

    ***************************************************************************/

    final override void append (LogEvent event)
    {
        // We need the `file.flush()` to happen after the lockingTextWriter
        // is destroyed (unlocking the file).
        scope (exit) this.file.flush();
        scope writer = this.file.lockingTextWriter();
        this.layout.format(event,
            (in char[] content)
            {
                writer.put(content);
            });
        version (Windows) writer.put("\r\n");
        else              writer.put("\n");
    }
}
