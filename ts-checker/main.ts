import { parse } from "./parser.ts";
import { writeTerm } from "./write.ts";

async function generate_prelude() {
  return [
    await Deno.readTextFile("Equal.xil"),
    await Deno.readTextFile("Bool.xil"),
    await Deno.readTextFile("Unit.xil"),
    await Deno.readTextFile("Nat.xil"),
  ]
}

function term_to_hvm(prelude: string[], term: string) {
  return writeTerm(parse([...prelude, term].join("\n\n")))
}

async function generate_main() {
  let prelude = await generate_prelude()
  if (Deno.args[0] == "instance" || Deno.args[0] == "subtype" || Deno.args[0] == "equal") {
    assert(Deno.args.len() > 2);
    let term_1 = term_to_hvm(prelude, Deno.args[1])
    let term_2 = term_to_hvm(prelude, Deno.args[2])
    
    return `(Checker.${Deno.args[0]} State.empty (Checker.eval ${term_1}) (Checker.eval ${term_2}))`
  };
  if (Deno.args[0] == "check") {
    assert(Deno.args.len() > 1);
    return `(Checker.normalize_check State.empty ${term_to_hvm(prelude, Deno.args[1])})`
  };
  // Do default action
  let code = "Bool.and Nat.zero Bool.true"
  return `(Checker.normalize_check State.empty ${term_to_hvm(prelude, code)})`
}

let code = "CheckProgram =\n" + await generate_main();
await Deno.writeTextFile("program.hvm", code, {
  append: true,
})
