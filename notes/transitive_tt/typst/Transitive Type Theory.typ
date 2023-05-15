#import "template.typ": *

// Take a look at the file `template.typ` in the file panel
// to customize this template and discover how it works.
#show: project.with(
  title: "Transitive Type Theory",
  authors: (
    "FranchuFranchu",
    "T6",
  ),
  // Insert your abstract after the colon, wrapped in brackets.
  // Example: `abstract: [This is my abstract...]`
  abstract: [
    We introduce a novel type system that offers a transitive instance-of relationship and explores its potential applications. With minor adjustments, this type system accommodates uninhabited and homotopic types, making it useful for theorem-proving and mathematically elegant.
  ],
)

// We generated the example code below so you can see how
// your document will look. Go ahead and replace it with
// your own content!

= Introduction

In contemporary type systems, there are two major issues: redundancy and asymmetry. The redundancy arises from the fact that the Pi type $limits(Pi)_(x: T) (F space x)$ and the lambda constructor $lambda (x:T)(F space x)$ carry the same information: the type $T$ and the function $F$.

The asymmetry in most contemporary type systems exists between the type-of relationship and the instance-of relationship. While there is a top type, there are frequently no bottom types. Lambdas can be applied, but Pi types cannot.

We propose a new type system that addresses both issues. Our system eliminates the redundancy between the Pi type and lambda constructor by treating them as equivalent. We achieve this by having the type of a lambda be another lambda. This approach allows us to combine the benefits of both the Pi type and the lambda constructor, without any redundancy.

Moreover, our type system eliminates the asymmetry between the type-of and instance-of relationships by using the same rules for both. This has the uncomfortable consequence that *the type-of relationship is transitive*, which is the source for the name, Transitive Type Theory.

We have tested our new type system, and it offers significant advantages over traditional type systems. Not only does it remove redundancy and asymmetry, but it also simplifies the syntax, making it more straightforward to use. The resulting type system is more flexible and more expressive, making it an attractive option for developers and researchers alike

== In this paper
#lorem(20)

=== Contributions
#lorem(40)

= Methods

We will describe how we arrived to our typesystem.

Our original goal was to achieve a typesystem where $limits(Pi)_(x: T) (F space x)$ is the same thing as $lambda (x: T) (F space x)$. This is the traditional rule for instance-of relationships between lambdas and Pi types.

#align(center)[$lambda (x: T) (F space x): limits(Pi)_(x: U) (G space x)$ if and only if $U <= T$ and for all $x: U$, $(F space x): (G space x)$]

If we replace the Pi type by another lambda, we get:

#align(center)[$lambda (x: T) (F space x): lambda (x: U) (G space x)$ if and only if $U <= T$ and for all $x: U$, $(F space x): (G space x)$]

If apply eta-reduction and define $"Dm"(F)$ as the domain of $F$, we get:

#align(center)[$F: G$ if and only if $"Dm"(G) <= "Dm"(F)$ and for all $x: "Dm"(G)$, $(F space x): (G space x)$]

We can ignore the subtyping requirement to get a clearer view of what this means.

#align(center)[$F: G$ if and only if for all $x$, $(F space x): (G space x)$]

The above statement is not true because we've altered the right-hand side, but it's quite useful to think about what various parts of the typesystem should work.

#let recmu = $mu^-$
#let recnu = $mu^+$

== The top type

We have substituted the Pi type with lambdas. This, however, brings a problem. In regular type systems, the type of Pi types is a "top" type, sometimes represented as $*$, $"Type"$, or $"Set"$, such that #emph[typeof]$(*) = *$. However, our new type system treats lambdas and Pi types as equivalent, so we cannot differentiate between them. Thus, we cannot identify a "top" type in the same way as traditional systems.

However, let us assume we already have a top type and work out the implications. This should probably still apply, even though $*$ might not be a lambda:
#align(center)[$F: G$ if and only if for all $x$, $(F space x): (G space x)$]

By substituting $G = *$

#align(center)[$F: *$ if and only if for all $x$, $(F space x): (* x)$]

We know $F: *$ is true for all $F$ because $*$ is the top type.

#align(center)[for all $x$ and for all $F$, $(F space x): (* x)$]

$F$ can be any function at all, so it could return any term. For all $z$, $lambda "_"(z)$ is certaintly an option for $F$. Therefore we can substitue $(F x)$ by an arbitray $z$

#align(center)[for all $x$ and for all $z$, $z: (* x)$]

Interestingly, this proves that $(* x)$ should also be the top type. So applying any $x$ to $*$ should return $*$, thus $lambda "_" (*)$ is a valid value for $*$. However, what would be the domain of $*$? We will recall the full typing rule:

#align(center)[$F: G$ if and only if $"Dm"(G) <= "Dm"(F)$ and for all $x: "Dm"(G)$, $(F space x): (G space x)$]

By substituting F and G, as previously described

#align(center)[for all $F$, $"Dm"(*) <= "Dm"(F)$ and for all $x: "Dm"(*)$, $(F space x): *$]

Let us discard the right-hand side condition.

#align(center)[for all $F$, $"Dm"(*) <= "Dm"(F)$]

F can be anything, so $"Dm"(F)$ can be anything too. Thus $"Dm"(*)$ is the universal subtype, which is the bottom type, which we will represent as $!$

$* = lambda("_": !)(*) = ! -> *$

TODO. We can actually follow the same reasoning for ! and arrive that 

$! = lambda("_": *)(*) = * -> !$

We know that:

$* = lambda("_": !)(*) = ! -> * &= (! = * -> !) -> * \
! = lambda("_": *)(*) = * -> ! &= (* = ! -> *) -> !$

However, we've reached a problem, which is that swapping $*$ and $!$ doesn't change anything (!). Any checker for such a typesystem would have to have $*$ and $!$ as special cases.

This is where we borrow a concept from related literature, called the least-fixed point and greatest-fixed point. 

The least fixed point type $#recmu (x) space (F space x)$ is the smallest type $x$ such that $x = (F space x)$.

The greatest fixed point type $#recnu (x) space (F space x)$ is the largest type $x$ such that $x = (F space x)$.

Both of these are recursive constructors, however, they behave differently in regards to typing. This is exactly what we need here.

The typechecking rule is that 

$a: #recmu space (x)(F space x) "iff" forall X ( X >= F(X) arrow a : X) $

$a: #recnu space (x) (F space x) "iff" exists X ( F(X) >= X arrow a: X)$




TODO: Explain transitivity and how we got to it.

= Results

=== Relationships
The resulting type system features the following relationship:

#align(center)[The instance-of relationship: $a < b$]

We say that $a$ is of type $b$. $b$ is a type of $a$, $a$ is an instance of $b$.

=== Terms

The resulting type system features the following term constructors:

#align(center)[Variables: $x$]

Variables can be bound to arguments or to recursive terms.

#align(center)[Lambda: $lambda(T < x < U) "body"$]

Lambdas are the only way to construct functions. All functions can be expressed as lambdas. 

#align(center)[Function application: $(f space x)$]

Function application is the term that does all computation.

#align(center)[Least recursive type: $#recmu (x < U) space (F space x)$]
#align(center)[Greatest recursive type: $#recnu (T < x) space (F space x)$]

Here, we introduce two recursive term constructors that are equivalent with respect to computation. The computation rule is that $mu (T < x < U) (F space x) = (F space mu (T < x < U) (F space x))$, which applies to both constructors. However, these constructors exhibit different behavior during type-checking

In related literature, $#recnu$ is sometimes referred to as $iota$ or $nu$

#align(center)[Infinitesimally larger type: $x^+$]
#align(center)[Infinitesimally smaller type: $x^-$]

$x^+$ is defined as "the smallest $x^+$ such that $x < x^+$ and for all $x < y$, $x^+ <= y$"

$x^-$ is defined as "the smallest $x^-$ such that $x^- < x$ and for all $y < x$, $y <= x^-$"

=== Rules




= Related Work
#lorem(500)
