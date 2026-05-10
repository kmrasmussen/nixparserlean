# Parser Internals

The parser lives in `NixParserLean/Parser.lean`. It is a handwritten recursive-descent parser with no external dependencies.

## Parser state

```lean
structure ParserState where
  remaining : List Char
  offset    : Nat := 0
```

The input is stored as a `List Char`. `offset` tracks how many characters have been consumed, used in error messages. The monad is `Except String` — every parser function returns either a value or an error string.

## Whitespace and comments

`skipSpace` is called before every token. It consumes:

- ASCII whitespace characters (space, tab, newline, etc.)
- `# ...` line comments (consumed up to and including `\n`)
- `/* ... */` block comments (no nesting)

Comments are fully discarded. They do not appear in the AST.

## Operator precedence

The expression parser is split into a chain of functions, each handling one precedence level. Lower in the list means tighter binding (higher precedence).

| Function | Operator(s) | Associativity |
|---|---|---|
| `parseExpr` | `let`, `if`, `with`, lambdas | — |
| `parseImplies` | `->` | right |
| `parseOr` | `\|\|` | left |
| `parseAnd` | `&&` | left |
| `parseEquality` | `==`, `!=` | left |
| `parseHasAttr` | `?` | left |
| `parseComparison` | `<`, `>`, `<=`, `>=` | left |
| `parseUpdate` | `//` | left |
| `parseConcat` | `++` | left |
| `parseAdd` | `+`, `-` | left |
| `parseMul` | `*`, `/` | left |
| `parseUnary` | `!`, unary `-` | right |
| `parseApp` | function application | left |
| `parseSelect` | `.` (attribute selection) | left |
| `parseAtom` | literals, identifiers, `(...)`, `[...]`, `{...}` | — |

Each binary level uses a `loop` helper that re-parses the right-hand side and accumulates a left-associative tree.

## Atom parsing (`parseAtom`)

Dispatches on the current character after skipping whitespace:

- `"` — quoted string (with `\n`, `\t`, `\"`, `\\` escapes and interpolation)
- `''` — indented string with interpolation
- `(` — parenthesized expression
- `[` — list
- `{` — attribute set
- `-` or digit — integer (optionally negative)
- path-start characters — path literal (see below)
- otherwise — identifier, then matched against `true`, `false`, `null`, `rec`

## Path literals

`isPathStart` recognises path prefixes:

| Pattern | Example |
|---|---|
| `./` | `./foo.nix` |
| `../` | `../bar` |
| `/` followed by a non-space character (not `//`) | `/nix/store/...` |
| `~/` | `~/config.nix` |
| `<` | `<nixpkgs>` |

Angle-bracket paths (`<...>`) are read until `>`. All other paths are read until a whitespace or delimiter character (`)`  `]`  `}`  `;`  `,`).

## Attribute paths

`parseAttrPath` accepts identifier segments and static quoted string segments:

```nix
a.b
a."foo-bar"
"foo-bar".nested
```

Quoted segments reuse the string parser, but only text-only strings are accepted
as static attribute names. Interpolated names such as `"${name}"` need a richer
attribute-path AST and are intentionally left for a later slice.

## Lambda detection

`parseLambda` is attempted via backtracking inside `parseExpr`. If it fails (no `:` found after the parameter), the parser falls back to `parseOr`. This means lambda syntax is tried speculatively and never consumes input on failure.

## Application parsing (`parseApp`)

`parseApp` collects consecutive argument atoms into a left-associative `app` tree. It stops when:

- EOF or a closing delimiter (`]`, `}`, `;`, `,`, `:`) is reached.
- The current token is a stop keyword (`in`, `then`, `else`).
- `//` is seen (it is an operator at a looser level, not an argument).
- The next token does not look like the start of an expression.

## Binding parsing

`parseBinding` is called inside attribute sets and `let` bodies. It dispatches on whether the first identifier is `inherit`:

- `inherit (scope) a b;` → `Binding.inheritFrom`
- `inherit a b;` → `Binding.inherit`
- `a.b.c = expr;` → `Binding.assign`

`parseBindingsUntil endChar` loops until it sees `endChar` without consuming it. `parseLetBindings` loops until it peeks `in`.

## Error messages

All errors are produced by `failAt`, which formats:

```
parse error at offset N: <message>
```

The `parse error at offset` prefix is significant — the Rust e2e runner uses it to classify failures as `ParseFail`.
