use crate::{term::Term, traceback::{TracebackStack, TracebackTree, TracebackBranch, TracebackEntry, Judgement}};

#[derive(Default)]
pub struct Checker {
	// TODO perhaps some metadata for debugging is good here?
	forall_meta: Vec<()>,
}

#[derive(Debug)]
pub struct ReduceResult(Term, TracebackTree);

impl ReduceResult {
	fn with_entry(mut self, entry: TracebackEntry) ->Self {
		self.1 = TracebackBranch::Single(entry, Box::new(std::mem::take(&mut self.1)));
		self
	}
	fn with_comment(self, s: impl ToString) -> Self {
		self.with_entry(TracebackEntry::Comment(s.to_string()))
	}
	fn with_judgement(self, j: Judgement) -> Self {
		self.with_entry(TracebackEntry::Judgement(j))
	}
	fn from_term(term: Term) -> Self {
		Self(term.clone(), TracebackBranch::Leaf(term))
	}
	fn error() -> Self {
		Self::from_term(Term::Error)
	}
}

impl Checker {
	fn new_forall<T>(&mut self, f: impl FnOnce(&mut Self, Term) -> T) -> T {
		let forall = Term::Forall { id: self.forall_meta.len() };
		self.forall_meta.push(());
		let ret = f(self, forall);
		self.forall_meta.pop();
		ret
	}
	
	pub fn reduce(&mut self, term: Term) -> ReduceResult {
		match term {
			_ => ReduceResult::error().with_comment("I don't know how to reduce this")
		}
	}
}