import { parse } from "./parser.ts";

console.log(parse([
  await Deno.readTextFile("Equal.xil"),
  await Deno.readTextFile("Bool.xil"),
  await Deno.readTextFile("Nat.xil"),
  "one = Nat.succ Nat.zero; Nat.add one one",
].join("\n\n")));
