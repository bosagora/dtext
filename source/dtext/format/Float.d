/*******************************************************************************

    A set of functions for converting between string and floating-
    point values.

    Applying the D "import alias" mechanism to this module is highly
    recommended, in order to limit namespace pollution:
    ---
    import Float = ocean.text.convert.Float;

    auto f = Float.parse ("3.14159");
    ---

    Copyright:
        Copyright (c) 2004 Kris Bell.
        Some parts copyright (c) 2009-2016 dunnhumby Germany GmbH.
        All rights reserved.

    License:
        Tango Dual License: 3-Clause BSD License / Academic Free License v3.0.
        See LICENSE_TANGO.txt for details.

    Version:
        Nov 2005: Initial release
        Jan 2010: added internal ecvt()

    Authors: Kris

********************************************************************************/

module dtext.format.Float;

// import ocean.core.ExceptionDefinitions;
// import ocean.math.IEEE;
// import ocean.meta.types.Qualifiers;
import std.traits;

static import tsm = core.stdc.math;

private alias real NumType;

/******************************************************************************

  Constants

 ******************************************************************************/

private enum
{
    Pad = 0,                // default trailing decimal zero
    Dec = 2,                // default decimal places
    Exp = 10,               // default switch to scientific notation
}

/******************************************************************************

  Template wrapper to make life simpler. Returns a text version
  of the provided value.

  See format() for details

 ******************************************************************************/

char[] toString (NumType d, uint decimals=Dec, int e=Exp)
{
    char[64] tmp = void;

    return format (tmp, d, decimals, e).dup;
}

/******************************************************************************

  Truncate trailing '0' and '.' from a string, such that 200.000
  becomes 200, and 20.10 becomes 20.1

  Returns a potentially shorter slice of what you give it.

 ******************************************************************************/

T[] truncate(T) (T[] s)
{
    auto tmp = s;
    int i = tmp.length;
    foreach (int idx, T c; tmp)
    {
        if (c is '.')
        {
            while (--i >= idx)
            {
                if (tmp[i] != '0')
                {
                    if (tmp[i] is '.')
                        --i;
                    s = tmp [0 .. i+1];
                    while (--i >= idx)
                        if (tmp[i] is 'e')
                            return tmp;
                    break;
                }
            }
        }
    }
    return s;
}

/******************************************************************************

  Extract a sign-bit

 ******************************************************************************/

private bool negative (NumType x)
{
    static if (NumType.sizeof is 4)
        return ((*cast(uint *)&x) & 0x8000_0000) != 0;
    else
        static if (NumType.sizeof is 8)
            return ((*cast(ulong *)&x) & 0x8000_0000_0000_0000) != 0;
    else
    {
        auto pe = cast(ubyte *)&x;
        return (pe[9] & 0x80) != 0;
    }
}


/*******************************************************************************

    Format a floating-point value according to a format string

    Defaults to 2 decimal places and 10 exponent, as the other format overload
    does.

    Format specifiers (additive unless stated otherwise):
        '.' = Do not pad
        'e' or 'E' = Display exponential notation
        Any number = Set the decimal precision

    Params:
        T      = character type
        V      = Floating point type
        output = Where to write the string to - expected to be large enough
        v      = Number to format
        fmt    = Format string, see this function's description

    Returns:
        A const reference to `output`

*******************************************************************************/

public const(T)[] format (T, V) (T[] output, V v, in T[] fmt)
{
    static assert(is(V : const(real)),
                  "Float.format only support floating point types or types that"
                  ~ "implicitly convert to them");

    int dec = Dec;
    int exp = Exp;
    bool pad = true;

    for (auto p = fmt.ptr, e = p + fmt.length; p < e; ++p)
        switch (*p)
        {
        case '.':
            pad = false;
            break;
        case 'e':
        case 'E':
            exp = 0;
            break;
        default:
            Unqual!(T) c = *p;
            if (c >= '0' && c <= '9')
            {
                dec = c - '0', c = p[1];
                if (c >= '0' && c <= '9' && ++p < e)
                    dec = dec * 10 + c - '0';
            }
            break;
        }

    return format!(T)(output, v, dec, exp, pad);
}

/******************************************************************************

  Convert a floating-point number to a string.

  The e parameter controls the number of exponent places emitted,
  and can thus control where the output switches to the scientific
  notation. For example, setting e=2 for 0.01 or 10.0 would result
  in normal output. Whereas setting e=1 would result in both those
  values being rendered in scientific notation instead. Setting e
  to 0 forces that notation on for everything. Parameter pad will
  append trailing '0' decimals when set ~ otherwise trailing '0's
  will be elided

 ******************************************************************************/

T[] format(T) (T[] dst, NumType x, int decimals=Dec, int e=Exp, bool pad=Pad)
{
    const(char)*  end, str;
    int       exp,
              sign,
              mode=5;
    char[32]  buf = void;

    // test exponent to determine mode
    exp = (x == 0) ? 1 : cast(int) tsm.log10l(x < 0 ? -x : x);
    if (exp <= -e || exp >= e)
        mode = 2, ++decimals;

    str = convertl (buf.ptr, x, decimals, &exp, &sign, mode is 5);

    auto p = dst.ptr;
    if (sign)
        *p++ = '-';

    if (exp is 9999)
        while (*str)
            *p++ = *str++;
    else
    {
        if (mode is 2)
        {
            --exp;
            *p++ = *str++;
            if (*str || pad)
            {
                auto d = p;
                *p++ = '.';
                while (*str)
                    *p++ = *str++;
                if (pad)
                    while (p-d < decimals)
                        *p++ = '0';
            }
            *p++ = 'e';
            if (exp < 0)
                *p++ = '-', exp = -exp;
            else
                *p++ = '+';
            if (exp >= 1000)
            {
                *p++ = cast(T)((exp/1000) + '0');
                exp %= 1000;
            }
            if (exp >= 100)
            {
                *p++ = cast(char) (exp / 100 + '0');
                exp %= 100;
            }
            *p++ = cast(char) (exp / 10 + '0');
            *p++ = cast(char) (exp % 10 + '0');
        }
        else
        {
            if (exp <= 0)
                *p++ = '0';
            else
                for (; exp > 0; --exp)
                    *p++ = (*str) ? *str++ : '0';
            if (*str || pad)
            {
                *p++ = '.';
                auto d = p;
                for (; exp < 0; ++exp)
                    *p++ = '0';
                while (*str)
                    *p++ = *str++;
                if (pad)
                    while (p-d < decimals)
                        *p++ = '0';
            }
        }
    }

    // stuff a C terminator in there too ...
    *p = 0;
    return dst[0..(p - dst.ptr)];
}


/******************************************************************************

  ecvt() and fcvt() for 80bit FP, which DMD does not include. Based
  upon the following:

  Copyright (c) 2009 Ian Piumarta

  All rights reserved.

  Permission is hereby granted, free of charge, to any person
  obtaining a copy of this software and associated documentation
  files (the 'Software'), to deal in the Software without restriction,
  including without limitation the rights to use, copy, modify, merge,
  publish, distribute, and/or sell copies of the Software, and to permit
  persons to whom the Software is furnished to do so, provided that the
  above copyright notice(s) and this permission notice appear in all
  copies of the Software.

 ******************************************************************************/

private const(char)* convertl (char* buf, real value, int ndigit,
    int *decpt, int *sign, int fflag)
{
    import std.math;

    if ((*sign = negative(value)) != 0)
        value = -value;

    *decpt = 9999;
    if (tsm.isnan(value))
        return "nan\0".ptr;

    if (isInfinity(value))
        return "inf\0".ptr;

    int exp10 = (value == 0) ? !fflag : cast(int) tsm.ceill(tsm.log10l(value));
    if (exp10 < -4931)
        exp10 = -4931;
    value *= tsm.powl(10.0, -exp10);
    if (value)
    {
        while (value <  0.1) { value *= 10;  --exp10; }
        while (value >= 1.0) { value /= 10;  ++exp10; }
    }
    assert(isZero(value) || (0.1 <= value && value < 1.0));
    //auto zero = pad ? int.max : 1;
    auto zero = 1;
    if (fflag)
    {
        // if (! pad)
        zero = exp10;
        if (ndigit + exp10 < 0)
        {
            *decpt= -ndigit;
            return "\0".ptr;
        }
        ndigit += exp10;
    }
    *decpt = exp10;
    int ptr = 1;

    if (ndigit > real.dig)
        ndigit = real.dig;
    //printf ("< flag %d, digits %d, exp10 %d, decpt %d\n", fflag, ndigit, exp10, *decpt);
    while (ptr <= ndigit)
    {
        real i = void;
        value = tsm.modfl(value * 10, &i);
        buf [ptr++]= cast(char) ('0' + cast(int) i);
    }

    if (value >= 0.5)
        while (--ptr && ++buf[ptr] > '9')
            buf[ptr] = (ptr > zero) ? '\0' : '0';
    else
        for (auto i=ptr; i && --i > zero && buf[i] is '0';)
            buf[i] = '\0';

    if (ptr)
    {
        buf [ndigit + 1] = '\0';
        return buf + 1;
    }
    if (fflag)
    {
        ++ndigit;
    }
    buf[0]= '1';
    ++*decpt;
    buf[ndigit]= '\0';
    return buf;
}

/// TODO: FIXME
int isZero(real x) { return x == 0.0 || x == -0.0; }
