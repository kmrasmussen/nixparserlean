# Design Notes

This document explains specific implementation choices in the codebase — what was done, why it was probably done that way, and what tradeoffs it carries. It is aimed at people reading the source for the first time.

---

## Why Lean 4?

Lean 4 is primarily a theorem prover, but it is also a general-purpose functional programming language with a capable type system. Using it for a Nix parser is an unusual choice, and it is a deliberate one.

The goal is not just to parse Nix files. It is to build a *model* of the Nix language that the type system can reason about — a foundation for later proving properties like "this subset of Nix is referentially transparent" or "evaluation of this fragment always terminates." A model written in Lean can be checked by the kernel. A model written in Python cannot.

Starting with a parser rather than a semantics is also deliberate: it forces you to be precise about what the language actually looks like before you can say anything about what it means.

---

## Why a handwritten parser, not a grammar or combinator library?

The parser in `Parser.lean` is written by hand. Every function is explicit. There are no parser combinator types, no grammar files, no generated code.

The practical reason is that it keeps the mechanics visible. When you are also designing the AST and deciding what the language model should look like, a combinator library adds a layer of abstraction that can obscure the decisions being made. Here, every parsing choice is a function you can read and reason about directly.

The blog post (`blog/2026-05-10-09-11-first-parser.md`) notes that the handwritten approach "gives us a place to discover the right Lean-side model before introducing a parser combinator layer or a more faithful grammar." The parser is intentionally provisional — good enough to make real questions concrete, not designed to be the final word.

---

## The parser monad: `Except String`

```lean
abbrev ParserM := Except String
```

The entire parser runs in `Except String`. This is the simplest possible error monad: either you get a value, or you get an error string. There is no error recovery, no multiple errors, no source spans in the error type.

This is a conscious simplification. A production parser would want structured errors, source locations in a richer form, and recovery strategies. Here, the goal is to get something working and testable quickly. The `failAt` function bakes the offset into the *string*, which is cheap to implement but makes the error impossible to process programmatically later:

```lean
private def failAt (s : ParserState) (msg : String) : ParserM α :=
  throw s!"parse error at offset {s.offset}: {msg}"
```

There is one important consequence of this choice: the Rust e2e runner classifies failures by pattern-matching on the first line of stderr. That only works because the error format is stable and consistent. The design of `failAt` and `bindingConflictMessage` is therefore part of an implicit protocol between the Lean and Rust layers.

---

## Parser state as `List Char`

```lean
structure ParserState where
  remaining : List Char
  offset    : Nat := 0
```

The input is stored as a `List Char` rather than a `String` with an index. In Lean 4, `String` is internally UTF-8 encoded, and random-access indexing requires `O(n)` traversal. Using a `List Char` means `curr?` and `bump` are `O(1)` pattern matches — exactly what a character-at-a-time parser needs.

The tradeoff is memory: a `List Char` has one heap allocation per character (cons cell + payload), which is much more expensive than a flat byte array. For the file sizes being parsed (small Nix expressions, not multi-megabyte files), this is fine. If the parser ever needed to handle large inputs efficiently, the state type would need to change.

`offset` is kept separately as a `Nat` and incremented in `bump`. It is only used for error messages — the parser never seeks backwards by offset, it only inspects `remaining` and calls `bump`.

---

## `curr?`, `bump`, and the absence of mutation

```lean
private def curr? (s : ParserState) : Option Char := s.remaining.head?
private def bump  (s : ParserState) : ParserState :=
  match s.remaining with
  | [] => s
  | _ :: rest => { s with remaining := rest, offset := s.offset + 1 }
```

There is no mutable state. Every parser function takes a `ParserState` and returns a new one. This is standard functional style, but it has a specific benefit here: it makes backtracking trivial. If you have a `ParserState` value `s`, you can attempt to parse something, fail, and fall back to `s` without any undo mechanism because `s` was never modified.

The lambda parser exploits this directly:

```lean
match parseLambda s with
| .ok result => pure result
| .error _   => parseOr s
```

If `parseLambda` fails, the original `s` is passed to `parseOr`. No state was consumed.

---

## Why `skipSpace` is called inside every primitive

Rather than calling `skipSpace` once at the start of each top-level parse function, it is called inside `char`, `token`, `ident`, and `integer`. This means whitespace (and comments) can appear between any two tokens automatically, without every higher-level parser needing to think about it.

The alternative — whitespace-insensitive combinators that each call `skipSpace` explicitly — would require that discipline to be maintained everywhere. The current design encapsulates it: if you use the provided primitives, whitespace is handled for you.

---

## Comments as whitespace

`skipSpace` handles both `#` line comments and `/* */` block comments by consuming them and recursing:

```lean
else if c == '#' then
  skipSpace (skipLineComment (bump s))
else if c == '/' && next? s == some '*' then
  skipSpace (skipBlockComment (bump (bump s)))
```

Comments do not appear in the AST at all. This is a deliberate choice documented in the blog (`blog/2026-05-10-09-12-comments-are-whitespace.md`): the current model is about executable Nix structure, not source-preserving formatting. A formatter or LSP would need comment nodes or trivia ranges; a semantics model should not.

The `next?` helper peeks one character ahead (it calls `curr?` on `bump s`) to distinguish `/*` from a bare `/`. This two-character lookahead is the most complex lookahead in the lexer.

---

## The `mutual` inductive for `Expr` and `Binding`

```lean
mutual
inductive Expr where
  | attrset : (recursive : Bool) -> (bindings : List Binding) -> Expr
  | letIn   : (bindings : List Binding) -> (body : Expr) -> Expr
  ...

inductive Binding where
  | assign      : (path : AttrPath) -> (value : Expr) -> Binding
  | inheritFrom : (scope : Expr) -> (names : List String) -> Binding
  ...
end
```

`Expr` refers to `Binding` (attribute sets contain bindings) and `Binding` refers to `Expr` (bindings contain values). In Lean 4 you cannot have two mutually recursive `inductive` types without wrapping them in a `mutual ... end` block. This is a type-system requirement, not a style choice.

The consequence is that any function over these types must also be `mutual` if it handles both — which is why `validateExpr`, `validateExprs`, and `validateBindings` are all inside a `mutual` block in `Validate.lean`.

---

## The operator precedence chain

The expression parser is split into a cascade of functions:

```
parseExpr
  └─ parseImplies    (->)
       └─ parseOr         (||)
            └─ parseAnd        (&&)
                 └─ parseEquality    (==, !=)
                      └─ parseHasAttr     (?)
                           └─ parseComparison  (<, >, <=, >=)
                                └─ parseUpdate      (//)
                                     └─ parseConcat      (++)
                                          └─ parseAdd         (+, -)
                                               └─ parseMul         (*, /)
                                                    └─ parseUnary       (!, unary -)
                                                         └─ parseApp
                                                              └─ parseSelect   (.)
                                                                   └─ parseAtom
```

Each function parses "its" operator and delegates tighter expressions to the next function. This is the classic recursive-descent way to encode a precedence table. The advantage over a Pratt parser or a table-driven approach is that the code is completely explicit — each level is a function you can read independently, and the precedence order is visible from the call structure.

The `||` / `&&` / equality ordering matches Nix's actual precedence. `//` (attribute set update) sits above comparisons and below list concatenation. Additive and multiplicative arithmetic have separate levels. Function application (`parseApp`) binds tighter than any binary operator, which is why `f x + 1` parses as `(f x) + 1` rather than `f (x + 1)`. Attribute selection (`.`) binds tightest of all the binary forms.

Each level uses an internal `loop` that is left-associative by construction:

```lean
partial def parseOr (s : ParserState) : ParserM (Expr × ParserState) := do
  let (left, s) ← parseAnd s
  let rec loop (expr : Expr) (st : ParserState) := do
    match token "||" st with
    | .ok st =>
        let (right, st) ← parseAnd st
        loop (.binary .or expr right) st
    | .error _ => pure (expr, st)
  loop left s
```

`loop` accumulates into `expr` on every iteration, building `(((a || b) || c) || d)` from left to right.

---

## Why `parseApp` is the hardest level

Function application in Nix is written without any separator: `f x y` means `(f x) y`. This creates an ambiguity: how does the parser know when the argument list ends?

The solution is `isAppStop` and `isAppArgumentStart`. After parsing the function expression, `parseApp` checks whether the next token *looks like* the start of an argument. If it does not, or if `isAppStop` returns true, it stops.

```lean
private def isAppStop (s : ParserState) : Bool :=
  let s := skipSpace s
  match curr? s with
  | none                                        => true
  | some ']' | some '}' | some ';' | some ','
  | some ':'                                    => true
  | some '/' => next? s == some '/'   -- // is an operator, not an argument
  | some c =>
      if isIdentStart c then
        match ident s with
        | .ok (name, _) => isExprStopKeyword name  -- "in", "then", "else"
        | .error _ => false
      else false
```

The tricky cases:

- `//` must stop application. If `//` were treated as an argument start, `f // g` would try to parse `// g` as an argument to `f` and fail. The check `next? s == some '/'` peeks two characters ahead.
- `in`, `then`, `else` must stop application. If `let x = f y in z` were parsed naively, `in` might look like an identifier argument. The keyword check reads the full identifier and compares it.
- `:` must stop application, because `x: body` is a lambda and not an attribute selection.

---

## Lambda detection via backtracking

Lambda syntax (`x: body` or `{ a, b }: body`) overlaps with identifiers and attribute sets at the start. The parser handles this by attempting `parseLambda` speculatively inside `parseExpr`:

```lean
match parseLambda s with
| .ok result => pure result
| .error _   => parseOr s
```

Because state is immutable, if `parseLambda` fails partway through (for example, it finds an identifier but then no `:`), it returns an error and the original `s` is passed to `parseOr` instead. No input is consumed on the failed attempt.

This works correctly because `parseLambda` is the only place where you need lookahead beyond one token. The `char ':'` at the end is what commits the parse to a lambda; until that point, the attempt is exploratory.

---

## Path detection with `isPathStart`

Nix paths are distinguished from other tokens by their prefix characters. The function `isPathStart` inspects up to three characters ahead:

```lean
private def isPathStart (s : ParserState) : Bool :=
  let s := skipSpace s
  match curr? s, next? s, charAt? 2 s with
  | some '.', some '/', _       => true   -- ./foo
  | some '.', some '.', some '/'=> true   -- ../foo
  | some '/', some '/', _       => false  -- // is the update operator
  | some '/', some c, _         => !c.isWhitespace -- /nix/store/...
  | some '~', some '/', _       => true   -- ~/config
  | some '<', some c, _         => !c.isWhitespace && c != '=' -- <nixpkgs>
  | _, _, _                     => false
```

The `//` exclusion is essential. Without it, the attribute-set update operator would be parsed as the start of an absolute path.

`charAt? 2` is the only place in the lexer that looks more than one character ahead. It uses `listGet?`, a helper that traverses the `List Char` by index.

---

## The separation of parsing and validation

Parsing (`Parser.lean`) and semantic checking (`Validate.lean`) are separate passes. The parser builds an `Expr` tree; the validator traverses it and checks structural invariants.

The split makes sense because the invariants being checked — duplicate bindings, conflicting attribute paths — are not context-free. You cannot detect them with a recursive-descent parser because detecting them requires collecting all binding paths at a given level and comparing them to each other, which is a set operation, not a pattern match on adjacent tokens.

Keeping this logic out of the parser also keeps the parser simpler: it only needs to produce a structurally valid tree, not a semantically valid one.

---

## Attribute path conflict detection

Nix's attribute set semantics allows *nested* paths to be defined separately:

```nix
{ a.b = 1; a.c = 2; }   # fine — a.b and a.c are siblings
{ a.b = 1; a   = 2; }   # error — a conflicts with a.b
```

The validation rule is: two attribute paths conflict if one is a prefix of the other. The `isPrefix` function checks exactly this:

```lean
private def isPrefix : List String -> List String -> Bool
  | [], _          => true   -- empty path is a prefix of everything
  | _ :: _, []     => false  -- non-empty is not a prefix of empty
  | x :: xs, y :: ys => x == y && isPrefix xs ys
```

`pathsConflict` checks both directions (either could be a prefix of the other), and `firstPathConflict?` runs an O(n²) scan over all binding paths at each level. For the binding counts expected in real Nix code, this is fine.

The error message distinguishes the two cases: if the paths are identical, it says "duplicate binding"; if one is a proper prefix of the other, it says "conflicting binding paths."

---

## Why Rust for the e2e harness

The e2e runner could have been written in Lean. The reason it is Rust is stated explicitly in `docs/scaling-plan.md`: the harness has a different job. It finds files, runs subprocesses, manages caching, and prints summaries. It does not need to parse Nix or model the language. Mixing that orchestration code into the Lean project would complicate the model without improving it.

Rust is also a practical fit: it compiles to a small, dependency-free binary, has strong subprocess and filesystem support in the standard library, and the e2e runner's `Cargo.toml` deliberately has zero dependencies to keep the build trivial.

The separation also means the harness can evolve independently. If the manifest format changes, or if the runner gains a download/cache mode, those changes do not touch any Lean code.

---

## The manifest format

```
e2e/corpus/smoke/attrset.nix    pass              basic attrset with comments
e2e/corpus/smoke/lambda.nix     pass              attrset lambda parameter
e2e/corpus/smoke/duplicate.nix  validation-fail   duplicate attr binding
```

Three tab-separated fields: path, expectation, note. The format is intentionally minimal — no JSON, no TOML, no YAML. It is easy to edit by hand, easy to diff in git, and trivial to parse with `splitn(3, '\t')`.

The `note` field is the key to making expected failures useful. Without a note, a `validation-fail` entry is just a red flag you have to look up. With a note, the summary output tells you *why* it was expected to fail, which makes it safe to add known-missing features to the corpus without making every CI run look broken.

---

## `partial` on recursive functions

Many parser functions in Lean are marked `partial`:

```lean
private partial def skipLineComment (s : ParserState) : ParserState := ...
partial def parseExpr (s : ParserState) : ParserM (Expr × ParserState) := ...
```

Lean 4 requires all functions to be provably terminating by default. For simple structural recursion (like `isPrefix` over a `List`), the termination checker can verify this automatically. For parser functions that recurse on a `ParserState` (where "termination" means "the input keeps shrinking"), the checker cannot currently verify this automatically.

`partial` tells Lean to accept the function without a termination proof. The tradeoff is that Lean can no longer reason about these functions for proof purposes. For a parser whose goal is eventually to be used in proofs, this is a debt to repay — ideally by reformulating the parser with a fuel argument or a sized type, or by proving a measure that decreases on each call. For now, `partial` keeps the code readable while the model takes shape.
