import { parse } from "./parser.ts";
import { writeTerm } from "./write.ts";

console.log(
  "Program =\n" + writeTerm(parse([
    await Deno.readTextFile("Equal.xil"),
    await Deno.readTextFile("Bool.xil"),
    // await Deno.readTextFile("Nat.xil"),
    Deno.args[0] || "Bool.and Bool.true",
  ].join("\n\n"))),
);
