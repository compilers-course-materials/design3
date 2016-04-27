## Common Subexpression Elimination

In class and lab, we discussed constant propagation: an optimization that
substituted constants into other expressions to save on variable space.

A related optimization is called _common subexpression elimination_.  In some
ways, it's the inverse of constant propagation.

It works like this: In an expression, search for multiple instances of the same
sub-expression, and replace them with a new variable.  Then wrap the whole
expression in a new let binding for that variable that computes the expression.
We can do this on, say, each function body to avoid repeated computation.

So, for example, we might change:

```
def dist(x1, x2, y1, y2):
  sqrt(((x1 - x2) * (x1 - x2)) + ((y1 - y2) * (y1 - y2)))
```

into:

```
def dist(x1, x2, y1, y2):
  let tmp1 = x1 - x2 in
  let tmp2 = y1 - y2 in
  sqrt((tmp1 * tmp1) + (tmp2 * tmp2))
```

The common sub-expressions were `(x1 - x2)` and `(y1 - y2)`.  The idea is to
avoid repeating the same computation – in the optimized program, the
subtraction only needs to happen twice, rather than four times.

Some expressions, if eliminated in this way, clearly change the meaning of the
program.  `print` expressions are an obvious example.  It would change the
program to turn:

```
def f(x):
  (print(x), print(x))
```

into

```
def f(x):
  let tmp = print(x) in
  (tmp, tmp)
```

In fact, the optimization changed the first program, too, but more subtly.
Consider a call to `dist` where the quantity `(x1 - x2)` is large enough to
overflow when multiplied by itself, and `y1` is mistakenly passed as a boolean.
In the first program, the overflow error would result.  In the second, the
not-a-boolean error would result.

Questions:
- Is this last point—the change in error behavior—acceptable?  Come up with a
  definition for "acceptable", and defend why this behavior is acceptable or
  unacceptable. (Assume, for the purposes of this question, that the printing
  example is obviously unacceptable)
- Are there any cases for common subexpression elimination that don't change
  the program?  Assume the semantics of egg-eater.
- Are there changes to the language or other design decisions we could make
  that would make it easier to not change the program's behavior with this
  optimization?  Hint: Think about C's rules for arithmetic.  Another hint:
  Think about equality.
- If we were to run common subexpression elimination in a fixpoint loop with
  constant propagation and constant folding, would the loop terminate?  Why or
  why not?


## Register Allocation

Consider this alternate strategy for allocating registers, that doesn't use
anything like `colorful_env`.  Starting from egg-eater, first, we change the
signature of the compiler's functions slightly:

```
acompile_cexpr :: (ce : cexpr) (env : location envt) (regs : reg list) (si : int) -> instruction list
acompile_aexpr :: (ae : aexpr) (env : location envt) (regs : reg list) (si : int) -> instruction list
```

Where `location` is as in Hundred Pacer:

```
type location =
  | LReg of reg
  | LStack of int
```

The new `regs` parameter keeps track of a list of _available registers_ that
can be used for binding new variables.

When compiling a let binding, we first check if there are available registers,
and if there are, we use one of them to store the new variable, and bind it to
the corresponding `LReg` in the environment when compiling the body.
Otherwise, we use a stack location:

```
...
  | ALet(x, ex, b) ->
    let (loc, new_regs, new_si) = match regs with
      | [] -> (LStack(si), [], si + 1)
      | r::rs -> (LReg(r), rs, si) in
    let cinstrs = acompile_cexpr ex env regs si in
    let binstrs = acompile_aexpr b (x, loc)::env new_regs new_si in
    let dest = match loc with
      | LStack(si) -> RegOffset(-4 * si, EBP)
      | LReg(r) -> Reg(r) in
    cinstrs @ [ IMov(dest, Reg(EAX)) ] @ binstrs
...
```

Compiling an identifier uses the same kind of logic as `dest` to look up the
variable in the correct location:

```
...
  | ImmId(x) ->
    match lookup env x with
      | Some(LReg(r)) -> Reg(r)
      | Some(LStack(si) -> RegOffset(-4 * si, EBP)
      | None -> failwith "Unbound id"
...
```

The initial value of `regs` can be any set of open registers.  For example we
might choose `[EBX; EDX; ESI]` if we were building on, say, egg-eater or FDL,
which don't use those registers for anything.  This would allow us to use
registers for some variables, while others would end up on the stack.

Questions:

- Is this strategy ever worse than not allocating variables to registers at
  all?
- In terms of total number of locations used, is this strategy better or worse
  at assigning variables to locations than the graph coloring algorithm we
  discussed in class?  Give some examples supporting your conclusion.
- How does the time complexity of this strategy, in terms of the work the
  _compiler_ has to do, compare to the graph coloring algorithm?

