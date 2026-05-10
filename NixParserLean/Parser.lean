import NixParserLean.Syntax

namespace NixParserLean

structure ParserState where
  input : String
  pos : String.Pos := 0
  deriving Repr, Inhabited

abbrev ParserM := Except String

private def eof (s : ParserState) : Bool :=
  s.pos == s.input.endPos

private def curr? (s : ParserState) : Option Char :=
  if eof s then none else s.input.get? s.pos

private def bump (s : ParserState) : ParserState :=
  if eof s then s else { s with pos := s.input.next s.pos }

private def next? (s : ParserState) : Option Char :=
  curr? (bump s)

private def failAt (s : ParserState) (msg : String) : ParserM α :=
  throw s!"parse error at byte {s.pos.byteIdx}: {msg}"

private partial def takeWhileGo (p : Char -> Bool) (acc : List Char) (s : ParserState) :
    String × ParserState :=
  match curr? s with
  | some c =>
      if p c then takeWhileGo p (c :: acc) (bump s) else (String.mk acc.reverse, s)
  | none => (String.mk acc.reverse, s)

private def takeWhile (p : Char -> Bool) (s : ParserState) : String × ParserState :=
  takeWhileGo p [] s

private partial def skipLineComment (s : ParserState) : ParserState :=
  match curr? s with
  | none => s
  | some '\n' => bump s
  | some _ => skipLineComment (bump s)

private partial def skipBlockComment (s : ParserState) : ParserState :=
  match curr? s with
  | none => s
  | some '*' =>
      let s := bump s
      if curr? s == some '/' then bump s else skipBlockComment s
  | some _ => skipBlockComment (bump s)

private partial def skipSpace (s : ParserState) : ParserState :=
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

private def char (expected : Char) (s : ParserState) : ParserM ParserState := do
  let s := skipSpace s
  match curr? s with
  | some c =>
      if c == expected then pure (bump s)
      else failAt s s!"expected '{expected}', found '{c}'"
  | none => failAt s s!"expected '{expected}', found end of input"

private def isIdentStart (c : Char) : Bool :=
  c.isAlpha || c == '_'

private def isIdentRest (c : Char) : Bool :=
  c.isAlpha || c.isDigit || c == '_' || c == '-' || c == '\''

private def ident (s : ParserState) : ParserM (String × ParserState) := do
  let s := skipSpace s
  match curr? s with
  | some c =>
      if isIdentStart c then
        let (rest, s') := takeWhile isIdentRest (bump s)
        pure (String.singleton c ++ rest, s')
      else
        failAt s "expected identifier"
  | none => failAt s "expected identifier"

private def keyword (word : String) (s : ParserState) : ParserM ParserState := do
  let (name, s') ← ident s
  if name == word then pure s' else failAt s s!"expected keyword '{word}'"

private def integer (s : ParserState) : ParserM (Int × ParserState) := do
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

private partial def quotedStringGo (acc : List Char) (s : ParserState) :
    ParserM (String × ParserState) := do
  match curr? s with
  | none => failAt s "unterminated string"
  | some '"' => pure (String.mk acc.reverse, bump s)
  | some '\\' =>
      let s := bump s
      match curr? s with
      | some 'n' => quotedStringGo ('\n' :: acc) (bump s)
      | some 't' => quotedStringGo ('\t' :: acc) (bump s)
      | some '"' => quotedStringGo ('"' :: acc) (bump s)
      | some '\\' => quotedStringGo ('\\' :: acc) (bump s)
      | some c => quotedStringGo (c :: acc) (bump s)
      | none => failAt s "unterminated escape"
  | some c => quotedStringGo (c :: acc) (bump s)

private def quotedString (s : ParserState) : ParserM (String × ParserState) := do
  let s ← char '"' s
  quotedStringGo [] s

mutual
partial def parseExpr (s : ParserState) : ParserM (Expr × ParserState) := do
  let s := skipSpace s
  match ident s with
  | .ok ("let", _) =>
    parseLet s
  | _ => parseAtom s

partial def parseAtom (s : ParserState) : ParserM (Expr × ParserState) := do
  let s := skipSpace s
  match curr? s with
  | some '"' =>
      let (v, s') ← quotedString s
      pure (.str v, s')
  | some '[' => parseList s
  | some '{' => parseAttrset false s
  | some '-' =>
      let (v, s') ← integer s
      pure (.int v, s')
  | some c =>
      if c.isDigit then
        let (v, s') ← integer s
        pure (.int v, s')
      else
        let (name, s') ← ident s
        match name with
        | "true" => pure (.bool true, s')
        | "false" => pure (.bool false, s')
        | "null" => pure (.null, s')
        | "rec" =>
            let s'' := skipSpace s'
            if curr? s'' == some '{' then parseAttrset true s''
            else pure (.ident name, s')
        | _ => pure (.ident name, s')
  | none => failAt s "expected expression"

partial def parseList (s : ParserState) : ParserM (Expr × ParserState) := do
  let s ← char '[' s
  let rec loop (items : List Expr) (st : ParserState) := do
    let st := skipSpace st
    match curr? st with
    | some ']' => pure (.list items.reverse, bump st)
    | none => failAt st "unterminated list"
    | _ =>
        let (item, st') ← parseExpr st
        loop (item :: items) st'
  loop [] s

partial def parseAttrPath (s : ParserState) : ParserM (AttrPath × ParserState) := do
  let (first, s) ← ident s
  let rec loop (parts : List String) (st : ParserState) := do
    let st := skipSpace st
    if curr? st == some '.' then
      let (part, st') ← ident (bump st)
      loop (part :: parts) st'
    else
      pure ({ parts := parts.reverse }, st)
  loop [first] s

partial def parseBinding (s : ParserState) : ParserM (Binding × ParserState) := do
  let s := skipSpace s
  match ident s with
  | .ok ("inherit", _) =>
    let s ← keyword "inherit" s
    parseInheritNames [] s
  | _ =>
    let (path, s) ← parseAttrPath s
    let s ← char '=' s
    let (value, s) ← parseExpr s
    let s ← char ';' s
    pure (.assign path value, s)

partial def parseInheritNames (acc : List String) (s : ParserState) :
    ParserM (Binding × ParserState) := do
  let s := skipSpace s
  match curr? s with
  | some ';' => pure (.inherit acc.reverse, bump s)
  | none => failAt s "unterminated inherit binding"
  | _ =>
      let (name, s') ← ident s
      parseInheritNames (name :: acc) s'

partial def parseBindingsUntil (endChar : Char) (s : ParserState) : ParserM (List Binding × ParserState) := do
  let rec loop (bindings : List Binding) (st : ParserState) := do
    let st := skipSpace st
    match curr? st with
    | some c =>
        if c == endChar then
          pure (bindings.reverse, st)
        else
          let (binding, st') ← parseBinding st
          loop (binding :: bindings) st'
    | none => failAt st s!"expected '{endChar}'"
  loop [] s

partial def parseAttrset (recursive : Bool) (s : ParserState) : ParserM (Expr × ParserState) := do
  let s ← char '{' s
  let (bindings, s) ← parseBindingsUntil '}' s
  let s ← char '}' s
  pure (.attrset recursive bindings, s)

partial def parseLet (s : ParserState) : ParserM (Expr × ParserState) := do
  let s ← keyword "let" s
  let (bindings, s) ← parseLetBindings [] s
  let s ← keyword "in" s
  let (body, s) ← parseExpr s
  pure (.letIn bindings body, s)

partial def parseLetBindings (bindings : List Binding) (s : ParserState) :
    ParserM (List Binding × ParserState) := do
  let s := skipSpace s
  match ident s with
  | .ok ("in", _) => pure (bindings.reverse, s)
  | _ =>
      let (binding, s') ← parseBinding s
      parseLetBindings (binding :: bindings) s'
end

def parse (input : String) : Except String Expr := do
  let (expr, s) ← parseExpr { input := input }
  let s := skipSpace s
  if eof s then
    pure expr
  else
    failAt s "trailing input"

end NixParserLean
