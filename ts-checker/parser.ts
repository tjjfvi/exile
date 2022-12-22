import { lex, Token, TokenKind } from "./lexer.ts";

export function parse(source: string) {
  return parseTerm(new TokenStream(lex(source)));
}

class TokenStream {
  base: Iterator<Token, undefined>;
  current?: Token;

  constructor(base: Iterable<Token>) {
    this.base = base[Symbol.iterator]();
    this.next();
  }

  next() {
    this.current = this.base.next().value;
    return this;
  }

  expect(kind?: TokenKind): this {
    if (this.current?.kind !== kind) {
      throw new Error(`expected ${kind}, got ${this.current?.kind}`);
    }
    return this;
  }
}

export type Var = { kind: "var"; name: string; bound?: Term };
export type App = { kind: "app"; func: Term; arg: Term };
export type Lambda = { kind: "lambda"; arg: Var; body: Term };
export type Rec = { kind: "rec"; arg: Var; body: Term };
export type Self = { kind: "self"; arg: Var; body: Term };
export type Bind = { kind: "bind"; var: Var; val: Term; body: Term };
export type Top = { kind: "top" };
export type Bot = { kind: "bot" };

export type Term =
  | Var
  | App
  | Lambda
  | Rec
  | Self
  | Bind
  | Top
  | Bot;

function _parseTerm(tokens: TokenStream, canBind = true): Term {
  if (tokens.current?.kind === "lambda") {
    return parseLambda(tokens, canBind);
  }
  if (tokens.current?.kind === "mu") {
    return parseRec(tokens, canBind);
  }
  if (tokens.current?.kind === "xi") {
    return parseSelf(tokens, canBind);
  }
  if (tokens.current?.kind === "*") {
    tokens.next();
    return { kind: "top" };
  }
  if (tokens.current?.kind === "!") {
    tokens.next();
    return { kind: "bot" };
  }
  if (tokens.current?.kind === "(") {
    tokens.next();
    const term = parseTerm(tokens);
    tokens.expect(")").next();
    return term;
  }
  tokens.expect("ident");
  const name = tokens.current!.content;
  tokens.next();
  if (
    canBind && (tokens.current?.kind === ":" || tokens.current?.kind === "=")
  ) {
    let bound;
    if (tokens.current?.kind === ":") {
      tokens.next();
      bound = parseTerm(tokens, false);
    }
    tokens.expect("=").next();
    const val = parseTerm(tokens);
    tokens.expect(";").next();
    const body = parseTerm(tokens);
    return { kind: "bind", var: { kind: "var", name, bound }, val, body };
  }
  return { kind: "var", name };
}

function parseTerm(tokens: TokenStream, canBind = true): Term {
  let term = _parseTerm(tokens, canBind);
  while (
    tokens.current &&
    tokens.current.kind !== ")" && tokens.current.kind !== ":" &&
    tokens.current.kind !== "=" && tokens.current.kind !== ";"
  ) {
    term = { kind: "app", func: term, arg: _parseTerm(tokens, canBind) };
  }
  return term;
}

function parseLambda(tokens: TokenStream, canBind = true): Lambda {
  tokens.expect("lambda").next();
  const arg = parseVar(tokens, true);
  const body = parseTerm(tokens, canBind);
  return { kind: "lambda", arg, body };
}

function parseRec(tokens: TokenStream, canBind = true): Rec {
  tokens.expect("mu").next();
  const arg = parseVar(tokens, false);
  const body = parseTerm(tokens, canBind);
  return { kind: "rec", arg, body };
}

function parseSelf(tokens: TokenStream, canBind = true): Self {
  tokens.expect("xi").next();
  const arg = parseVar(tokens, false);
  const body = parseTerm(tokens, canBind);
  return { kind: "self", arg, body };
}

function parseVar(tokens: TokenStream, typed: boolean): Var {
  if (typed && tokens.current?.kind === "(") {
    tokens.next();
    tokens.expect("ident");
    const name = tokens.current.content;
    tokens.next().expect(":").next();
    const bound = parseTerm(tokens);
    tokens.expect(")").next();
    return { kind: "var", name, bound };
  }
  tokens.expect("ident");
  const name = tokens.current!.content;
  tokens.next();
  return { kind: "var", name };
}
