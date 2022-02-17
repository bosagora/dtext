/*******************************************************************************

    Test module for dtext.format.Formatter

    Copyright:
        Copyright (c) 2009-2016 dunnhumby Germany GmbH.
        All rights reserved.

    License:
        Boost Software License Version 1.0. See LICENSE_BOOST.txt for details.
        Alternatively, this file may be distributed under the terms of the Tango
        3-Clause BSD License (see LICENSE_BSD.txt for details).

*******************************************************************************/

module ocean.text.convert.Formatter_test;

import dtext.format.Formatter;
import dtext.Test;

unittest
{
    static struct Foo
    {
        int i = 0x2A;
        void toString (scope void delegate (in char[]) sink) const
        {
            sink("Hello void");
        }
    }

    Foo f;
    assert(format("{}", f) == "Hello void");
}

/*******************************************************************************

    Original tango Layout unittest, minus changes of behaviour

    Copyright:
        These unit tests come from `tango.text.convert.Layout`.
        Copyright Kris & Larsivi

*******************************************************************************/

unittest
{
    // basic layout tests
    assert(format("abc") == "abc");
    assert(format("{0}", 1) == "1");

    assert(format("X{}Y", string.init) == "XY");

    assert(format("{0}", -1) == "-1");

    assert(format("{}", 1) == "1");
    assert(format("{} {}", 1, 2) == "1 2");
    assert(format("{} {0} {}", 1, 3) == "1 1 3");
    assert(format("{} {0} {} {}", 1, 3) == "1 1 3 {invalid index}");
    assert(format("{} {0} {} {:x}", 1, 3) == "1 1 3 {invalid index}");

    assert(format("{0}", true) == "true");
    assert(format("{0}", false) == "false");

    assert(format("{0}", cast(byte)-128) == "-128");
    assert(format("{0}", cast(byte)127) == "127");
    assert(format("{0}", cast(ubyte)255) == "255");

    assert(format("{0}", cast(short)-32768 ) == "-32768");
    assert(format("{0}", cast(short)32767) == "32767");
    assert(format("{0}", cast(ushort)65535) == "65535");
    assert(format("{0:x4}", cast(ushort)0xafe) == "0afe");
    assert(format("{0:X4}", cast(ushort)0xafe) == "0AFE");

    assert(format("{0}", -2147483648) == "-2147483648");
    assert(format("{0}", 2147483647) == "2147483647");
    assert(format("{0}", 4294967295) == "4294967295");

    // large integers
    assert(format("{0}", -9223372036854775807L) == "-9223372036854775807");
    assert(format("{0}", 0x8000_0000_0000_0000L) == "9223372036854775808");
    assert(format("{0}", 9223372036854775807L) == "9223372036854775807");
    assert(format("{0:X}", 0xFFFF_FFFF_FFFF_FFFF) == "FFFFFFFFFFFFFFFF");
    assert(format("{0:x}", 0xFFFF_FFFF_FFFF_FFFF) == "ffffffffffffffff");
    assert(format("{0:x}", 0xFFFF_1234_FFFF_FFFF) == "ffff1234ffffffff");
    assert(format("{0:x19}", 0x1234_FFFF_FFFF) == "00000001234ffffffff");
    assert(format("{0}", 18446744073709551615UL) == "18446744073709551615");
    assert(format("{0}", 18446744073709551615UL) == "18446744073709551615");

    // fragments before and after
    assert(format("d{0}d", "s") == "dsd");
    assert(format("d{0}d", "1234567890") == "d1234567890d");

    // brace escaping
    assert(format("d{0}d", "<string>") == "d<string>d");
    assert(format("d{{0}d", "<string>") == "d{0}d");
    assert(format("d{{{0}d", "<string>") == "d{<string>d");
    assert(format("d{0}}d", "<string>") == "d<string>}d");

    // hex conversions, where width indicates leading zeroes
    assert(format("{0:x}", 0xafe0000) == "afe0000");
    assert(format("{0:x7}", 0xafe0000) == "afe0000");
    assert(format("{0:x8}", 0xafe0000) == "0afe0000");
    assert(format("{0:X8}", 0xafe0000) == "0AFE0000");
    assert(format("{0:X9}", 0xafe0000) == "00AFE0000");
    assert(format("{0:X13}", 0xafe0000) == "000000AFE0000");
    assert(format("{0:x13}", 0xafe0000) == "000000afe0000");

    // decimal width
    assert(format("{0:d6}", 123) == "000123");
    assert(format("{0,7:d6}", 123) == " 000123");
    assert(format("{0,-7:d6}", 123) == "000123 ");

    // width & sign combinations
    assert(format("{0:d7}", -123) == "-0000123");
    assert(format("{0,7:d6}", 123) == " 000123");
    assert(format("{0,7:d7}", -123) == "-0000123");
    assert(format("{0,8:d7}", -123) == "-0000123");
    assert(format("{0,5:d7}", -123) == "-0000123");

    // Negative numbers in various bases
    assert(format("{:b}", cast(byte) -1) == "11111111");
    assert(format("{:b}", cast(short) -1) == "1111111111111111");
    assert(format("{:b}", cast(int) -1)
           , "11111111111111111111111111111111");
    assert(format("{:b}", cast(long) -1)
           , "1111111111111111111111111111111111111111111111111111111111111111");

    assert(format("{:o}", cast(byte) -1) == "377");
    assert(format("{:o}", cast(short) -1) == "177777");
    assert(format("{:o}", cast(int) -1) == "37777777777");
    assert(format("{:o}", cast(long) -1) == "1777777777777777777777");

    assert(format("{:d}", cast(byte) -1) == "-1");
    assert(format("{:d}", cast(short) -1) == "-1");
    assert(format("{:d}", cast(int) -1) == "-1");
    assert(format("{:d}", cast(long) -1) == "-1");

    assert(format("{:x}", cast(byte) -1) == "ff");
    assert(format("{:x}", cast(short) -1) == "ffff");
    assert(format("{:x}", cast(int) -1) == "ffffffff");
    assert(format("{:x}", cast(long) -1) == "ffffffffffffffff");

    // argument index
    assert(format("a{0}b{1}c{2}", "x", "y", "z") == "axbycz");
    assert(format("a{2}b{1}c{0}", "x", "y", "z") == "azbycx");
    assert(format("a{1}b{1}c{1}", "x", "y", "z") == "aybycy");

    // alignment does not restrict the length
    assert(format("{0,5}", "hellohello") == "hellohello");

    // alignment fills with spaces
    assert(format("->{0,-10}<-", "hello") == "->hello     <-");
    assert(format("->{0,10}<-", "hello") == "->     hello<-");
    assert(format("->{0,-10}<-", 12345) == "->12345     <-");
    assert(format("->{0,10}<-", 12345) == "->     12345<-");

    // chop at maximum specified length; insert ellipses when chopped
    assert(format("->{.5}<-", "hello") == "->hello<-");
    assert(format("->{.4}<-", "hello") == "->hell...<-");
    assert(format("->{.-3}<-", "hello") == "->...llo<-");

    // width specifier indicates number of decimal places
    assert(format("{0:f}", 1.23f) == "1.23");
    assert(format("{0:f4}", 1.23456789L) == "1.2346");
    assert(format("{0:e4}", 0.0001) == "1.0000e-04");

    // 'f.' & 'e.' format truncates zeroes from floating decimals
    assert(format("{:f4.}", 1.230) == "1.23");
    assert(format("{:f6.}", 1.230) == "1.23");
    assert(format("{:f1.}", 1.230) == "1.2");
    assert(format("{:f.}", 1.233) == "1.23");
    assert(format("{:f.}", 1.237) == "1.24");
    assert(format("{:f.}", 1.000) == "1");
    assert(format("{:f2.}", 200.001) == "200");

    // array output
    int[] a = [ 51, 52, 53, 54, 55 ];
    assert(format("{}", a) == "[51, 52, 53, 54, 55]");
    assert(format("{:x}", a) == "[33, 34, 35, 36, 37]");
    assert(format("{,-4}", a) == "[51  , 52  , 53  , 54  , 55  ]");
    assert(format("{,4}", a) == "[  51,   52,   53,   54,   55]");
    int[][] b = [ [ 51, 52 ], [ 53, 54, 55 ] ];
    assert(format("{}", b) == "[[51, 52], [53, 54, 55]]");

    char[1024] static_buffer;
    static_buffer[0..10] = "1234567890";

    assert(format("{}", static_buffer[0..10]) == "1234567890");

    // sformat()
    char[] buffer;
    assert(sformat(buffer, "{}", 1) == "1");
    assert(buffer == "1");

    buffer.length = 0;
    assumeSafeAppend(buffer);
    assert(sformat(buffer, "{}", 1234567890123) == "1234567890123");
    assert(buffer == "1234567890123");

    auto old_buffer_ptr = buffer.ptr;
    buffer.length = 0;
    assumeSafeAppend(buffer);
    assert(sformat(buffer, "{}", 1.24) == "1.24");
    assert(buffer == "1.24");
    assert(buffer.ptr == old_buffer_ptr);

    interface I
    {
    }

    class C : I
    {
        override string toString()
        {
            return "something";
        }
    }

    C c = new C;
    I i = c;

    assert(format("{}", i) == "something");
    assert(format("{}", c) == "something");

    static struct S
    {
        string toString()
        {
            return "something";
        }
    }

    assert(format("{}", S.init) == "something");


    // snformat is supposed to overwrite the provided buffer without changing
    // its length and ignore any remaining formatted data that does not fit
    char[] target;
    snformat(target, "{}", 42);
    assert(target.ptr is null);
    target.length = 5; target[] = 'a';
    snformat(target, "{}", 42);
    assert(target, "42aaa");
}


/*******************************************************************************

    Tests for the new behaviour that diverge from the original Layout unit tests

*******************************************************************************/

unittest
{
    // This is handled as a pointer, not as an integer literal
    assert(format("{}", null) == "null");

    // Imaginary and complex numbers aren't supported in D2
    // assert(format("{0:f}", 1.23f*1i) == "1.23*1i");
    // See the original Tango's code for more examples

    static struct S2 { }
    assert(format("{}", S2.init) == "{ empty struct }");
    // This used to produce '{unhandled argument type}'

    // Basic wchar / dchar support
    assert(format("{}", "42"w) == "42");
    assert(format("{}", "42"d) == "42");
    wchar wc = '4';
    dchar dc = '2';
    assert(format("{}", wc) == "4");
    assert(format("{}", dc) == "2");

    assert(format("{,3}", '8') == "  8");

    /*
     * Associative array formatting used to be in the form `{key => value, ...}`
     * However this looks too much like struct, and does not match AA literals
     * syntax (hence it's useless for any code formatting).
     * So it was changed to `[ key: value, ... ]`
     */

    // integer AA
    ushort[long] d;
    d[42] = 21;
    d[512] = 256;
    const(char)[] formatted = format("{}", d);
    assert(formatted == "[ 42: 21, 512: 256 ]"
           || formatted == "[ 512: 256, 42: 21 ]");

    // bool/string AA
    bool[string] e;
    e["key"] = false;
    e["value"] = true;
    formatted = format("{}", e);
    assert(formatted == `[ "key": false, "value": true ]`
           || formatted == `[ "value": true, "key": false ]`);

    // string/double AA
    char[][double] f;
    f[ 2.0 ] = "two".dup;
    f[ 3.14 ] = "PI".dup;
    formatted = format("{}", f);
    assert(formatted == `[ 2.00: "two", 3.14: "PI" ]`
           || formatted == `[ 3.14: "PI", 2.00: "two" ]`);

    // This used to yield `[aa, bb]` but is now quoted
    assert(format("{}", [ "aa", "bb" ]) == `["aa", "bb"]`);
}


/*******************************************************************************

    Additional unit tests

*******************************************************************************/

unittest
{
    // This was not tested by tango, but the behaviour was the same
    assert(format("{0", 42) == "{missing closing '}'}");

    // Wasn't tested either, but also the same behaviour
    assert(format("foo {1} bar", 42) == "foo {invalid index} bar");

    // Support for new sink-based toString
    static struct S1
    {
        void toString (scope FormatterSink sink)
        {
            sink("42424242424242");
        }
    }
    S1 s1;
    assert(format("The answer is {0.2}", s1) == "The answer is 42...");

    // For classes too
    static class C1
    {
        void toString (scope FormatterSink sink)
        {
            sink("42424242424242");
        }
    }
    C1 c1 = new C1;
    assert(format("The answer is {.2}", c1) == "The answer is 42...");

    // Compile time support is awesome, isn't it ?
    static struct S2
    {
        void toString (scope FormatterSink sink, in char[] default_ = "42")
        {
            sink(default_);
        }
    }
    S2 s2;
    assert(format("The answer is {0.2}", s2) == "The answer is 42");

    // Support for formatting struct (!)
    static struct S3
    {
        C1 c;
        int a = 42;
        int* ptr;
        char[] foo;
        const(char)[] bar = "Hello World";
    }
    S3 s3;
    assert(format("Woot {} it works", s3)
           == `Woot { c: null, a: 42, ptr: null, foo: "", bar: "Hello World" } it works`);

    // Pointers are nice too
    int* x = cast(int*)0x2A2A_0000_2A2A;
    assert(format("Here you go: {1}", 42, x) == "Here you go: 0X00002A2A00002A2A");

    // Null AA / array
    int[] empty_arr;
    int[int] empty_aa;
    assert(format("{}", empty_arr) == "[]");
    assert(format("{}", empty_aa) == "[:]");
    int[1] static_arr;
    assert(format("{}", static_arr[$ .. $]) == "[]");

    empty_aa[42] = 42;
    empty_aa.remove(42);
    assert(format("{}", empty_aa) == "[:]");

    // Basic integer-based enums (use `switch` jump table)
    enum Foo : ulong
    {
        A = 0,
        B = 1,
        FooBar = 42
    }
    char[256] buffer;
    Foo[] foo_inputs = [ Foo.FooBar, cast(Foo)1, cast(Foo)36 ];
    string[] foo_outputs = [ "Foo.FooBar", "Foo.B", "cast(Foo) 36" ];
    foreach (i, ref item; foo_inputs)
        testNoAlloc(assert(snformat(buffer, "{}", item) == foo_outputs[i]));

    // Simple test for `const` and `immutable` values
    const Foo fa = Foo.A;
    immutable Foo fb = Foo.B;
    const Foo fc = cast(Foo) 420;
    assert(format("{}", fa) == "const(Foo).A");
    assert(format("{}", fb) == "immutable(Foo).B");
    assert(format("{}", fc) == "cast(const(Foo)) 420");

    // Enums with `string` as base type (use `switch` binary search)
    enum FooA : string
    {
        a = "alpha",
        b = "beta"
    }
    FooA[] fooa_inputs = [ FooA.a, cast(FooA)"beta", cast(FooA)"gamma" ];
    string[] fooa_outputs = [ "FooA.a", "FooA.b", "cast(FooA) gamma" ];
    foreach (i, ref item; fooa_inputs)
        testNoAlloc(assert(snformat(buffer, "{}", item) == fooa_outputs[i]));

    // Enums with `real` as base type (use `if` forest)
    enum FooB : real
    {
        a = 1,
        b = 1.41421,
        c = 1.73205
    }
    FooB[] foob_inputs = [ FooB.a, cast(FooB)1.41421, cast(FooB)42 ];
    string[] foob_outputs = [ "FooB.a", "FooB.b", "cast(FooB) 42.00" ];
    foreach (i, ref item; foob_inputs)
        testNoAlloc(assert(snformat(buffer, "{}", item) == foob_outputs[i]));

    // Enums with struct as base type (use `if` forest)
    static struct S
    {
        int value;
    }
    enum FooC : S { a = S(1), b = S(2), c = S(3) }
    FooC[] fooc_inputs = [ FooC.a, cast(FooC)S(2), cast(FooC)S(42) ];
    string[] fooc_outputs = [ "FooC.a", "FooC.b", "cast(FooC) { value: 42 }" ];
    foreach (i, ref item; fooc_inputs)
        testNoAlloc(assert(snformat(buffer, "{}", item) == fooc_outputs[i]));

    // Chars
    static struct CharC { char c = 'H'; }
    char c = '4';
    CharC cc;
    assert("4" == format("{}", c));
    assert("{ c: 'H' }" == format("{}", cc));

    // void[] array are 'special'
    ubyte[5] arr = [42, 43, 44, 45, 92];
    void[] varr = arr;
    assert(format("{}", varr) == "[42, 43, 44, 45, 92]");

    static immutable ubyte[5] carr = [42, 43, 44, 45, 92];
    auto cvarr = carr; // Immutable, cannot be marked `const` in D1
    assert(format("{}", cvarr) == "[42, 43, 44, 45, 92]");

    // Function ptr / delegates
    auto func = cast(int function(char[], char, int)) 0x4444_1111_2222_3333;
    int delegate(void[], char, int) dg;
    dg.funcptr = cast(typeof(dg.funcptr)) 0x1111_2222_3333_4444;
    dg.ptr     = cast(typeof(dg.ptr))     0x5555_6666_7777_8888;
    assert(format("{}", func)
           == "int function(char[], char, int): 0X4444111122223333");
    assert(format("{}", dg)
           == "int delegate(void[], char, int): { funcptr: 0X1111222233334444, ptr: 0X5555666677778888 }");
}

// Const tests
unittest
{
    static immutable int ai = 42;
    static immutable double ad = 42.00;
    static struct Answer_struct { int value; }
    static class Answer_class
    {
        public override string toString () const
        {
            return "42";
        }
    }

    const(Answer_struct) as = Answer_struct(42);
    auto ac = new const(Answer_class);

    assert(format("{}", ai) == "42");
    assert(format("{:f2}", ad) == "42.00", format("{:f2}", ad));
    assert(format("{}", as) == "{ value: 42 }");
    assert(format("{}", ac) == "42");
}

// Check that `IsTypeofNull` does its job,
// and that pointers to objects are not dereferenced
unittest
{
    // Since `Object* o; string s = o.toString();`
    // compiles, the test for `toString` used to pass
    // on pointers to object, which is wrong.
    // Fixed in sociomantic/ocean#1605
    Object* o = cast(Object*) 0xDEADBEEF_DEADBEEF;
    void* ptr = cast(void*) 0xDEADBEEF_DEADBEEF;

    static immutable string expected = "0XDEADBEEFDEADBEEF";
    string object_str = format("{}", o);
    string ptr_str = format("{}", ptr);
    string null_str = format("{}", null);

    assert(ptr_str != null_str);
    assert(object_str != null_str);
    assert(ptr_str == expected);
    assert(object_str == expected);
}

unittest
{
    static immutable bool YES = true;
    static immutable bool NO  = false;
    assert(format("{} -- {}", YES, NO) == "true -- false");
}

unittest
{
    // Used to work only with "{:X}", however this limitation was lifted
    assert(format("{X}", 42) == "2A");
}

unittest
{
    static void myFunc (inout char[] arg)
    {
        assert(format("{}", arg[0]) == "H");
    }
    myFunc("Hello World");
}

unittest
{
    // Some types (e.g. Phobos's `SysTime` take a sink by ref)
    static struct SysTime
    {
        void toString (W) (ref W writer) { writer("Hello World"); }
    }
    assert(format("{}", SysTime.init) == "Hello World");
}

unittest
{
    // empty range
    bool[string] empty;
    assert(format("{}", empty.byKey()) == `[]`);

    // range with 1 element
    bool[string] one;
    one["A"] = true;
    assert(format("{}", one.byKey()) == `["A"]`);

    // element type is string
    bool[string] foo;
    foo["A"] = true;
    foo["B"] = true;
    assert(format("{}", foo.byKey()) == `["A", "B"]`);

    // element type is int
    bool[int] bar;
    bar[0] = true;
    bar[1] = true;
    assert(format("{}", bar.byKey()) == `[0, 1]`);

    // element type is struct
    struct Key { int value; }
    struct Value { string value; }
    Value[Key] aa;

    aa[Key(1)] = Value("1");
    aa[Key(2)] = Value("2");
    aa[Key(3)] = Value("3");
    aa[Key(4)] = Value("4");
    aa[Key(5)] = Value("5");

    assert(format("{}", aa.byKey()) ==
        `[{ value: 3 }, { value: 5 }, { value: 4 }, ` ~
        `{ value: 2 }, { value: 1 }]`);

    assert(format("{}", aa.byValue()) ==
        `[{ value: "3" }, { value: "5" }, { value: "4" }, ` ~
        `{ value: "2" }, { value: "1" }]`);
}
