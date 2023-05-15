#import "template.typ": *

// Take a look at the file `template.typ` in the file panel
// to customize this template and discover how it works.
#show: project.with(
  title: "A Functional Language based on TTT with effects",
  authors: (
    "FranchuFranchu",
  ),
)

// We generated the example code below so you can see how
// your document will look. Go ahead and replace it with
// your own content!

= Introduction
I will describe a a programming language based on Transitive Type Theory. It features syntax to handle monads, and metaprogramming.

= Runtime

The language first desugars to a low level representation, where all values are Transitive Type Theory terms.

This resulting desugared program is type-checked. After type-checking, it is compiled to HVM.

= Syntax


#show raw.where(block: true): block.with(
  fill: luma(200),
  inset: 6pt,
  radius: 4pt,
  breakable: false,
)
// that retains the correct baseline.
#show raw.where(block: false): box.with(
  fill: luma(200),
  inset: (x: 3pt, y: 0pt),
  outset: (y: 3pt),
  radius: 2pt,
)



== Basic Syntax
- Function application: `function (argument)`
- Function application with multiple arguments: `function (a1 a2 a3)`
- Function creation: `(argument) body`
- Function creation (with type): `(argument: T) body`
- Function creation (with type bounds): `(T < argument < U) body`
- Function creation (with many arguments): `(a1 a2 a3) body`
- Least-recursive term creation: `rec <= body`
- Greatest-recursive term creation: `rec >= body`
- Macros: `do { }`,`  inductive { }`,` coinductive { }`, etc.

== Types

```
Nat = inductive {
  Nat.zero: Nat
  Nat.succ (x: Nat): Nat
}
```
`Nat` is an inductive type which can have two values - `Nat.zero` and `Nat.succ (x: Nat)`. `Nat.zero` represents the natural number zero and `Nat.succ (x: Nat)` represents the successor of the natural number `x`.
```
List (T: *) = inductive {
  List.nil: List T
  List.cons (head: T) (tail: List T): List T
}
```
`List` is a parametrized inductive type, which means that it takes another type `T` as a parameter. It can have two values - `List.nil` which represents an empty list and `List.cons (head: T tail: List T)` which represents a non-empty list with `head` as the first element and `tail` as the rest of the list
```
Stream (T: *) = coinductive {
  Stream.head (x: Stream T): T
  Stream.tail (x: Stream T): Stream T
}
```
`Stream` is a parametrized co-inductive type which is used to represent an infinite stream of values of type `T`. It has two functions - `Stream.head (x: Stream T)` which returns the first element of the stream x and `Stream.tail (x: Stream T)` which returns the rest of the stream after the first element.

== Type checking

Each name can have a value and a type.
```
Nat.add: (a: Nat) (b: Nat) Nat = ...
```
or, by splitting it into two lines.
```
Nat.add: (a: Nat) (b: Nat) Nat 
Nat.add (a: Nat) (b: Nat) = ...
```
This type does not influence other functions and is merely an instruction for the type checker to check this term's value against its type.

== Functions

The first way is to define a function by first specifying its name, followed by its arguments, and then its body. For example, `Nat.square` takes a value of type Nat as an argument and returns the square of that value by multiplying it with itself using the `Nat.mul` function.
```
Nat.square (a: Nat) = (Nat.mul a a)
```
The second way is to define a function using a lambda expression.
```
Nat.square = (a: Nat) (Nat.mul a a)
```

The programming language also supports defining partial functions. Partial functions are functions that are not defined for all possible values of their arguments. By defining them multiple times you can perform pattern-matching with function definition.
```
Nat.add = (Nat.zero)        (b: Nat) b
Nat.add = (Nat.succ a: Nat) (b: Nat) (Nat.succ (Nat.add a b))
```


These get compiled into equivalent closed-form functions.


The programming language supports defining functions inside other functions. This allows for more modular and organized code. Here is an example:

```
Nat.addition_and_square = (a: Nat) (b: Nat) {
  Nat.addition = (c: Nat) (Nat.add a c)
  Nat.square = (d: Nat) (Nat.mul d d)
  Nat.square (Nat.addition b)
}
```

== Pattern Matching
```
Nat.is_zero (a: Nat) = match a {
  (Nat.zero) Bool.true
  (Nat.succ a) Bool.false
}
```

== Let-Binding
A `let` binding defines a variable in the local scope. 
```
let var = value
body
---------------------  desugars to
((var) body) (value)
```
where `body` is an expression that includes `var`
== Ask-Binding
The right-hand side of an `ask` binding is a function which takes in a _continuation_ of type `T -> U` and returns `U`. The left-hand side is of type `T`.
```
ask var = value
body
---------------------  desugars to
value ((var) body))
```
So, for example, if `F = (x) (x 1)`
```
ask var = F
+ (var 2)
-------------------- desugars to
(F ((var) + (var 2)))
--------------------- replace F
((x) (x 1) ((var) + (var 2)))
--------------------- x = ((var) + (var 2))
(((var) + (var 2)) 1)
--------------------- var = 1
+ (1 2)
3
```
The interesting thing about `ask` bindings is that it can modify the result of the continuation, which gives it more flexibility than `let` bindings have.

=== Inline ask binding

`ask` bindings can also be done inline, by providing a "wrapper function" as an argument; for example:

```
(c (a.ask(b)))
----------------
ask x = (b a)
(c x)
```
This is a bit magical, but quite useful in many situations.


== Seq-Binding
`seq` is sometimes needed to run side-effectful functions sequentially. There aren't many of them, usually they interact with the underlying HVM runtinme

== Monad syntax
```
Main = do Io (io) {
  let x = (Io.read a).ask(io)
  // Or: ask x = io (Io.read a)
  // Or: ask(io) x = (Io.read a)
}
```

== Built-in effects:
Monads are quite similar to effects. Here are some potential effects that wrap another type, what they mean, what `ask` would do with them, and how you could extract the inner `T` value.

==== Incomplete effects
These are effects that require extra data to produce their value.

- `Future (ready: T)`
  - Wraps: `T` requires time to be produced. This represents a promise that a value of type T will exist eventually. It requistate machine, that might await other futures internally and return a value of type `T`
  - Ask: Polls and awaits the future, returning `Pending` if it's pending and passing `T` to the rest of the function if it's ready. The difference it has with `Maybe` is that `Future` requires a waker.
  - Resolve: Needs an executor to get T. This can be provided by the main function.
- `Io (ready: T)`
  - Wraps: `T` requires interaction with the outer world to be produced. It is not pure.
  - Ask: Waits the IO action to finish.
  - Resolve: Resolver provided by main function.
- `Allocator (returns: T)`
  - Wraps: `T` requires memory allocation to be produced. This  
  - Ask: Allocates and then continues execution
  - Resolve: Resolver provided by main function.
- `Coroutine (in: T) (out: U)`
  - Wraps: There are many values of type `U`, which will be produced sequenitially. To produce an `U`, you need a `T`. Has an internal state.
  - Ask: It's essentially `map`
  - Resolve: `fold` but you need to provide the `T` values yourself.
==== Complete effects
These are "effects" that already have all the data they need to produce their value.

- `Iterator (item: T) = Coroutine (Unit T)`
  - Wraps: There are many values of type `T`, which will be produced sequentially. 
  - Ask: It's essentially `map`
  - Resolve: Essentially, `fold`
- `Result (ok: T) (err: U)`
  - Wraps: It might be a `T`, or an `U`. It's `Either`  but with monad semantics.
  - Ask: Bubbles if `Err`, otherwise returns value..
  - Resolve: `match`
- `Maybe (value: T) = Result (T Unit)`
  - Wraps: There might be a `T` or there might not be one. 
  - Ask: Bubbles if `None`
  - Resolve: `match`
==

= Sample programs

```
Nat = inductive {
  Nat.zero: Nat
  Nat.succ (pred: Nat): Nat
}

Nat.add: (a: Nat) (b: Nat): Nat
Nat.add = (a: Nat) (b: Nat) match a {
  (Nat.zero) = b
  (Nat.succ a) = Nat.succ (Nat.add (a b))
}

Fibonacci (a: Nat): Nat
Fibonacci Nat.zero = 1
Fibonacci Nat.succ(Nat.zero) = 1
Fibonacci Nat.succ(Nat.succ x)) = Nat.add(Fibonacci(Nat.succ x) Fibonacci(x))

Equal (a b) = (P) (:P a) (P b)
Equal.refl a: Equal a a
Equal.refl a = (P) (prop) prop

Equal.apply (f a b eq:(Equal a b)) : Equal (f a) (f b)
                                   = (P) (prop) eq(((x) (P (f x))) prop)

Nat.add_zero (a: Nat): Equal (Nat.add (a Nat.zero) a)
Nat.add_zero (Nat.zero) = Equal.refl Nat.zero
Nat.add_zero (Nat.succ a) = Equal.apply Nat.succ _ _ (Nat.add_zero a)
```
This can be desugared to Transitive Type Theory terms and then compiled to HVM and evaluated.

= TODO list
- Properly define whether to use `(f a)` vs `f(a)`. The former is ambiguous sometimes, but the latter looks weird?
- Completely implement transitive type theory.