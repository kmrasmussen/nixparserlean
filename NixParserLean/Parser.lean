import NixParserLean.Syntax

namespace NixParserLean

structure ParserState where
  remaining : List Char
  offset : Nat := 0
  deriving Repr, Inhabited

abbrev ParserM := Except String

private def eof (s : ParserState) : Bool :=
  s.remaining.isEmpty

private def curr? (s : ParserState) : Option Char :=
  s.remaining.head?

private def bump (s : ParserState) : ParserState :=
  match s.remaining with
  | [] => s
  | _ :: rest => { s with remaining := rest, offset := s.offset + 1 }

private def next? (s : ParserState) : Option Char :=
  curr? (bump s)

private def listGet? : List α -> Nat -> Option α
  | [], _ => none
  | x :: _, 0 => some x
  | _ :: xs, n + 1 => listGet? xs n

private def charAt? (n : Nat) (s : ParserState) : Option Char :=
  listGet? s.remaining n

private def failAt (s : ParserState) (msg : String) : ParserM α :=
  throw s!"parse error at offset {s.offset}: {msg}"

private partial def takeWhileGo (p : Char -> Bool) (acc : List Char) (s : ParserState) :
    String × ParserState :=
  match curr? s with
  | some c =>
      if p c then takeWhileGo p (c :: acc) (bump s) else (String.ofList acc.reverse, s)
  | none => (String.ofList acc.reverse, s)

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

private def token (expected : String) (s : ParserState) : ParserM ParserState := do
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

private def operatorToken (expected : String) (s : ParserState) : ParserM ParserState := do
  let s' ← token expected s
  if expected == "+" && curr? s' == some '+' then
    failAt s "expected '+'"
  else if expected == "<" && curr? s' == some '=' then
    failAt s "expected '<'"
  else if expected == ">" && curr? s' == some '=' then
    failAt s "expected '>'"
  else
    pure s'

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

private def isExprStopKeyword (name : String) : Bool :=
  name == "in" || name == "then" || name == "else"

private def isPathStart (s : ParserState) : Bool :=
  let s := skipSpace s
  match curr? s, next? s, charAt? 2 s with
  | some '.', some '/', _ => true
  | some '.', some '.', some '/' => true
  | some '/', some '/', _ => false
  | some '/', _, _ => true
  | some '~', some '/', _ => true
  | some '<', some c, _ => !c.isWhitespace && c != '='
  | _, _, _ => false

private def isAppArgumentStart (s : ParserState) : Bool :=
  let s := skipSpace s
  isPathStart s ||
    match curr? s with
    | some '"' | some '[' | some '{' | some '-' | some '!' => true
    | some c => c.isDigit || isIdentStart c
    | none => false

private def isAppStop (s : ParserState) : Bool :=
  let s := skipSpace s
  match curr? s with
  | none => true
  | some ']' | some '}' | some ';' | some ',' | some ':' => true
  | some '/' => next? s == some '/'
  | some c =>
      if isIdentStart c then
        match ident s with
        | .ok (name, _) => isExprStopKeyword name
        | .error _ => false
      else
        false

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

private def flushStringText (text : List Char) (parts : List StringPart) : List StringPart :=
  if text.isEmpty then
    parts
  else
    .text (String.ofList text.reverse) :: parts

private def isPathTerminator (c : Char) : Bool :=
  c.isWhitespace || c == ')' || c == ']' || c == '}' || c == ';' || c == ','

private partial def anglePathGo (acc : List Char) (s : ParserState) :
    ParserM (String × ParserState) := do
  match curr? s with
  | none => failAt s "unterminated angle path"
  | some '>' => pure ("<" ++ String.ofList acc.reverse ++ ">", bump s)
  | some c =>
      if c.isWhitespace then
        failAt s "unterminated angle path"
      else
        anglePathGo (c :: acc) (bump s)

private def anglePath (s : ParserState) : ParserM (String × ParserState) := do
  let s ← char '<' s
  anglePathGo [] s

private def pathLiteral (s : ParserState) : ParserM (String × ParserState) := do
  let s := skipSpace s
  if !isPathStart s then
    failAt s "expected path"
  else if curr? s == some '<' then
    anglePath s
  else
    let (path, s') := takeWhile (fun c => !isPathTerminator c) s
    pure (path, s')

mutual
partial def quotedStringGo (text : List Char) (parts : List StringPart) (s : ParserState) :
    ParserM (List StringPart × ParserState) := do
  match curr? s with
  | none => failAt s "unterminated string"
  | some '"' => pure ((flushStringText text parts).reverse, bump s)
  | some '$' =>
      if next? s == some '{' then
        let parts := flushStringText text parts
        let (expr, s) ← parseExpr (bump (bump s))
        let s ← char '}' s
        quotedStringGo [] (.interpolation expr :: parts) s
      else
        quotedStringGo ('$' :: text) parts (bump s)
  | some '\\' =>
      let s := bump s
      match curr? s with
      | some 'n' => quotedStringGo ('\n' :: text) parts (bump s)
      | some 't' => quotedStringGo ('\t' :: text) parts (bump s)
      | some '"' => quotedStringGo ('"' :: text) parts (bump s)
      | some '\\' => quotedStringGo ('\\' :: text) parts (bump s)
      | some c => quotedStringGo (c :: text) parts (bump s)
      | none => failAt s "unterminated escape"
  | some c => quotedStringGo (c :: text) parts (bump s)

partial def quotedString (s : ParserState) : ParserM (List StringPart × ParserState) := do
  let s ← char '"' s
  quotedStringGo [] [] s

partial def parseExpr (s : ParserState) : ParserM (Expr × ParserState) := do
  let s := skipSpace s
  match ident s with
  | .ok ("let", _) =>
    parseLet s
  | .ok ("if", _) =>
    parseIf s
  | .ok ("with", _) =>
    parseWith s
  | _ =>
    match parseLambda s with
    | .ok result => pure result
    | .error _ => parseImplies s

partial def parseImplies (s : ParserState) : ParserM (Expr × ParserState) := do
  let (left, s) ← parseOr s
  match token "->" s with
  | .ok s =>
      let (right, s) ← parseImplies s
      pure (.binary .implies left right, s)
  | .error _ => pure (left, s)

partial def parseOr (s : ParserState) : ParserM (Expr × ParserState) := do
  let (left, s) ← parseAnd s
  let rec loop (expr : Expr) (st : ParserState) := do
    match token "||" st with
    | .ok st =>
        let (right, st) ← parseAnd st
        loop (.binary .or expr right) st
    | .error _ => pure (expr, st)
  loop left s

partial def parseAnd (s : ParserState) : ParserM (Expr × ParserState) := do
  let (left, s) ← parseEquality s
  let rec loop (expr : Expr) (st : ParserState) := do
    match token "&&" st with
    | .ok st =>
        let (right, st) ← parseEquality st
        loop (.binary .and expr right) st
    | .error _ => pure (expr, st)
  loop left s

partial def parseEquality (s : ParserState) : ParserM (Expr × ParserState) := do
  let (left, s) ← parseHasAttr s
  let rec loop (expr : Expr) (st : ParserState) := do
    match token "==" st with
    | .ok st =>
        let (right, st) ← parseHasAttr st
        loop (.binary .equal expr right) st
    | .error _ =>
        match token "!=" st with
        | .ok st =>
            let (right, st) ← parseHasAttr st
            loop (.binary .notEqual expr right) st
        | .error _ => pure (expr, st)
  loop left s

partial def parseHasAttr (s : ParserState) : ParserM (Expr × ParserState) := do
  let (left, s) ← parseComparison s
  let rec loop (expr : Expr) (st : ParserState) := do
    match token "?" st with
    | .ok st =>
        let (path, st) ← parseAttrPath st
        loop (.hasAttr expr path) st
    | .error _ => pure (expr, st)
  loop left s

partial def parseComparison (s : ParserState) : ParserM (Expr × ParserState) := do
  let (left, s) ← parseUpdate s
  let rec loop (expr : Expr) (st : ParserState) := do
    match token "<=" st with
    | .ok st =>
        let (right, st) ← parseUpdate st
        loop (.binary .lessOrEqual expr right) st
    | .error _ =>
        match token ">=" st with
        | .ok st =>
            let (right, st) ← parseUpdate st
            loop (.binary .greaterOrEqual expr right) st
        | .error _ =>
            match operatorToken "<" st with
            | .ok st =>
                let (right, st) ← parseUpdate st
                loop (.binary .less expr right) st
            | .error _ =>
                match operatorToken ">" st with
                | .ok st =>
                    let (right, st) ← parseUpdate st
                    loop (.binary .greater expr right) st
                | .error _ => pure (expr, st)
  loop left s

partial def parseUpdate (s : ParserState) : ParserM (Expr × ParserState) := do
  let (left, s) ← parseConcat s
  let rec loop (expr : Expr) (st : ParserState) := do
    match token "//" st with
    | .ok st =>
        let (right, st) ← parseConcat st
        loop (.binary .update expr right) st
    | .error _ => pure (expr, st)
  loop left s

partial def parseConcat (s : ParserState) : ParserM (Expr × ParserState) := do
  let (left, s) ← parseAdd s
  let rec loop (expr : Expr) (st : ParserState) := do
    match token "++" st with
    | .ok st =>
        let (right, st) ← parseAdd st
        loop (.binary .concat expr right) st
    | .error _ => pure (expr, st)
  loop left s

partial def parseAdd (s : ParserState) : ParserM (Expr × ParserState) := do
  let (left, s) ← parseUnary s
  let rec loop (expr : Expr) (st : ParserState) := do
    match operatorToken "+" st with
    | .ok st =>
        let (right, st) ← parseUnary st
        loop (.binary .add expr right) st
    | .error _ => pure (expr, st)
  loop left s

partial def parseUnary (s : ParserState) : ParserM (Expr × ParserState) := do
  let s := skipSpace s
  match curr? s, next? s with
  | some '!', _ =>
      let (expr, s) ← parseUnary (bump s)
      pure (.unary .not expr, s)
  | some '-', some c =>
      if c.isDigit then
        let (v, s) ← integer s
        pure (.int v, s)
      else
        let (expr, s) ← parseUnary (bump s)
        pure (.unary .negate expr, s)
  | _, _ => parseApp s

partial def parseApp (s : ParserState) : ParserM (Expr × ParserState) := do
  let (function, s) ← parseSelect s
  let rec loop (expr : Expr) (st : ParserState) := do
    if isAppStop st || !isAppArgumentStart st then
      pure (expr, st)
    else
      match parseSelect st with
      | .ok (argument, st') => loop (.app expr argument) st'
      | .error _ => pure (expr, st)
  loop function s

partial def parseSelect (s : ParserState) : ParserM (Expr × ParserState) := do
  let (base, s) ← parseAtom s
  let rec loop (expr : Expr) (st : ParserState) := do
    match curr? st with
    | some '.' =>
        let (path, st) ← parseAttrPath (bump st)
        match ident st with
        | .ok ("or", st) =>
            let (defaultExpr, st) ← parseExpr st
            loop (.select expr path (some defaultExpr)) st
        | _ => loop (.select expr path none) st
    | _ => pure (expr, st)
  loop base s

partial def parseAtom (s : ParserState) : ParserM (Expr × ParserState) := do
  let s := skipSpace s
  if isPathStart s then
    let (path, s) ← pathLiteral s
    pure (.path path, s)
  else
  match curr? s with
  | some '"' =>
      let (v, s') ← quotedString s
      pure (.str v, s')
  | some '(' =>
      let s ← char '(' s
      let (expr, s) ← parseExpr s
      let s ← char ')' s
      pure (expr, s)
  | some '[' => parseList s
  | some '{' => parseAttrset false s
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

partial def parseLambda (s : ParserState) : ParserM (Expr × ParserState) := do
  let s := skipSpace s
  let (param, s) ←
    match curr? s with
    | some '{' =>
        let (paramSet, s) ← parseParamSet s
        pure (LambdaParam.attrset paramSet, s)
    | _ =>
        let (name, s) ← ident s
        pure (LambdaParam.ident name, s)
  let s ← char ':' s
  let (body, s) ← parseExpr s
  pure (.lambda param body, s)

partial def parseParamSet (s : ParserState) : ParserM (ParamSet × ParserState) := do
  let s ← char '{' s
  let rec loop (names : List String) (ellipsis : Bool) (st : ParserState) := do
    let st := skipSpace st
    match curr? st with
    | some '}' => pure ({ names := names.reverse, ellipsis }, bump st)
    | some '.' =>
        let st ← token "..." st
        let st ← char '}' st
        pure ({ names := names.reverse, ellipsis := true }, st)
    | none => failAt st "unterminated function parameter set"
    | _ =>
        let (name, st) ← ident st
        let st := skipSpace st
        match curr? st with
        | some ',' => loop (name :: names) ellipsis (bump st)
        | some '}' => pure ({ names := (name :: names).reverse, ellipsis }, bump st)
        | some c =>
            failAt st
              ("expected ',' or '}' in function parameter set, found '" ++ String.singleton c ++ "'")
        | none => failAt st "unterminated function parameter set"
  loop [] false s

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
    parseInherit s
  | _ =>
    let (path, s) ← parseAttrPath s
    let s ← char '=' s
    let (value, s) ← parseExpr s
    let s ← char ';' s
    pure (.assign path value, s)

partial def parseInherit (s : ParserState) : ParserM (Binding × ParserState) := do
  let s := skipSpace s
  match curr? s with
  | some '(' =>
      let s ← char '(' s
      let (scope, s) ← parseExpr s
      let s ← char ')' s
      let (names, s) ← parseInheritNameList [] s
      pure (.inheritFrom scope names, s)
  | _ =>
      let (names, s) ← parseInheritNameList [] s
      pure (.inherit names, s)

partial def parseInheritNames (acc : List String) (s : ParserState) :
    ParserM (Binding × ParserState) := do
  let (names, s) ← parseInheritNameList acc s
  pure (.inherit names, s)

partial def parseInheritNameList (acc : List String) (s : ParserState) :
    ParserM (List String × ParserState) := do
  let s := skipSpace s
  match curr? s with
  | some ';' => pure (acc.reverse, bump s)
  | none => failAt s "unterminated inherit binding"
  | _ =>
      let (name, s') ← ident s
      parseInheritNameList (name :: acc) s'

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

partial def parseIf (s : ParserState) : ParserM (Expr × ParserState) := do
  let s ← keyword "if" s
  let (condition, s) ← parseExpr s
  let s ← keyword "then" s
  let (thenBranch, s) ← parseExpr s
  let s ← keyword "else" s
  let (elseBranch, s) ← parseExpr s
  pure (.ifThenElse condition thenBranch elseBranch, s)

partial def parseWith (s : ParserState) : ParserM (Expr × ParserState) := do
  let s ← keyword "with" s
  let (scope, s) ← parseExpr s
  let s ← char ';' s
  let (body, s) ← parseExpr s
  pure (.withExpr scope body, s)

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
  let (expr, s) ← parseExpr { remaining := input.toList }
  let s := skipSpace s
  if eof s then
    pure expr
  else
    failAt s "trailing input"

end NixParserLean
