/*******************************************************************************

   Test utilities for this package

*******************************************************************************/

module dtext.Test;

/******************************************************************************

    Verifies that call to `expr` does not allocate GC memory

    This is achieved by checking GC usage stats before and after the call.
    Originally `ocean.core.Test : testNoAlloc`

    Params:
        expr = any expression, wrapped in void-returning delegate if necessary
        file = file where test is invoked
        line = line where test is invoked

******************************************************************************/

public void testNoAlloc (lazy void expr, string file = __FILE__,
    int line = __LINE__)
{
    import core.memory;

    const before = GC.stats();
    expr();
    const after = GC.stats();

    assert(before.usedSize == after.usedSize);
    assert(before.freeSize == after.freeSize);
}
