const tokenRegex =
  /[^\S\n]*(?:\n[^\S\n]*)?((?<eof>$)|(?<char>[λµξ\\&$():;=!*])|(?<ident>[\w\.]+)|(?<semi>\n\s*)|[^])/gs;

export type TokenKind =
  | "lambda"
  | "mu"
  | "xi"
  | "("
  | ")"
  | ":"
  | ";"
  | "="
  | "*"
  | "!"
  | "ident";

export type Token = { kind: TokenKind; content: string };

const charMap: Record<string, TokenKind | undefined> = {
  "λ": "lambda",
  "\\": "lambda",
  "µ": "mu",
  "&": "mu",
  "ξ": "xi",
  "$": "xi",
};

export function* lex(source: string): IterableIterator<Token> {
  for (const match of source.matchAll(tokenRegex)) {
    const groups = match.groups!;
    if (groups.eof !== undefined) return;
    if (groups.char) {
      yield {
        kind: charMap[groups.char] ?? groups.char as never,
        content: groups.char,
      };
    } else if (groups.ident) {
      yield {
        kind: "ident",
        content: groups.ident,
      };
    } else if (groups.semi) {
      yield { kind: ";", content: ";" };
    } else {
      throw new Error(`invalid char ${JSON.stringify(source[1])}`);
    }
  }
}
