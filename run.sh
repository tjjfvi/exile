#!/bin/bash

kind2 to-hvm hvm-typechecker/checker.kind2 > program.hvm &&
deno run -A ts-checker/main.ts >> program.hvm &&
hvm r -f program.hvm --debug

