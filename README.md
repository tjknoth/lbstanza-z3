# Stanza Wrapper for the Z3 Solver Library

This project attempts to wrap Z3's solver functionality and provide a
tool for solving and optimizating over domains.

## Example

From `tests/Solver.stanza`:

```
  val cfg = Config()
  val ctx = Context(cfg)

  val s = Solver(ctx)
  val [R1, R2] = to-tuple(RealVars(ctx, ["R1", "R2"])) as [AST, AST]
  val [Vin, Vout] = to-tuple(RealVars(ctx, ["Vin", "Vout"])) as [AST, AST]

  assert-on(s, z-equal?(R1, 100.0e3))
  assert-on(s, z-equal?(Vin, 24.0))
  assert-on(s, z-equal?(Vout, 6.0))

  assert-on(s, R2 > 0.0)
  assert-on(s, z-equal?(Vout, Vin * (R2 / (R1 + R2))))

  val r = check(s)
  println("Result: %_" % [r])

  val m = get-model(s)
  println("%~" % [m])

```

This will generate:

```
Result: Z3_L_TRUE
R2 -> (/ 100000.0 3.0)
R1 -> 100000.0
Vout -> 6.0
Vin -> 24.0
/0 -> {
  (/ 100000.0 3.0) (/ 400000.0 3.0) -> (/ 1.0 4.0)
  else -> 0.0
}
```

Where R2 = 100k / 3.0 == 33.3k. This creates a voltage divider with an output of 6.0V when there
is an input of 24V.

# Setup on Windows

You will need the stanza compiler on your path.

```
$env:PATH += ";C:\Path\To\Stanza"
```

You will need to install and use [MinGW-W64 gcc compiler](https://www.mingw-w64.org/). Install
this and then make sure it is available on your path. I'm currently using version 12.2.0:

```
$> $env:PATH += ";C:\Path\To\MinGW"
$> gcc --version
gcc.exe (x86_64-posix-seh-rev0, Built by MinGW-W64 project) 12.2.0
Copyright (C) 2022 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

I'm also using the `mingw32-make.exe` utility for building the code and tests.

Currently, I'm downloading the v4.11.2 Z3 build from the [releases page](https://github.com/Z3Prover/z3/releases)


I then unzip this and copy the `libz3.dll` file into the `lbstanza-z3` root project directory.
Then copy the `include` folder into `release/include`.


# Running the Tests

```
$> mingw32-make.exe tests
stanza build z3-tests
./z3-tests
[Test 1] test-cfg-basic
[PASS]

[Test 2] test-basic
[PASS]

[Test 3] test-bool-sort
[PASS]

[Test 4] test-int-sort
[PASS]

[Test 5] test-real-sort
[PASS]

[Test 6] test-bitvec-sort
[PASS]

[Test 7] test-finite-domain-sort
[PASS]

[Test 8] test-array-sort
[PASS]

[Test 9] test-numerals
asdf
[PASS]

[Test 10] test-ast-vector
[PASS]

[Test 11] test-basic
Result: Z3_L_TRUE
y -> 0
x -> 7

[PASS]

[Test 12] test-divider
Result: Z3_L_TRUE
R2 -> 100000.0
R1 -> 100000.0
Vout -> 12.0
Vin -> 24.0
/0 -> {
  100000.0 200000.0 -> (/ 1.0 2.0)
  else -> 0.0
}

[PASS]

Tests Finished: 12/12 tests passed. 0 tests skipped. 0 tests failed.

Longest Running Tests:
[PASS] test-basic (28 ms)
[PASS] test-divider (22 ms)
[PASS] test-cfg-basic (12 ms)
[PASS] test-basic (11 ms)
[PASS] test-bool-sort (11 ms)
[PASS] test-numerals (11 ms)
[PASS] test-int-sort (10 ms)
[PASS] test-finite-domain-sort (10 ms)
[PASS] test-ast-vector (10 ms)
[PASS] test-bitvec-sort (10 ms)
[PASS] test-real-sort (10 ms)
[PASS] test-array-sort (9290 us)

```


## Wrapper.stanza & Enums

This project uses the tool defined in [lbstanza-wrappers](https://github.com/callendorph/lbstanza-wrappers) to generate the C function wrappers and the enumeration definitions.


## Writing a solver

There are a couple examples in the unit tests. There are primarily two different types - Solvers and Optimizers. There is an interface called `Constrainable` that is intended to
make it easier to work with either.

WARNING: Currently - there is a short coming in the lbstanza `Unique` interface that makes overriding the `equal?` function of AST objects impossible - see [here](https://github.com/StanzaOrg/lbstanza/issues/184). Hence the `z-equal?` and `z-not-equal?` functions for implementing the `==` and `!=` AST relations for now.

```
  public defn solve (ctx:Context, minR:Double) -> Maybe<[Double, Double]> :
    ; Solve for the resistors of a ground-referenced resistive divider.
    val s = Solver(ctx)

    val [r1, r2] = to-tuple(RealVars(ctx, ["R1", "R2"])) as [AST, AST]
    val [vin, vout] = to-tuple(RealVars(ctx, ["Vin", "Vout"])) as [AST, AST]
    val targ = RealVar(ctx, "TargetVout")

    assert-on(c, z-equal?(vin, 24.0))
    assert-on(c, z-equal?(targ, 6.0))

    assert-on(c, r1 > 0.0)
    assert-on(c, r2 > 0.0)

    assert-on(c, (r1 + r2) > minR)
    assert-on(c, z-equal?(vout, vin * (r2 / (r1 + r2))))

    ; Use a squared error as our target constraint
    val err = pow((targ - vout) / targ, 2.0)

    assert-on(s, err < 0.0001)

    val r = check(s)
    if r is Z3_L_TRUE :
      val m = get-model(s)
      println("%~" % [m])
      val R1Val = to-double(m[r1])
      val R2Val = to-double(m[r2])
      One([R1Val, R2Val])
    else:
      None()
```

You can also use the `Optimizer` instead of `Solver` in this same code.

The `Shellable` provides a means of implementing different scopes:
```
  within shell(s):
    assert-on(s, ((vout * vout) / r1) < 0.01)
    val r = check(s)
    ...
```

The asserts inside the `within` body will only apply during that scope. Once we leave
that scope, they will be removed from the stack of constraints.

