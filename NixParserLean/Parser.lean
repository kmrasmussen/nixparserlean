import NixParserLean.Parser.Basic
import NixParserLean.Syntax

namespace NixParserLean

private def isExprStopKeyword (name : String) : Bool :=
  name == "in" || name == "then" || name == "else"

private def isAppArgumentStart (s : ParserState) : Bool :=
  let s := skipSpace s
  isPathStart s ||
    match curr? s with
    | some '"' | some '\'' | some '(' | some '[' | some '{' => true
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

private def spacedDynamicSelection? (s : ParserState) : Option ParserState :=
  let s := skipSpace s
  match curr? s, next? s, charAt? 2 s with
  | some '.', some '$', some '{' => some s
  | _, _, _ => none

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

partial def indentedStringGo (text : List Char) (parts : List StringPart) (s : ParserState) :
    ParserM (List StringPart × ParserState) := do
  match curr? s with
  | none => failAt s "unterminated indented string"
  | some '\'' =>
      if next? s == some '\'' then
        pure ((flushStringText text parts).reverse, bump (bump s))
      else
        indentedStringGo ('\'' :: text) parts (bump s)
  | some '$' =>
      if next? s == some '{' then
        let parts := flushStringText text parts
        let (expr, s) ← parseExpr (bump (bump s))
        let s ← char '}' s
        indentedStringGo [] (.interpolation expr :: parts) s
      else
        indentedStringGo ('$' :: text) parts (bump s)
  | some c => indentedStringGo (c :: text) parts (bump s)

partial def indentedString (s : ParserState) : ParserM (List StringPart × ParserState) := do
  let s ← token "''" s
  indentedStringGo [] [] s

partial def staticStringParts? : List StringPart -> Option String
  | [] => some ""
  | .text text :: parts => do
      let rest ← staticStringParts? parts
      some (text ++ rest)
  | .interpolation _ :: _ => none

partial def attrName (s : ParserState) : ParserM (AttrPathPart × ParserState) := do
  let s := skipSpace s
  match curr? s, next? s with
  | some '"', _ =>
      let (parts, s') ← quotedString s
      match staticStringParts? parts with
      | some name => pure (.static name, s')
      | none => pure (.dynamicString parts, s')
  | some '$', some '{' =>
      let (expr, s') ← parseExpr (bump (bump s))
      let s' ← char '}' s'
      pure (.dynamicString [.interpolation expr], s')
  | _, _ => do
      let (name, s') ← ident s
      pure (.static name, s')

partial def parseExpr (s : ParserState) : ParserM (Expr × ParserState) := do
  let s := skipSpace s
  match ident s with
  | .ok ("let", _) =>
    parseLet s
  | .ok ("if", _) =>
    parseIf s
  | .ok ("assert", _) =>
    parseAssert s
  | .ok ("with", _) =>
    parseWith s
  | _ =>
    match parseLambdaHeader? s with
    | some (param, s) =>
        let (body, s) ← parseExpr s
        pure (.lambda param body, s)
    | none => parseImplies s

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

partial def parseMul (s : ParserState) : ParserM (Expr × ParserState) := do
  let (left, s) ← parseUnary s
  let rec loop (expr : Expr) (st : ParserState) := do
    match token "*" st with
    | .ok st =>
        let (right, st) ← parseUnary st
        loop (.binary .multiply expr right) st
    | .error _ =>
        match operatorToken "/" st with
        | .ok st =>
            let (right, st) ← parseUnary st
            loop (.binary .divide expr right) st
        | .error _ => pure (expr, st)
  loop left s

partial def parseAdd (s : ParserState) : ParserM (Expr × ParserState) := do
  let (left, s) ← parseMul s
  let rec loop (expr : Expr) (st : ParserState) := do
    match operatorToken "+" st with
    | .ok st =>
        let (right, st) ← parseMul st
        loop (.binary .add expr right) st
    | .error _ =>
        match operatorToken "-" st with
        | .ok st =>
            let (right, st) ← parseMul st
            loop (.binary .subtract expr right) st
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
        let (number, s) ← numberLiteral s
        match number with
        | .int value => pure (.int value, s)
        | .float value => pure (.float value, s)
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
      let (argument, st') ← parseSelect st
      loop (.app expr argument) st'
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
    | _ =>
        match spacedDynamicSelection? st with
        | some dot =>
            let (path, st) ← parseAttrPath (bump dot)
            match ident st with
            | .ok ("or", st) =>
                let (defaultExpr, st) ← parseExpr st
                loop (.select expr path (some defaultExpr)) st
            | _ => loop (.select expr path none) st
        | none => pure (expr, st)
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
  | some '\'' =>
      if next? s == some '\'' then
        let (v, s') ← indentedString s
        pure (.str v, s')
      else
        failAt s "expected expression"
  | some '(' =>
      let s ← char '(' s
      let (expr, s) ← parseExpr s
      let s ← char ')' s
      pure (expr, s)
  | some '[' => parseList s
  | some '{' => parseAttrset false s
  | some c =>
      if c.isDigit then
        let (number, s') ← numberLiteral s
        match number with
        | .int value => pure (.int value, s')
        | .float value => pure (.float value, s')
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

partial def parseLambdaHeader? (s : ParserState) : Option (LambdaParam × ParserState) :=
  let s := skipSpace s
  let parsed? : Option (LambdaParam × ParserState) :=
    match curr? s with
    | some '{' =>
        match parseParamSet s with
        | .ok (paramSet, s) =>
            let s' := skipSpace s
            if curr? s' == some '@' then
              match ident (bump s') with
              | .ok (name, s) => some (LambdaParam.alias name (LambdaParam.attrset paramSet), s)
              | .error _ => none
            else
              some (LambdaParam.attrset paramSet, s)
        | .error _ => none
    | _ =>
        match ident s with
        | .ok (name, s) =>
            let s' := skipSpace s
            if curr? s' == some '@' then
              let s := bump s'
              match curr? (skipSpace s) with
              | some '{' =>
                  match parseParamSet s with
                  | .ok (paramSet, s) => some (LambdaParam.alias name (LambdaParam.attrset paramSet), s)
                  | .error _ => none
              | _ => none
            else
              some (LambdaParam.ident name, s)
        | .error _ => none
  match parsed? with
  | some (param, s) =>
      let s := skipSpace s
      if curr? s == some ':' then
        some (param, bump s)
      else
        none
  | none => none

partial def parseLambda (s : ParserState) : ParserM (Expr × ParserState) := do
  match parseLambdaHeader? s with
  | some (param, s) =>
      let (body, s) ← parseExpr s
      pure (.lambda param body, s)
  | none => failAt s "expected lambda expression"

partial def parseParamSet (s : ParserState) : ParserM (ParamSet × ParserState) := do
  let s ← char '{' s
  let rec loop (entries : List ParamEntry) (ellipsis : Bool) (st : ParserState) := do
    let st := skipSpace st
    match curr? st with
    | some '}' => pure ({ entries := entries.reverse, ellipsis }, bump st)
    | some '.' =>
        let st ← token "..." st
        let st ← char '}' st
        pure ({ entries := entries.reverse, ellipsis := true }, st)
    | none => failAt st "unterminated function parameter set"
    | _ =>
        let (entry, st) ← parseParamEntry st
        let st := skipSpace st
        match curr? st with
        | some ',' => loop (entry :: entries) ellipsis (bump st)
        | some '}' => pure ({ entries := (entry :: entries).reverse, ellipsis }, bump st)
        | some c =>
            failAt st
              ("expected ',' or '}' in function parameter set, found '" ++ String.singleton c ++ "'")
        | none => failAt st "unterminated function parameter set"
  loop [] false s

partial def parseParamEntry (s : ParserState) : ParserM (ParamEntry × ParserState) := do
  let (name, s) ← ident s
  let s' := skipSpace s
  if curr? s' == some '?' then
    let (defaultExpr, s) ← parseExpr (bump s')
    pure ({ name, default? := some defaultExpr }, s)
  else
    pure ({ name }, s)

partial def parseAttrPath (s : ParserState) : ParserM (AttrPath × ParserState) := do
  let (first, s) ← attrName s
  let rec loop (parts : List AttrPathPart) (st : ParserState) := do
    if curr? st == some '.' then
      let (part, st') ← attrName (bump st)
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
  | some '"' =>
      let (parts, s') ← quotedString s
      match staticStringParts? parts with
      | some name => parseInheritNameList (name :: acc) s'
      | none => failAt s "dynamic inherit names are unsupported"
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

partial def parseAssert (s : ParserState) : ParserM (Expr × ParserState) := do
  let s ← keyword "assert" s
  let (condition, s) ← parseExpr s
  let s ← char ';' s
  let (body, s) ← parseExpr s
  pure (.assertExpr condition body, s)

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

def parse (input : String) : ParserM Expr := do
  let (expr, s) ← parseExpr { remaining := input.toList }
  let s := skipSpace s
  if eof s then
    pure expr
  else
    failAt s "trailing input"

end NixParserLean
