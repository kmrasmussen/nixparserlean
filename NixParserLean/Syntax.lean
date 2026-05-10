namespace NixParserLean

inductive BinaryOp where
  | equal
  | notEqual
  | less
  | greater
  | lessOrEqual
  | greaterOrEqual
  | and
  | or
  | implies
  | add
  | subtract
  | multiply
  | divide
  | concat
  | update
  deriving Repr, BEq, Inhabited

inductive UnaryOp where
  | not
  | negate
  deriving Repr, BEq, Inhabited

mutual
structure AttrPath where
  parts : List AttrPathPart
  deriving Repr, BEq, Inhabited

inductive AttrPathPart where
  | static : String -> AttrPathPart
  | dynamicString : List StringPart -> AttrPathPart
  deriving Repr, BEq, Inhabited

inductive LambdaParam where
  | ident : String -> LambdaParam
  | attrset : ParamSet -> LambdaParam
  | alias : String -> LambdaParam -> LambdaParam
  deriving Repr, BEq, Inhabited

structure ParamEntry where
  name : String
  default? : Option Expr := none
  deriving Repr, BEq, Inhabited

structure ParamSet where
  entries : List ParamEntry
  ellipsis : Bool := false
  deriving Repr, BEq, Inhabited

inductive StringPart where
  | text : String -> StringPart
  | interpolation : Expr -> StringPart
  deriving Repr, BEq, Inhabited

inductive Expr where
  | int : Int -> Expr
  | float : String -> Expr
  | str : List StringPart -> Expr
  | bool : Bool -> Expr
  | null : Expr
  | ident : String -> Expr
  | path : String -> Expr
  | list : List Expr -> Expr
  | attrset : (recursive : Bool) -> (bindings : List Binding) -> Expr
  | letIn : (bindings : List Binding) -> (body : Expr) -> Expr
  | lambda : (param : LambdaParam) -> (body : Expr) -> Expr
  | ifThenElse : (condition : Expr) -> (thenBranch : Expr) -> (elseBranch : Expr) -> Expr
  | assertExpr : (condition : Expr) -> (body : Expr) -> Expr
  | withExpr : (scope : Expr) -> (body : Expr) -> Expr
  | select : (base : Expr) -> (path : AttrPath) -> (default? : Option Expr) -> Expr
  | hasAttr : (base : Expr) -> (path : AttrPath) -> Expr
  | app : (function : Expr) -> (argument : Expr) -> Expr
  | unary : (op : UnaryOp) -> (expr : Expr) -> Expr
  | binary : (op : BinaryOp) -> (left : Expr) -> (right : Expr) -> Expr
  deriving Repr, BEq, Inhabited

inductive Binding where
  | assign : (path : AttrPath) -> (value : Expr) -> Binding
  | inherit : (names : List String) -> Binding
  | inheritFrom : (scope : Expr) -> (names : List String) -> Binding
  deriving Repr, BEq, Inhabited
end

def AttrPathPart.toString : AttrPathPart -> String
  | .static name => name
  | .dynamicString _ => "<dynamic>"

def AttrPath.toString (path : AttrPath) : String :=
  ".".intercalate (path.parts.map AttrPathPart.toString)

def Binding.path? : Binding -> Option AttrPath
  | .assign path _ => some path
  | .inherit _ => none
  | .inheritFrom _ _ => none

def Expr.isAtomic : Expr -> Bool
  | .int _ | .float _ | .str _ | .bool _ | .null | .ident _ | .path _ => true
  | _ => false

end NixParserLean
