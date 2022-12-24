use checker::Checker;
use term::Term;

pub mod parser;
pub mod term;
pub mod hparser;
pub mod checker;
pub mod traceback;

fn main() {
    let mut checker = Checker::default();
    let t = checker.reduce(Term::Top);
    println!("{:?}", t);
}
