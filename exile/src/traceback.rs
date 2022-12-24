use std::fmt::Formatter;

use crate::term::Term;

pub enum Judgement {
	Instance(Term, Term),
	Equal(Term, Term),
}

impl Judgement {
	pub fn show(&self, mut fmt: &mut Formatter) -> Result<(), core::fmt::Error> {
		match self {
		    Judgement::Instance(a, b) => fmt.write_fmt(format_args!("{} : {}", a, b)),
		    Judgement::Equal(a, b) => fmt.write_fmt(format_args!("{} == {}", a, b)),
		}
	}
}

pub enum TracebackEntry {
	Comment(String),
	Judgement(Judgement)
}

impl TracebackEntry {
	pub fn show(&self, mut fmt: &mut Formatter, depth: usize) -> Result<(), core::fmt::Error> {
		let depth_s = " ".repeat(depth);
		match self {
		    TracebackEntry::Comment(s) => {
		    	fmt.write_str(&depth_s)?;
		    	fmt.write_str(s)
		    },
		    TracebackEntry::Judgement(j) => {
		    	fmt.write_str(&depth_s)?;
		    	j.show(fmt)
		    },
		}
	}
}

pub type TracebackStack = Vec<TracebackEntry>;

pub enum TracebackBranch {
	Leaf(Term),
	Single(TracebackEntry, Box<TracebackTree>),
	Or(Box<TracebackTree>, Box<TracebackTree>),
	And(Box<TracebackTree>, Box<TracebackTree>),
}

impl TracebackBranch {
	pub fn show(&self, mut fmt: &mut Formatter, depth: usize) -> Result<(), core::fmt::Error> {
		let depth_s = " ".repeat(depth);
		match self {
		    TracebackBranch::Single(entry, tree) => {
		    	entry.show(fmt, depth)?;
		    	fmt.write_str("\n")?;
	    		tree.show(fmt, depth + 1)?;
	    		fmt.write_str("\n")?;
		    },
		    TracebackBranch::Or(l, r) => {
		    	fmt.write_str(&depth_s)?;
		    	fmt.write_str("OR")?;
		    	fmt.write_str("\n")?;
		    	l.show(fmt, depth + 1)?;
		    	fmt.write_str("\n")?;
		    	r.show(fmt, depth + 1)?;
		    	fmt.write_str("\n")?;
		    },
		    TracebackBranch::And(l, r) => {
		    	fmt.write_str(&depth_s)?;
		    	fmt.write_str("AND")?;
		    	l.show(fmt, depth + 1)?;
		    	fmt.write_str("\n")?;
		    	r.show(fmt, depth + 1)?;
		    	fmt.write_str("\n")?;
		    },
		    TracebackBranch::Leaf(term) => {
		    	term.show(fmt, 0)?;
		    }
		};
		Ok(())
	}
}

impl Default for TracebackBranch {
	fn default() -> Self {
		TracebackBranch::Leaf(Term::Error)
	}
}


impl core::fmt::Debug for TracebackBranch {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        self.show(f, 0)
    }
}

pub type TracebackTree = TracebackBranch;