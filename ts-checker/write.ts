import { Term } from "./parser.ts";

export function writeTerm(term: Term): string {
  if (term.kind === "top") return "Term.top";
  if (term.kind === "bot") return "Term.bot";
  if (term.kind === "app") {
    return `(Term.apply ${writeTerm(term.func)} ${writeTerm(term.arg)}`;
  }
  if (term.kind === "lambda") {
    return `(Term.lam ${
      writeTerm(term.arg.bound ?? { kind: "top" })
    } @${term.arg.name} ${writeTerm(term.body)})`;
  }
  if (term.kind === "rec") {
    return `(Term.rec @${term.arg.name} ${writeTerm(term.body)})`;
  }
  if (term.kind === "self") {
    return `(Term.self @${term.arg.name} ${writeTerm(term.body)})`;
  }
  if (term.kind === "var") {
    return term.name;
  }
  if (term.kind === "bind") {
    return `let ${term.var.name} = ${writeTerm(term.val)};// check ${
      writeTerm(term.var.bound ?? { kind: "top" })
    }\n${writeTerm(term.body)}`;
  }
  return null!;
}
