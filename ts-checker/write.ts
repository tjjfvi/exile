import { Term } from "./parser.ts";

export function writeTerm(term: Term): string {
  if (term.kind === "top") return "Term.top";
  if (term.kind === "bot") return "Term.bot";
  if (term.kind === "app") {
    return `(Term.apply ${writeTerm(term.func)} ${writeTerm(term.arg)})`;
  }
  if (term.kind === "lambda") {
    return `(Term.lam ${
      writeTerm(term.arg.bound ?? { kind: "top" })
    } @v${term.arg.name} ${writeTerm(term.body)})`;
  }
  if (term.kind === "rec") {
    return `(Term.rec @v${term.arg.name} ${writeTerm(term.body)})`;
  }
  if (term.kind === "self") {
    return `(Term.self @v${term.arg.name} ${writeTerm(term.body)})`;
  }
  if (term.kind === "var") {
    return `v${term.name}`;
  }
  if (term.kind === "bind") {
    return `let v${term.var.name} = (Term.apply (Term.lam ${
      writeTerm(term.var.bound ?? { kind: "top" })
    } @v v) ${writeTerm(term.val)});\n${writeTerm(term.body)}`;
  }
  return null!;
}
