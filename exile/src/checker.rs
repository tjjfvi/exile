use crate::{term::Term, traceback::{TracebackStack, TracebackTree, TracebackBranch, TracebackEntry, Judgement}};

#[derive(Default)]
pub struct Checker {
	// TODO perhaps some metadata for debugging is good here?
	forall_meta: Vec<()>,
}

pub type Result<T> = core::result::Result<(T, TracebackTree), TracebackTree>;

pub fn result_get_tb<T>(res: Result<T>) -> (Option<T>, TracebackTree) {
	match res {
	    Ok((t, tb)) => (Some(t), tb),
	    Err(tb) => (None, tb),
	}
}

pub fn map_tb<T>(res: &mut Result<T>, f: impl FnOnce(&mut TracebackBranch)) {
	match res {
	    Ok((t, tb)) => f(tb),
	    Err(tb) => f(tb),
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
	fn with_comment<T>(&mut self, s: impl ToString, f: impl FnOnce(&mut Self) -> Result<T>) -> Result<T> {
		let entry = TracebackEntry::Comment(s.to_string());
		let mut ret = f(self);
		map_tb(&mut ret, |tb| {
			let a = std::mem::take(tb);
			*tb = TracebackBranch::Single(entry, Some(Box::new(a)));
		});
		ret
	}
	fn with_judgement<T>(&mut self, judgement: Judgement, f: impl FnOnce(&mut Self) -> Result<T>) -> Result<T> {
		let entry = TracebackEntry::Judgement(judgement);
		let mut ret = f(self);
		map_tb(&mut ret, |tb| {
			let a = std::mem::take(tb);
			*tb = TracebackBranch::Single(entry, Some(Box::new(a)));
		});
		ret
	}
	fn result_and<R, L, T>(&mut self,
		left: impl FnOnce(&mut Self) -> Result<L>,
		right: impl FnOnce(&mut Self) -> Result<R>,
		combine: impl FnOnce(L, R) -> T
	) -> Result<T> {
		let (left_res, left_tb) = result_get_tb(left(self));
		let (right_res, right_tb) = result_get_tb(right(self));
		
		let new_tb = TracebackBranch::And(Box::new(left_tb), Box::new(right_tb));
		
		if let Some((l, r)) = left_res.map(|x| Some((x, right_res?))).flatten() {
			Result::Ok((combine(l, r), new_tb))
		} else {
			Result::Err(new_tb)
		}
	}
	
	fn error<T>(&mut self) -> Result<T> {
		Result::Err(TracebackBranch::default())
	}
	
	pub fn instance(&mut self, term: Term, typ: Term) -> Result<()> {
		self.with_judgement(crate::traceback::Judgement::Instance(term, typ), |this|
			match this {
				_ => {
					this.with_comment("Can't check term", |this| {
						this.error()
					})
				}
			}
		)
	}
	pub fn compare(&mut self, term: Term, typ: Term)  -> Result<()>{
		self.with_judgement(crate::traceback::Judgement::Equal(term, typ), |this|
			match this {
				_ => {
					this.with_comment("Can't check term", |this| {
						this.error()
					})
				}
			}
		)
	}
}