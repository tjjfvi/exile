#!/usr/bin/env python3
# 0BSD license
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

"""A prototype Exile typechecker, to test ideas"""

__author__ = "FranchuFranchu"
__email__ = "fff999abc999@gmail.com"
__license__ = "0BSD"

from dataclasses import dataclass, field
from typing import Callable
from lark import Lark, Tree, Transformer, Visitor

def visit_transform_ast(ast: Tree, map: dict) -> "Term":
	if str(ast.data) in ("lambda_untyped", "recursive", "self_"):
		body = lambda x: visit_transform_ast(ast.children[1], {**map, str(ast.children[0]): x})
	if ast.data == "lambda_typed":
		if len(ast.children) == 2:
			body = lambda x: visit_transform_ast(ast.children[1], {**map})
			typ = visit_transform_ast(ast.children[0], map)
		else:
			body = lambda x: visit_transform_ast(ast.children[2], {**map, str(ast.children[0]): x})
			typ = visit_transform_ast(ast.children[1], map)
		return LambdaTerm(typ, body)
	elif ast.data == "lambda_untyped":
		return LambdaTerm(TopType(), body)
	elif ast.data == "recursive":
		return RecursiveTerm(body)
	elif ast.data == "self_":
		return SelfTerm(body)
	elif ast.data == "top":
		return TopType()
	elif ast.data == "bottom":
		return BottomType()
	elif ast.data == "var":
		if ast.children[0] == "Type":
			return TopType()
		return map[str(ast.children[0])]
	elif ast.data == "apply":
		return ApplyTerm(visit_transform_ast(ast.children[0], map), visit_transform_ast(ast.children[1], map))
	else:
		raise ValueError(ast)
	

TERM_PARSER = Lark('''
?term:	lambda_typed
	| lambda_untyped
	| self_
	| recursive
	| top
	| bottom
	| var
	| paren_apply

?term_noparen:	lambda_typed
	| lambda_untyped
	| self_
	| recursive
	| top
	| bottom
	| var
	| apply
	| paren_apply

lambda_untyped: ("@"|"λ") NAME term
lambda_typed: ("@"|"λ") "(" NAME? ":" term_noparen ")"   term
recursive: ("%"|"μ") NAME term
self_: ("$"|"ξ"|"ζ"|"ι") NAME term
apply: term " "term
paren_apply: "(" (term|apply) " " term ")" -> apply // the term|apply magic allows (f a b c d) to be parsed correctly
top: "*"
bottom: "!"
var: NAME
NAME: /\w+/


%import common.WS
%ignore WS
''', start = 'term')

Term = "Term"
class Term:
	def is_instance_of(self, other: Term) -> Term:
		return other.is_type_of(self)
	def is_type_of(self, other: Term) -> Term:
		return False
	def is_supertype_of(self, other: Term):
		return self == other
	def is_subtype_of(self, other: Term) -> bool:
		return self == other or other.is_supertype_of(self)
	def apply_from(self, other: Term) -> Term:
		return ApplyTerm(self, other)
	def apply_subterm(self, f) -> Term:
		return self
	def as_lambda(self) -> 'LambdaTerm':
		self = self.normalize()
		if isinstance(self, LambdaTerm):
			return self
		elif isinstance(self, RecursiveTerm):
			return self.unroll().as_lambda()
		elif isinstance(self, TopType) or isinstance(self, BottomType):
			return self.as_recursive().as_lambda()
		
		return self
		
	def flatten(self):
		return self.apply_subterm(lambda x: x.flatten())
	def apply_flatten(self):
		return self.apply_from(ForallTerm()).flatten()
		
	def normalize(self):
		return self.apply_subterm(lambda x: x.normalize())
	def unroll(self):
		return self.apply_subterm(lambda x: x.unroll())
	def roll(self):
		return self.apply_subterm(lambda x: x.roll())
	def compare(self, other):
		return self == other
	def to_str(self, depth: int):
		return "???"
	def parse(text: str) -> Term:
		ast = TERM_PARSER.parse(text)
		return visit_transform_ast(ast, {})
	def __repr__(self):
		return self.to_str(0)
	def __str__(self):
		return self.to_str(0)


@dataclass
class LambdaTerm(Term):
	type: Term
	body: Callable[[Term], Term]
	def is_supertype_of(self, other):
		if isinstance(other, BottomType):
			return True
		other = other.as_lambda()
		if isinstance(other, LambdaTerm):
			x = ForallTerm()
			return self.body(InstanceBound(x, other.type)).is_subtype_of(other.body(InstanceBound(x, other.type))) and other.type.is_subtype_of(self.type)
		else:
			return None
	def is_subtype_of(self, other):
		other = other.normalize()
		if isinstance(other, TopType):
			return self
		if isinstance(other, BottomType):
			return None
		other = other.as_lambda()
		if isinstance(other, LambdaTerm):
			x = ForallTerm()
			return self.body(InstanceBound(x, other.type)).normalize().is_subtype_of(other.apply_from(x).normalize())
		return None
	def is_type_of(self, other):
		if type(other).is_instance_of == Term.is_instance_of:
			return False # no infinite looping please
		return other.is_instance_of(self)
	def normalize(self):
		if isinstance(self.body(ForallTerm()).normalize(), TopType):
			return TopType()
		if isinstance(self.body(ForallTerm()).normalize(), BottomType):
			return BottomType()
		return super().normalize()
	flatten = Term.apply_flatten
	def is_instance_of(self, other):
		if isinstance(other, TopType):
			return other
		if isinstance(other, BottomType):
			return False
		
		other = other.as_lambda()
		if isinstance(other, SelfTerm):
			return other.is_type_of(self)
		if isinstance(other, ForallTerm):
			# No term is an instance of all terms.
			return None
		if isinstance(other, LambdaTerm):
			x = ForallTerm()
			print(self, ":", other)
			return other.type.is_subtype_of(self.type) and self.body(InstanceBound(x, other.type)).is_instance_of(other.body(InstanceBound(x, other.type)))
		
		return other.is_supertype_of(self)
	def apply_from(self, other):
		return self.body(InstanceBound(other, self.type)).normalize()
	def apply_subterm(self, f):
		return LambdaTerm(f(self.type), lambda x: f(self.body(x)))
	def compare(self, other):
		x = ForallTerm()
		other = other.as_lambda()
		print(self, "=", other)
		if not isinstance(other, LambdaTerm):
			return False
		return self.type.compare(other.type) and self.body(x).compare(other.body(x))
	def to_str(self, depth):
		if isinstance(self.type, TopType):
			return f'λx{depth} {self.body(NamedTerm(f"x{depth}")).to_str(depth + 1)}'
		return f'λ(x{depth}: {self.type.to_str(depth)}) {self.body(NamedTerm(f"x{depth}")).to_str(depth + 1)}'
	
	
@dataclass
class RecursiveTerm(Term):
	body: Callable[[Term], Term]
	def is_instance_of(self, other: Term) -> Term:
		return self.unroll().is_instance_of(other)
	def is_type_of(self, other: Term) -> Term:
		return self.unroll().is_type_of(other)
	def is_supertype_of(self, other: Term) -> Term:
		if self.compare(other):
			return True
		return self.unroll().is_supertype_of(other)
	def is_subtype_of(self, other: Term) -> Term:
		if self.compare(other):
			return True
		return self.unroll().is_subtype_of(other)
	def unroll(self):
		return self.body(self)
	def roll_once(self):
		# Roll a recursive term once
		# A term μ x body can be rolled into μ x body 
		pass
		
	def compare(self, other):
		if isinstance(other, RecursiveTerm):
			x = ForallTerm()
			return self.body(x).compare(other.body(x))
		return self.unroll().compare(other)
	def normalize(self):
		return self
	
	def flatten(self):
		return self.body(ForallTerm()).flatten()
		
	def apply_subterm(self, f):
		return RecursiveTerm(lambda x: f(self.body(x)))
	def to_str(self, depth):
		return f'μx{depth} {self.body(NamedTerm(f"x{depth}")).to_str(depth + 1)}'

@dataclass	
class SelfTerm(Term):
	body: Callable[[Term], Term]
	def is_type_of(self, other):
		return self.apply_from(other).is_type_of(other)
	def is_subtype_of(self, other):
		return False
	def apply_from(self, other):
		return self.body(InstanceBound(other, self))
	def flatten(self):
		return self.apply_flatten().flatten()
	def apply_subterm(self, f):
		return SelfTerm(lambda x: f(self.body(x)))
	def compare(self, other):
		x = ForallTerm()
		if not isinstance(other, SelfTerm):
			return False
		return self.body(x).compare(other.body(x))
	def to_str(self, depth):
		return f'ξx{depth} {self.body(NamedTerm(f"x{depth}")).to_str(depth + 1)}'

@dataclass
class ForallTerm(Term):
	identifier: object = field(default_factory=object)
	def to_str(self, depth):
		return f'Ɐx{str(id(self.identifier))[-4:]}'
	def compare(self, other):
		return self.identifier == other.identifier
	
@dataclass
class InstanceBound(Term):
	instance: Term
	type: Term
	def is_instance_of(self, typ):
		print(self, ":", typ)
		print(self.type, "<=", typ)
		print(self.type.is_subtype_of(typ))
		return self.type.is_subtype_of(typ) or self.instance.is_instance_of(typ)
	def is_subtype_of(self, supertype):
		return self == supertype or self.instance == supertype or self.instance.is_subtype_of(supertype)
	def to_str(self, depth):
		return f'({self.instance.to_str(depth)} :: {self.type.to_str(depth)})'
	def normalize(self):
		return InstanceBound(self.instance.normalize(), self.type.normalize())
	def compare(self, other):
		return self.instance.compare(other.instance) and self.type.compare(other.type) 

@dataclass
class SubtypeBound(Term):
	subtype: Term
	supertype: Term
	def is_subtype_of(self, supertype):
		return self.supertype.is_subtype_of(supertype) or self.subtype.is_subtype_of(supertype)
	def to_str(self, depth):
		return f'{self.instance.to_str(depth)} <= {self.type.to_str(depth)}'
	def normalize(self):
		return SubtypeBound(self.subtype.normalize(), self.supertype.normalize())
	def compare(self, other):
		return self.subtype.compare(other.subtype) and self.supertype.compare(other.supertype) 

@dataclass
class ApplyTerm(Term):
	function: Term
	argument: Term
	def to_str(self, depth):
		return f'({self.function.to_str(depth)} {self.argument.to_str(depth)})'
	def normalize(self):
		function = self.function.as_lambda().normalize()
		argument = self.argument.normalize()
		if function.apply_from(argument) != function:
			return function
		else:
			ApplyTerm(function, argument)
	def is_subtype_of(self, other):
		if other.is_supertype_of != Term.is_supertype_of:
			if isinstance(other, ApplyTerm):
				if self.function == other.function:
					# TODO what about contravariance?
					return (self.argument.is_subtype_of(other.argument))
					pass
					
		return other.is_supertype_of(self)
	def compare(self, other):
		return self.function.compare(other.function) and self.argument.compare(other.argument) 

@dataclass
class BottomType(Term):
	def is_subtype_of(self, other):
		return True
	def is_type_of(self, other):
		# Bot is empty.
		return False
	def as_recursive(self):
		return RecursiveTerm(lambda bot: LambdaTerm(Top, lambda _: bot))
	def to_str(self, depth):
		return '!'

@dataclass
class TopType(Term):
	def is_supertype_of(self, other):
		return True
	def is_type_of(self, other):
		return True
	def as_recursive(self):
		return RecursiveTerm(lambda top: LambdaTerm(Bot, lambda _: top))
	def apply_from(self, other):
		return self.as_recursive().as_lambda().apply_from(other)
	def to_str(self, depth):
		return '*'
		
@dataclass
class NamedTerm(Term):
	name: str
	def to_str(self, depth):
		return self.name

Bot = BottomType()
Top = TopType() # RecursiveTerm(lambda top: LambdaTerm(Bot, lambda _: top))

Unit_new = LambdaTerm(Top, lambda p: LambdaTerm(Top, lambda new: new))
Bool_true = LambdaTerm(Top, lambda p: LambdaTerm(Top, lambda t: LambdaTerm(Top, lambda f: t)))
Bool_false = LambdaTerm(Top, lambda p: LambdaTerm(Top, lambda t: LambdaTerm(Top, lambda f: f)))
Bool = RecursiveTerm(lambda Bool: SelfTerm(lambda bool: LambdaTerm(
	LambdaTerm(Bool, lambda _: Top), lambda p: 
	LambdaTerm(ApplyTerm(p, Bool_true), lambda t: 
	LambdaTerm(ApplyTerm(p, Bool_false), lambda f: 
	ApplyTerm(p, bool)
	)))))

Unit_new = Term.parse("@p @new new")
Unit = Term.parse("%Unit $unit @(P: @(:Unit) *) @(new: (P @p @new new)) (P unit)")
Bool_true = Term.parse("@p @t @f t")
Bool_false = Term.parse("@p @t @f f")
Bool = Term.parse("%Bool $bool @(P: @(:Bool) *) @(t: (P @p @t @f t)) @(f: (P @p @t @f t)) (P bool)")
Equal = Term.parse("λT λ(x: T) λ(y: T) λ(P: λ(x: T) Type) λ(a: P x) (P y)")
Equal_refl = Term.parse("λT λ(x: T) λ(P: λ(x: T) Type) λ(a: P x) a")
Equal_refl_type = Term.parse(f"λT λ(x: T) λ(P: λ(x: T) Type) λ(a: P x) (P x)")
Equal_Bool_true = ApplyTerm(ApplyTerm(ApplyTerm(Equal, Bool), Bool_true), Bool_true).normalize()
Equal_refl_Bool_true = ApplyTerm(ApplyTerm(Equal_refl, Bool), Bool_true).normalize()

def test():
	#print(Bool)
	#print(Bool.unroll().compare(Bool.unroll()))
	#return
	# assert Equal_refl_Bool_true.is_instance_of(Equal_Bool_true)
	
	type_ = ForallTerm()
	term = InstanceBound(ForallTerm(), type_)

	assert term.is_instance_of(type_)
	assert not term.is_subtype_of(type_)
	
	assert type_.is_subtype_of(Top)
	
	assert Bot.is_subtype_of(type_)
	assert Bool_true.is_instance_of(Bool)
	assert Bool_false.is_instance_of(Bool)
	
	assert not Unit_new.is_instance_of(Bool)
	assert not Bool_true.is_instance_of(Unit)
	assert Equal_refl.is_instance_of(Equal_refl_type)
	
test()
