import NixParserLean.Syntax

namespace NixParserLean

structure ParserState where
  remaining : List Char
  offset : Nat := 0
  line : Nat := 1
  column : Nat := 1
  deriving Repr, Inhabited

structure ParseError where
  offset : Nat
  line : Nat
  column : Nat
  message : String
  deriving Repr, BEq, Inhabited

def ParseError.toString (err : ParseError) : String :=
  s!"parse error at offset {err.offset} (line {err.line}, column {err.column}): {err.message}"

instance : ToString ParseError where
  toString := ParseError.toString

abbrev ParserM := Except ParseError

def eof (s : ParserState) : Bool :=
  s.remaining.isEmpty

def curr? (s : ParserState) : Option Char :=
  s.remaining.head?

def bump (s : ParserState) : ParserState :=
  match s.remaining with
  | [] => s
  | c :: rest =>
      if c == '\n' then
        { s with remaining := rest, offset := s.offset + 1, line := s.line + 1, column := 1 }
      else
        { s with remaining := rest, offset := s.offset + 1, column := s.column + 1 }

def next? (s : ParserState) : Option Char :=
  curr? (bump s)

def listGet? : List α -> Nat -> Option α
  | [], _ => none
  | x :: _, 0 => some x
  | _ :: xs, n + 1 => listGet? xs n

def charAt? (n : Nat) (s : ParserState) : Option Char :=
  listGet? s.remaining n

def failAt (s : ParserState) (msg : String) : ParserM α :=
  throw { offset := s.offset, line := s.line, column := s.column, message := msg }

partial def takeWhileGo (p : Char -> Bool) (acc : List Char) (s : ParserState) :
    String × ParserState :=
  match curr? s with
  | some c =>
      if p c then takeWhileGo p (c :: acc) (bump s) else (String.ofList acc.reverse, s)
  | none => (String.ofList acc.reverse, s)

def takeWhile (p : Char -> Bool) (s : ParserState) : String × ParserState :=
  takeWhileGo p [] s

partial def skipLineComment (s : ParserState) : ParserState :=
  match curr? s with
  | none => s
  | some '\n' => bump s
  | some _ => skipLineComment (bump s)

partial def skipBlockComment (s : ParserState) : ParserState :=
  match curr? s with
  | none => s
  | some '*' =>
      let s := bump s
      if curr? s == some '/' then bump s else skipBlockComment s
  | some _ => skipBlockComment (bump s)

partial def skipSpace (s : ParserState) : ParserState :=
  match curr? s with
  | some c =>
      if c.isWhitespace then
        skipSpace (bump s)
      else if c == '#' then
        skipSpace (skipLineComment (bump s))
      else if c == '/' && next? s == some '*' then
        skipSpace (skipBlockComment (bump (bump s)))
      else
        s
  | none => s

def char (expected : Char) (s : ParserState) : ParserM ParserState := do
  let s := skipSpace s
  match curr? s with
  | some c =>
      if c == expected then pure (bump s)
      else failAt s s!"expected '{expected}', found '{c}'"
  | none => failAt s s!"expected '{expected}', found end of input"

def token (expected : String) (s : ParserState) : ParserM ParserState := do
  let s := skipSpace s
  let rec loop (chars : List Char) (st : ParserState) := do
    match chars with
    | [] => pure st
    | expectedChar :: rest =>
        match curr? st with
        | some c =>
            if c == expectedChar then loop rest (bump st)
            else failAt st s!"expected '{String.ofList chars}'"
        | none => failAt st s!"expected '{String.ofList chars}', found end of input"
  loop expected.toList s

def operatorToken (expected : String) (s : ParserState) : ParserM ParserState := do
  let s' ← token expected s
  if expected == "+" && curr? s' == some '+' then
    failAt s "expected '+'"
  else if expected == "-" && curr? s' == some '>' then
    failAt s "expected '-'"
  else if expected == "/" && curr? s' == some '/' then
    failAt s "expected '/'"
  else if expected == "<" && curr? s' == some '=' then
    failAt s "expected '<'"
  else if expected == ">" && curr? s' == some '=' then
    failAt s "expected '>'"
  else
    pure s'

def isIdentStart (c : Char) : Bool :=
  c.isAlpha || c == '_'

def isIdentRest (c : Char) : Bool :=
  c.isAlpha || c.isDigit || c == '_' || c == '-' || c == '\''

def ident (s : ParserState) : ParserM (String × ParserState) := do
  let s := skipSpace s
  match curr? s with
  | some c =>
      if isIdentStart c then
        let (rest, s') := takeWhile isIdentRest (bump s)
        pure (String.singleton c ++ rest, s')
      else
        failAt s "expected identifier"
  | none => failAt s "expected identifier"

def keyword (word : String) (s : ParserState) : ParserM ParserState := do
  let (name, s') ← ident s
  if name == word then pure s' else failAt s s!"expected keyword '{word}'"

def isPathStart (s : ParserState) : Bool :=
  let s := skipSpace s
  match curr? s, next? s, charAt? 2 s with
  | some '.', some '/', _ => true
  | some '.', some '.', some '/' => true
  | some '/', some '/', _ => false
  | some '/', some c, _ => !c.isWhitespace
  | some '~', some '/', _ => true
  | some '<', some c, _ => !c.isWhitespace && c != '='
  | _, _, _ => false

def integer (s : ParserState) : ParserM (Int × ParserState) := do
  let s := skipSpace s
  let sign :=
    match curr? s with
    | some '-' => -1
    | _ => 1
  let s := if sign == -1 then bump s else s
  let (digits, s') := takeWhile Char.isDigit s
  if digits.isEmpty then
    failAt s "expected integer"
  else
    pure (sign * digits.toInt!, s')

def flushStringText (text : List Char) (parts : List StringPart) : List StringPart :=
  if text.isEmpty then
    parts
  else
    .text (String.ofList text.reverse) :: parts

def isPathTerminator (c : Char) : Bool :=
  c.isWhitespace || c == ')' || c == ']' || c == '}' || c == ';' || c == ','

partial def anglePathGo (acc : List Char) (s : ParserState) :
    ParserM (String × ParserState) := do
  match curr? s with
  | none => failAt s "unterminated angle path"
  | some '>' => pure ("<" ++ String.ofList acc.reverse ++ ">", bump s)
  | some c =>
      if c.isWhitespace then
        failAt s "unterminated angle path"
      else
        anglePathGo (c :: acc) (bump s)

def anglePath (s : ParserState) : ParserM (String × ParserState) := do
  let s ← char '<' s
  anglePathGo [] s

def pathLiteral (s : ParserState) : ParserM (String × ParserState) := do
  let s := skipSpace s
  if !isPathStart s then
    failAt s "expected path"
  else if curr? s == some '<' then
    anglePath s
  else
    let (path, s') := takeWhile (fun c => !isPathTerminator c) s
    pure (path, s')

end NixParserLean
