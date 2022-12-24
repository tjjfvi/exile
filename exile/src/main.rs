use checker::Checker;
use term::Term;

pub mod term;
pub mod hparser;
pub mod checker;
pub mod traceback;

fn main() {
    let mut checker = Checker::default();
    let t = checker.instance(Term::Top, Term::Top);
    println!("{:?}", t);
}
