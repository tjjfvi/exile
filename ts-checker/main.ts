import { parse } from "./parser.ts";
import { writeTerm } from "./write.ts";

console.log(
  "Program =\n" + writeTerm(parse([
    // await Deno.readTextFile("Equal.xil"),
    // await Deno.readTextFile("Bool.xil"),
    // await Deno.readTextFile("Nat.xil"),
    "(\\(x: !) (\\(y: !) y) x)",
  ].join("\n\n"))),
);
