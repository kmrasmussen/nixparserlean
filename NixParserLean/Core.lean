import NixParserLean.Syntax

namespace NixParserLean
namespace Core

mutual
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

inductive Expr where
  | int : Int -> Expr
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
  | select : (base : Expr) -> (path : List AttrPathPart) -> (default? : Option Expr) -> Expr
  | hasAttr : (base : Expr) -> (path : List AttrPathPart) -> Expr
  | app : (function : Expr) -> (argument : Expr) -> Expr
  | unary : (op : UnaryOp) -> (expr : Expr) -> Expr
  | binary : (op : BinaryOp) -> (left : Expr) -> (right : Expr) -> Expr
  deriving Repr, BEq, Inhabited

inductive StringPart where
  | text : String -> StringPart
  | interpolation : Expr -> StringPart
  deriving Repr, BEq, Inhabited

inductive AttrPathPart where
  | static : String -> AttrPathPart
  | dynamicString : List StringPart -> AttrPathPart
  deriving Repr, BEq, Inhabited

inductive Binding where
  | staticAssign : (name : String) -> (value : Expr) -> Binding
  | inheritAssign : (name : String) -> Binding
  | dynamicAssign : (path : List AttrPathPart) -> (value : Expr) -> Binding
  deriving Repr, BEq, Inhabited
end

end Core
end NixParserLean
