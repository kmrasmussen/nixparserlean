# Parser Internals

The parser is split across two files:

- `NixParserLean/Parser/Basic.lean` — parser state, `ParseError`, the
  `ParserM` monad, whitespace and comment handling,
  character/token/keyword primitives, the identifier and number lexers, and
  the path literal recogniser.
- `NixParserLean/Parser.lean` — the recursive-descent expression/binding
  grammar built on top of those primitives.

The whole parser is handwritten and has no external dependencies.

## Parser state

```lean
structure ParserState where
  remaining : List Char
  offset    : Nat := 0
  line      : Nat := 1
  column    : Nat := 1
```

The input is stored as a `List Char`. `offset` tracks how many characters have
been consumed, while `line` and `column` track source position for diagnostics.
The monad is `abbrev ParserM := Except ParseError` — every parser function
returns either a value or a structured parse error.

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
| `parseExpr` | `let`, `if`, `assert`, `with`, lambdas | — |
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
- `-` or digit — integer or float literal (optionally negative)
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

`parseAttrPath` accepts identifier segments, quoted string segments, and bare
`${...}` dynamic segments:

```nix
a.b
a."foo-bar"
"foo-bar".nested
a.${name}
a."prefix-${name}"
```

Quoted text-only segments become static names. Quoted strings with
interpolation, and bare `${...}` segments, become dynamic `AttrPathPart`
values. Validation still checks duplicate and prefix conflicts for fully static
paths only; dynamic names are preserved for later desugaring instead of guessed
at validation time.

## Selection and path disambiguation

Plain attribute selection remains whitespace-tight: `pkg.meta` parses as
selection, while `pkg .meta` does not. Dynamic selection has a narrow exception
for real-world Nix code that formats the selector on the next line:

```nix
attrs
  .${name}
```

`parseSelect` recognizes that pattern only when the dot is followed directly by
`${`. This keeps path arguments such as `import ./default.nix` and
`fileContents ./.version` available to `parseApp` as path literals instead of
being claimed as spaced selections from the function name.

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
- `inherit "or";` and `inherit (scope) "quoted-name";` preserve static quoted
  names in the inherited name list
- `a.b.c = expr;` → `Binding.assign`

Dynamic quoted inherit names are still rejected at parse time; inherit names
are currently static strings.

`parseBindingsUntil endChar` loops until it sees `endChar` without consuming it. `parseLetBindings` loops until it peeks `in`.

## Operator-token disambiguation

`operatorToken` (in `Parser/Basic.lean`) is a wrapper around `token` that
rejects certain pairs to avoid confusing single-character operators with their
longer relatives:

| `operatorToken` | rejected if next char is |
|---|---|
| `+` | `+` (i.e. would form `++`) |
| `-` | `>` (`->`) |
| `/` | `/` (`//`) |
| `<` | `=` (`<=`) |
| `>` | `=` (`>=`) |

This is what lets `parseAdd` ask for `+` without accidentally claiming the
`++` of `parseConcat`, and similarly for the other near-collisions.

## Error messages

All parser errors are produced by `failAt`, which formats:

```
parse error at offset N (line L, column C): <message>
```

The `parse error at offset` prefix is significant — the Rust e2e runner uses it to classify failures as `ParseFail`.
