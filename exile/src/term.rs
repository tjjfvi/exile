use std::{any::Any, fmt::Display};

use crate::traceback::TracebackStack;

pub enum Term {
	Top,
	Lambda { typ: Box<Term>, body: Box<dyn Fn(Term) -> Term>},
	Recursive { body: Box<dyn Fn(Term) -> Term>},
	SelfType { body: Box<dyn Fn(Term) -> Term>},
	Apply { function: Box<Term>, argument: Box<Term> },
	Forall { id: usize },
	InstanceBound { instance: Box<Term>, typ: Box<Term> },
	TypeofBound { value: Box<Term> },
	Attach { value: Box<Term>, metadata: Box<dyn Any> }
}

pub struct DisplayWrapper<T: Fn(&mut core::fmt::Formatter) -> Result<(), core::fmt::Error>>(T);

impl<T: Fn(&mut core::fmt::Formatter) -> Result<(), core::fmt::Error>> Display for DisplayWrapper<T> {
	fn fmt(&self, mut fmt: &mut core::fmt::Formatter) -> Result<(), core::fmt::Error> {
		self.0(fmt)
	}
}


impl Term {
	fn show(&self, mut fmt: &mut core::fmt::Formatter, depth: usize) -> Result<(), core::fmt::Error> {
		match self {
		    Term::Top => fmt.write_str("*"),
		    Term::Lambda { typ, body } => fmt.write_fmt(format_args!(
		    	"λ(x{}: {}) {}",
		    	depth,
		    	DisplayWrapper(|fmt| typ.show(fmt, depth)),
		    	DisplayWrapper(|fmt| body(Term::Attach { 
		    		value: Box::new(Term::Forall { id: depth }),
		    		metadata: Box::new(format!("x{}", depth)),
		    	}).show(fmt, depth)),
		    )),
		    Term::SelfType { body } => fmt.write_fmt(format_args!(
		    	"ξx{} {}",
		    	depth,
		    	DisplayWrapper(|fmt| body(Term::Attach { 
		    		value: Box::new(Term::Forall { id: depth }),
		    		metadata: Box::new(format!("x{}", depth)),
		    	}).show(fmt, depth)),
		    )),
		    Term::Recursive { body } => fmt.write_fmt(format_args!(
		    	"μx{} {}",
		    	depth,
		    	DisplayWrapper(|fmt| body(Term::Attach { 
		    		value: Box::new(Term::Forall { id: depth }),
		    		metadata: Box::new(format!("x{}", depth)),
		    	}).show(fmt, depth)),
		    )),
		    Term::Apply { function, argument } => fmt.write_fmt(format_args!(
		    	"({} {})",
		    	DisplayWrapper(|fmt| function.show(fmt, depth)),
		    	DisplayWrapper(|fmt| argument.show(fmt, depth)),
		    )),
		    Term::Forall { id } => fmt.write_fmt(format_args!(
		    	"@x{}",
		    	id
		    )),
		    Term::InstanceBound { instance, typ } => fmt.write_fmt(format_args!(
		    	"({} {})",
		    	DisplayWrapper(|fmt| instance.show(fmt, depth)),
		    	DisplayWrapper(|fmt| typ.show(fmt, depth)),
		    )),
		    Term::TypeofBound { value } => fmt.write_fmt(format_args!(
		    	"{{{}}}",
		    	DisplayWrapper(|fmt| value.show(fmt, depth)),
		    )),
		    Term::Attach { value, metadata } => {
		    	if let Some(s) = metadata.downcast_ref::<String>() {
		    		fmt.write_str(s)
		    	} else {
		    		value.show(fmt, depth)
		    	}
		    },
		}
	}
}

impl core::fmt::Display for Term {
	fn fmt(&self, mut fmt: &mut core::fmt::Formatter) -> Result<(), core::fmt::Error> {
		self.show(fmt, 0)
	}
}
