/*******************************************************************************

    A set of functions for converting between string and integer
    values.

    Applying the D "import alias" mechanism to this module is highly
    recommended, in order to limit namespace pollution:
    ---
    import Integer = ocean.text.convert.Integer_tango;

    auto i = Integer.parse ("32767");
    ---

    Copyright:
        Copyright (c) 2004 Kris Bell.
        Some parts copyright (c) 2009-2016 dunnhumby Germany GmbH.
        All rights reserved.

    License:
        Tango Dual License: 3-Clause BSD License / Academic Free License v3.0.
        See LICENSE_TANGO.txt for details.

    Version: Initial release: Nov 2005

    Authors: Kris

 *******************************************************************************/

module dtext.format.Integer_tango;

// import ocean.meta.types.Qualifiers;
// import ocean.core.ExceptionDefinitions;
// import ocean.core.Verify;
// import ocean.meta.traits.Basic;
import std.traits;

/*******************************************************************************

  Supports format specifications via an array, where format follows
  the notation given below:
  ---
  type width prefix
  ---

  Type is one of [d, g, u, b, x, o] or uppercase equivalent, and
  dictates the conversion radix or other semantics.

  Width is optional and indicates a minimum width for zero-padding,
  while the optional prefix is one of ['#', ' ', '+'] and indicates
  what variety of prefix should be placed in the output. e.g.
  ---
  "d"     => integer
  "u"     => unsigned
  "o"     => octal
  "b"     => binary
  "x"     => hexadecimal
  "X"     => hexadecimal uppercase

  "d+"    => integer prefixed with "+"
  "b#"    => binary prefixed with "0b"
  "x#"    => hexadecimal prefixed with "0x"
  "X#"    => hexadecimal prefixed with "0X"

  "d8"    => decimal padded to 8 places as required
  "b8"    => binary padded to 8 places as required
  "b8#"   => binary padded to 8 places and prefixed with "0b"
  ---

  Note that the specified width is exclusive of the prefix, though
  the width padding will be shrunk as necessary in order to ensure
  a requested prefix can be inserted into the provided output.

 *******************************************************************************/

const(char)[] format(N) (char[] dst, N i_, in char[] fmt = null)
{
    // static assert(isIntegerType!(N),
    //               "Integer_tango.format only supports integers");

    char    pre,
            type;
    int     width;

    if (fmt.length is 0)
        type = 'd';
    else
    {
        type = fmt[0];
        if (fmt.length > 1)
        {
            auto p = &fmt[1];
            for (int j=1; j < fmt.length; ++j, ++p)
            {
                if (*p >= '0' && *p <= '9')
                    width = width * 10 + (*p - '0');
                else
                    pre = *p;
            }
        }
    }

    static immutable string lower = "0123456789abcdef";
    static immutable string upper = "0123456789ABCDEF";

    alias _FormatterInfo!(immutable(char)) Info;

    static immutable Info[] formats = [
        { 10, null, lower},
        { -10, "-" , lower},
        { 10, " " , lower},
        { 10, "+" , lower},
        {  2, "0b", lower},
        {  8, "0o", lower},
        { 16, "0x", lower},
        { 16, "0X", upper},
    ];

    Unqual!N i = i_;
    ubyte index;
    int len = cast(int) dst.length;

    if (len)
    {
        switch (type)
        {
            case 'd':
            case 'D':
            case 'g':
            case 'G':
                if (i < 0)
                    index = 1;
                else
                    if (pre is ' ')
                        index = 2;
                    else
                        if (pre is '+')
                            index = 3;
                goto case;
            case 'u':
            case 'U':
                pre = '#';
                break;

            case 'b':
            case 'B':
                index = 4;
                break;

            case 'o':
            case 'O':
                index = 5;
                break;

            case 'x':
                index = 6;
                break;

            case 'X':
                index = 7;
                break;

            default:
                return "{unknown format '" ~ type ~ "'}";
        }

        auto info = &formats[index];
        auto numbers = info.numbers;
        auto radix = info.radix;

        // convert number to text
        auto p = dst.ptr + len;


        // Base 10 formatting
        if (index <= 3 && index)
        {
            assert((i >= 0 && radix > 0) || (i < 0 && radix < 0));

            do
                *--p = numbers[abs(i % radix)];
            while ((i /= radix) && --len);
         }
        else // Those numbers are not signed
        {
            ulong v = reinterpretInteger!(ulong)(i);
            do
                *--p = numbers[v % radix];
            while ((v /= radix) && --len);
        }

        auto prefix = (pre is '#') ? info.prefix : null;
        if (len > prefix.length)
        {
            len -= prefix.length + 1;

            // prefix number with zeros?
            if (width)
            {
                width = cast(int) (dst.length - width - prefix.length);
                while (len > width && len > 0)
                {
                    *--p = '0';
                    --len;
                }
            }
            // write optional prefix string ...
            dst [len .. len + prefix.length] = prefix;

            // return slice of provided output buffer
            return dst [len .. $];
        }
    }

    return "{output width too small}";
}

/*******************************************************************************

    Get the absolute value of a number

    The number should not be == `T.min` if `T` is a signed number.
    Since signed numbers use the two's complement, `-T.min` cannot be
    represented: It would be `T.max + 1`.
    Trying to calculate `-T.min` causes an integer overflow and results in
    `T.min`.

    Params:
        x = A value between `T.min` (exclusive for signed number) and `T.max`

    Returns:
        The absolute value of `x` (`|x|`)

*******************************************************************************/

private T abs (T) (T x)
{
    static if (T.min < 0)
    {
        assert(x != T.min,
            "abs cannot be called with x == " ~ T.stringof ~ ".min");
    }
    return x >= 0 ? x : -x;
}


/*******************************************************************************

    Truncates or zero-extend a value of type `From` to fit into `To`.

    Getting the same binary representation of a number in a larger type can be
    quite tedious, especially when it comes to negative numbers.
    For example, turning `byte(-1)` into `long` or `ulong` gives different
    result.
    This functions allows to get the same exact binary representation of an
    integral type into another. If the representation is truncating, it is
    just a cast. If it is widening, it zero extends `val`.

    Params:
        To      = Type to convert to
        From    = Type to convert from. If not specified, it is infered from
                  val, so it will be an `int` when passing a literal.
        val     = Value to reinterpret

    Returns:
        Binary representation of `val` typed as `To`

*******************************************************************************/

private To reinterpretInteger (To, From) (From val)
{
    static if (From.sizeof >= To.sizeof)
        return cast(To) val;
    else
    {
        static struct Reinterpreter
        {
            version (LittleEndian) From value;
            // 0 padding
            ubyte[To.sizeof - From.sizeof] pad;
            version (BigEndian) From value;
        }

        Reinterpreter r = { value: val };
        return *(cast(To*) &r.value);
    }
}

private struct _FormatterInfo(T)
{
    byte    radix;
    T[]     prefix;
    T[]     numbers;
}
