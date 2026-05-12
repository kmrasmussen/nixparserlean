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

inductive NumberLiteral where
  | int : Int -> NumberLiteral
  | float : String -> NumberLiteral
  deriving Repr, BEq, Inhabited

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

def takeWhileGoFuel (fuel : Nat) (p : Char -> Bool) (acc : List Char) (s : ParserState) :
    String × ParserState :=
  match fuel, curr? s with
  | 0, _ => (String.ofList acc.reverse, s)
  | Nat.succ fuel, some c =>
      if p c then takeWhileGoFuel fuel p (c :: acc) (bump s) else (String.ofList acc.reverse, s)
  | Nat.succ _, none => (String.ofList acc.reverse, s)
termination_by fuel
decreasing_by simp_wf

def takeWhileGo (p : Char -> Bool) (acc : List Char) (s : ParserState) :
    String × ParserState :=
  takeWhileGoFuel s.remaining.length p acc s

def takeWhile (p : Char -> Bool) (s : ParserState) : String × ParserState :=
  takeWhileGo p [] s

def skipLineCommentFuel : Nat -> ParserState -> ParserState
  | 0, s => s
  | fuel + 1, s =>
      match curr? s with
      | none => s
      | some '\n' => bump s
      | some _ => skipLineCommentFuel fuel (bump s)
termination_by fuel _ => fuel
decreasing_by simp_wf

def skipLineComment (s : ParserState) : ParserState :=
  skipLineCommentFuel s.remaining.length s

def skipBlockCommentFuel : Nat -> ParserState -> ParserState
  | 0, s => s
  | fuel + 1, s =>
      match curr? s with
      | none => s
      | some '*' =>
          let s := bump s
          if curr? s == some '/' then bump s else skipBlockCommentFuel fuel s
      | some _ => skipBlockCommentFuel fuel (bump s)
termination_by fuel _ => fuel
decreasing_by
  simp_wf
  all_goals exact Nat.lt_succ_self fuel

def skipBlockComment (s : ParserState) : ParserState :=
  skipBlockCommentFuel s.remaining.length s

def skipSpaceFuel : Nat -> ParserState -> ParserState
  | 0, s => s
  | fuel + 1, s =>
      match curr? s with
      | some c =>
          if c.isWhitespace then
            skipSpaceFuel fuel (bump s)
          else if c == '#' then
            skipSpaceFuel fuel (skipLineComment (bump s))
          else if c == '/' && next? s == some '*' then
            skipSpaceFuel fuel (skipBlockComment (bump (bump s)))
          else
            s
      | none => s
termination_by fuel _ => fuel
decreasing_by
  simp_wf
  all_goals exact Nat.lt_succ_self fuel

def skipSpace (s : ParserState) : ParserState :=
  skipSpaceFuel s.remaining.length s

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

private def exponentPart? (s : ParserState) : ParserM (Option (String × ParserState)) := do
  match curr? s with
  | some c =>
      if c == 'e' || c == 'E' then
        let afterE := bump s
        let (signText, digitsStart) :=
          match curr? afterE with
          | some '+' => ("+", bump afterE)
          | some '-' => ("-", bump afterE)
          | _ => ("", afterE)
        let (digits, afterDigits) := takeWhile Char.isDigit digitsStart
        if digits.isEmpty then
          failAt s "expected float exponent"
        else
          pure (some (String.singleton c ++ signText ++ digits, afterDigits))
      else
        pure none
  | none => pure none

def numberLiteral (s : ParserState) : ParserM (NumberLiteral × ParserState) := do
  let s := skipSpace s
  let (signText, digitsStart) :=
    match curr? s with
    | some '-' => ("-", bump s)
    | _ => ("", s)
  let sign := if signText == "-" then -1 else 1
  let (digits, afterDigits) := takeWhile Char.isDigit digitsStart
  if digits.isEmpty then
    failAt digitsStart "expected number"
  else
    match curr? afterDigits, next? afterDigits with
    | some '.', some c =>
        if c.isDigit then
          let afterDot := bump afterDigits
          let (fraction, afterFraction) := takeWhile Char.isDigit afterDot
          let exp? ← exponentPart? afterFraction
          match exp? with
          | some (exponent, afterExponent) =>
              pure (.float (signText ++ digits ++ "." ++ fraction ++ exponent), afterExponent)
          | none =>
              pure (.float (signText ++ digits ++ "." ++ fraction), afterFraction)
        else
          match ← exponentPart? afterDigits with
          | some (exponent, afterExponent) =>
              pure (.float (signText ++ digits ++ exponent), afterExponent)
          | none => pure (.int (sign * digits.toInt!), afterDigits)
    | _, _ =>
        match ← exponentPart? afterDigits with
        | some (exponent, afterExponent) =>
            pure (.float (signText ++ digits ++ exponent), afterExponent)
        | none => pure (.int (sign * digits.toInt!), afterDigits)

def flushStringText (text : List Char) (parts : List StringPart) : List StringPart :=
  if text.isEmpty then
    parts
  else
    .text (String.ofList text.reverse) :: parts

def isPathTerminator (c : Char) : Bool :=
  c.isWhitespace || c == ')' || c == ']' || c == '}' || c == ';' || c == ','

def anglePathGoFuel (fuel : Nat) (acc : List Char) (s : ParserState) :
    ParserM (String × ParserState) := do
  match fuel, curr? s with
  | 0, _ => failAt s "unterminated angle path"
  | Nat.succ _, none => failAt s "unterminated angle path"
  | Nat.succ _, some '>' => pure ("<" ++ String.ofList acc.reverse ++ ">", bump s)
  | Nat.succ fuel, some c =>
      if c.isWhitespace then
        failAt s "unterminated angle path"
      else
        anglePathGoFuel fuel (c :: acc) (bump s)
termination_by fuel
decreasing_by simp_wf

def anglePathGo (acc : List Char) (s : ParserState) :
    ParserM (String × ParserState) := do
  anglePathGoFuel s.remaining.length acc s

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
