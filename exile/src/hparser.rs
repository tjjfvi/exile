use std::{cell::RefCell, rc::Rc};

use crate::{parser::*, term::Term};

pub struct ParserState {
    data: Vec<String>,
}

impl ParserState {
    fn get_depth(&self, var: String) -> Option<usize> {
        self.data.iter().enumerate().rev().find_map(|(idx, name)| if var == *name {
            Some(idx)
        } else {
            None
        })
    }
    fn get_term(&self, var: String) -> Option<Term> {
        self.get_depth(var).map(|x| Term::ReplaceVar { id: x })
    }
    fn register_var(&mut self, var: String) -> usize {
        self.data.push(var);
        self.data.len() - 1
    }
    fn pop_var(&mut self) {
        self.data.pop();
    }
}

fn parse_var<'a>(table: Rc<RefCell<ParserState>>, state: State<'a>) -> Answer<'a, Term> {
    let (state, name) = name1(state)?;
    let term = table.borrow().get_term(name).unwrap();
    Ok((state, term))
}

fn parse_body(table: Rc<RefCell<ParserState>>, state: State) -> Answer<Box<dyn Fn(Term) -> Term>> {
    let (state, name) = name1(state)?;
    let idx = table.borrow_mut().register_var(name);
    let (state, body) = parse_term(table.clone(), state)?;
    let body = Box::new(move |arg| body.replace_var(idx, arg));
    table.borrow_mut().pop_var();
    Ok((state, body))
}

fn parse_rec_self(table: Rc<RefCell<ParserState>>, state: State) -> Answer<Term> {
    let (state, _) = skip(state)?;
    let (state, c) = peek_char(state)?;
    match c {
        'μ' | '%' => { 
            let (state, body) = parse_body(table.clone(), state)?;
            Ok((state, Term::Recursive { body }))
        }
        'ξ' | '$' => {
            let (state, body) = parse_body(table.clone(), state)?;
            Ok((state, Term::SelfType { body }))
        }
        _ => {
            todo!();
         
    }
        }
}

pub fn make_parser<'a, T: 'static>(table: Rc<RefCell<ParserState>>, f: fn(Rc<RefCell<ParserState>>, State) -> Answer<T>) -> Parser<'a, Option<T>> {
    Box::new({ let table = table.clone(); move |state| { let table = table.clone(); maybe(Box::new(move |state| f(table.clone(), state)), state )}})
}

pub fn parse_term<'a>(table: Rc<RefCell<ParserState>>, state: State<'a>) -> Answer<'a, Term> {
    grammar("term", &[
        make_parser(table.clone(), parse_var),
    ], state)
}