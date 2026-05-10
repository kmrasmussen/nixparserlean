namespace NixParserLean

structure AttrPath where
  parts : List String
  deriving Repr, BEq, Inhabited

mutual
inductive Expr where
  | int : Int -> Expr
  | str : String -> Expr
  | bool : Bool -> Expr
  | null : Expr
  | ident : String -> Expr
  | list : List Expr -> Expr
  | attrset : (recursive : Bool) -> (bindings : List Binding) -> Expr
  | letIn : (bindings : List Binding) -> (body : Expr) -> Expr
  deriving Repr, BEq, Inhabited

inductive Binding where
  | assign : (path : AttrPath) -> (value : Expr) -> Binding
  | inherit : (names : List String) -> Binding
  deriving Repr, BEq, Inhabited
end

def AttrPath.toString (path : AttrPath) : String :=
  ".".intercalate path.parts

def Binding.path? : Binding -> Option AttrPath
  | .assign path _ => some path
  | .inherit _ => none

def Expr.isAtomic : Expr -> Bool
  | .int _ | .str _ | .bool _ | .null | .ident _ => true
  | _ => false

end NixParserLean
