import NixParserLean.CoreEval

namespace NixParserLean
namespace Core
namespace Eval

private def evalFuelExhausted : M α :=
  throw "eval error: evaluation fuel exhausted"

private def theoremUnsupported (feature : String) : M α :=
  throw s!"eval error: unsupported {feature}"

def primitiveLiteralValue? : Expr -> Option Value
  | .int value => some (.int value)
  | .float value => some (.float value)
  | .str [.text value] => some (.str value)
  | .bool value => some (.bool value)
  | .null => some .null
  | .path value => some (.path value)
  | _ => none

inductive PrimitiveLiteral : Expr -> Value -> Prop where
  | int (value : Int) : PrimitiveLiteral (.int value) (.int value)
  | float (value : String) : PrimitiveLiteral (.float value) (.float value)
  | str (value : String) : PrimitiveLiteral (.str [.text value]) (.str value)
  | bool (value : Bool) : PrimitiveLiteral (.bool value) (.bool value)
  | null : PrimitiveLiteral .null .null
  | path (value : String) : PrimitiveLiteral (.path value) (.path value)

theorem primitiveLiteralValue?_of_primitiveLiteral {expr : Expr} {value : Value}
    (h : PrimitiveLiteral expr value) :
    primitiveLiteralValue? expr = some value := by
  cases h <;> rfl

-- Total proof harness for the first evaluator-fuel theorem. It mirrors the
-- production entry-step policy for literals and binary expressions whose
-- operands are already primitive literals, avoiding the partial evaluator
-- environment until that larger recursion is proof-ready.
def evalLiteralBinarySubsetWithFuel : Nat -> Expr -> M Value
  | 0, _ => evalFuelExhausted
  | _ + 1, .int value => pure (.int value)
  | _ + 1, .float value => pure (.float value)
  | _ + 1, .str [.text value] => pure (.str value)
  | _ + 1, .bool value => pure (.bool value)
  | _ + 1, .null => pure .null
  | _ + 1, .path value => pure (.path value)
  | 1, .binary _ _ _ => evalFuelExhausted
  | _ + 2, .binary op left right =>
      match primitiveLiteralValue? left, primitiveLiteralValue? right with
      | some leftValue, some rightValue => evalBinary op leftValue rightValue
      | _, _ => theoremUnsupported "non-primitive fuel monotonicity theorem operand"
  | _ + 1, _ => theoremUnsupported "fuel monotonicity theorem expression"

theorem evalPrimitiveLiteralWithExtra {fuel extra : Nat} {expr : Expr} {value : Value}
    (hLiteral : PrimitiveLiteral expr value) :
    evalLiteralBinarySubsetWithFuel (fuel + extra + 1) expr = .ok value := by
  cases hLiteral <;> cases fuel <;> cases extra <;>
    simp [evalLiteralBinarySubsetWithFuel] <;> rfl

theorem evalPrimitiveBinaryWithFuel_monotone {fuel extra : Nat} {op : BinaryOp}
    {left right : Expr} {value : Value}
    (h : evalLiteralBinarySubsetWithFuel (fuel + 2) (.binary op left right) = .ok value) :
    evalLiteralBinarySubsetWithFuel (fuel + extra + 2) (.binary op left right) = .ok value := by
  cases fuel <;> cases extra <;> cases left <;> cases right <;>
    simp [evalLiteralBinarySubsetWithFuel, primitiveLiteralValue?] at h ⊢ <;>
    try exact h

inductive LiteralBinarySubset : Expr -> Value -> Nat -> Prop where
  | literal {expr : Expr} {value : Value} (hLiteral : PrimitiveLiteral expr value) :
      LiteralBinarySubset expr value 1
  | binary {op : BinaryOp} {left right : Expr} {leftValue rightValue value : Value}
      (hLeft : PrimitiveLiteral left leftValue)
      (hRight : PrimitiveLiteral right rightValue)
      (hEval : evalBinary op leftValue rightValue = .ok value) :
      LiteralBinarySubset (.binary op left right) value 2

theorem evalLiteralBinarySubsetWithFuel_monotone {fuel extra : Nat} {expr : Expr}
    {value : Value} {cost : Nat}
    (hSubset : LiteralBinarySubset expr value cost)
    (h : evalLiteralBinarySubsetWithFuel (fuel + cost) expr = .ok value) :
    evalLiteralBinarySubsetWithFuel (fuel + extra + cost) expr = .ok value := by
  cases hSubset with
  | literal hLiteral =>
      exact evalPrimitiveLiteralWithExtra (fuel := fuel) (extra := extra) hLiteral
  | binary hLeft hRight hEval =>
      exact evalPrimitiveBinaryWithFuel_monotone (fuel := fuel) (extra := extra) h

-- The next total proof harness widens the literal/binary subset with unary
-- expressions over primitive literal operands. It still avoids recursive
-- evaluation and environments.
def evalLiteralUnaryBinarySubsetWithFuel : Nat -> Expr -> M Value
  | 0, _ => evalFuelExhausted
  | _ + 1, .int value => pure (.int value)
  | _ + 1, .float value => pure (.float value)
  | _ + 1, .str [.text value] => pure (.str value)
  | _ + 1, .bool value => pure (.bool value)
  | _ + 1, .null => pure .null
  | _ + 1, .path value => pure (.path value)
  | 1, .unary _ _ => evalFuelExhausted
  | _ + 2, .unary op inner =>
      match primitiveLiteralValue? inner with
      | some innerValue => evalUnary op innerValue
      | none => theoremUnsupported "non-primitive unary fuel monotonicity theorem operand"
  | 1, .binary _ _ _ => evalFuelExhausted
  | _ + 2, .binary op left right =>
      match primitiveLiteralValue? left, primitiveLiteralValue? right with
      | some leftValue, some rightValue => evalBinary op leftValue rightValue
      | _, _ => theoremUnsupported "non-primitive fuel monotonicity theorem operand"
  | _ + 1, _ => theoremUnsupported "fuel monotonicity theorem expression"

theorem evalPrimitiveUnaryWithFuel_monotone {fuel extra : Nat} {op : UnaryOp}
    {inner : Expr} {value : Value}
    (h : evalLiteralUnaryBinarySubsetWithFuel (fuel + 2) (.unary op inner) = .ok value) :
    evalLiteralUnaryBinarySubsetWithFuel (fuel + extra + 2) (.unary op inner) = .ok value := by
  cases fuel <;> cases extra <;> cases inner <;>
    simp [evalLiteralUnaryBinarySubsetWithFuel, primitiveLiteralValue?] at h ⊢ <;>
    try exact h

theorem evalPrimitiveLiteralWithExtra_unaryBinary {fuel extra : Nat} {expr : Expr}
    {value : Value}
    (hLiteral : PrimitiveLiteral expr value) :
    evalLiteralUnaryBinarySubsetWithFuel (fuel + extra + 1) expr = .ok value := by
  cases hLiteral <;> cases fuel <;> cases extra <;>
    simp [evalLiteralUnaryBinarySubsetWithFuel] <;> rfl

theorem evalPrimitiveBinaryWithFuel_monotone_unaryBinary {fuel extra : Nat} {op : BinaryOp}
    {left right : Expr} {value : Value}
    (h : evalLiteralUnaryBinarySubsetWithFuel (fuel + 2) (.binary op left right) = .ok value) :
    evalLiteralUnaryBinarySubsetWithFuel (fuel + extra + 2) (.binary op left right) = .ok value := by
  cases fuel <;> cases extra <;> cases left <;> cases right <;>
    simp [evalLiteralUnaryBinarySubsetWithFuel, primitiveLiteralValue?] at h ⊢ <;>
    try exact h

inductive LiteralUnaryBinarySubset : Expr -> Value -> Nat -> Prop where
  | literal {expr : Expr} {value : Value} (hLiteral : PrimitiveLiteral expr value) :
      LiteralUnaryBinarySubset expr value 1
  | unary {op : UnaryOp} {inner : Expr} {innerValue value : Value}
      (hInner : PrimitiveLiteral inner innerValue)
      (hEval : evalUnary op innerValue = .ok value) :
      LiteralUnaryBinarySubset (.unary op inner) value 2
  | binary {op : BinaryOp} {left right : Expr} {leftValue rightValue value : Value}
      (hLeft : PrimitiveLiteral left leftValue)
      (hRight : PrimitiveLiteral right rightValue)
      (hEval : evalBinary op leftValue rightValue = .ok value) :
      LiteralUnaryBinarySubset (.binary op left right) value 2

theorem evalLiteralUnaryBinarySubsetWithFuel_monotone {fuel extra : Nat} {expr : Expr}
    {value : Value} {cost : Nat}
    (hSubset : LiteralUnaryBinarySubset expr value cost)
    (h : evalLiteralUnaryBinarySubsetWithFuel (fuel + cost) expr = .ok value) :
    evalLiteralUnaryBinarySubsetWithFuel (fuel + extra + cost) expr = .ok value := by
  cases hSubset with
  | literal hLiteral =>
      exact evalPrimitiveLiteralWithExtra_unaryBinary (fuel := fuel) (extra := extra) hLiteral
  | unary hInner hEval =>
      exact evalPrimitiveUnaryWithFuel_monotone (fuel := fuel) (extra := extra) h
  | binary hLeft hRight hEval =>
      exact evalPrimitiveBinaryWithFuel_monotone_unaryBinary (fuel := fuel) (extra := extra) h

def evalLiteralUnaryBinaryListItemsWithFuel (fuel : Nat) :
    List Expr -> M (List Value)
  | [] => pure []
  | item :: items => do
      let value ← evalLiteralUnaryBinarySubsetWithFuel fuel item
      let values ← evalLiteralUnaryBinaryListItemsWithFuel fuel items
      pure (value :: values)

inductive LiteralUnaryBinaryListItemsSubset : List Expr -> List Value -> Prop where
  | nil : LiteralUnaryBinaryListItemsSubset [] []
  | cons {expr : Expr} {value : Value} {cost : Nat} {exprs : List Expr}
      {values : List Value}
      (hItem : LiteralUnaryBinarySubset expr value cost)
      (hItems : LiteralUnaryBinaryListItemsSubset exprs values) :
      LiteralUnaryBinaryListItemsSubset (expr :: exprs) (value :: values)

theorem evalLiteralUnaryBinarySubsetWithFuel_of_subset {extra : Nat} {expr : Expr}
    {value : Value} {cost : Nat}
    (hSubset : LiteralUnaryBinarySubset expr value cost) :
    evalLiteralUnaryBinarySubsetWithFuel (extra + cost) expr = .ok value := by
  cases hSubset with
  | literal hLiteral =>
      exact evalPrimitiveLiteralWithExtra_unaryBinary
        (fuel := extra) (extra := 0) hLiteral
  | unary hInner hEval =>
      cases extra <;> cases hInner <;>
        simp [evalLiteralUnaryBinarySubsetWithFuel, primitiveLiteralValue?, hEval]
  | binary hLeft hRight hEval =>
      cases extra <;> cases hLeft <;> cases hRight <;>
        simp [evalLiteralUnaryBinarySubsetWithFuel, primitiveLiteralValue?, hEval]

theorem evalLiteralUnaryBinaryListItemsWithFuel_of_subset {fuel : Nat}
    {items : List Expr} {values : List Value}
    (hSubset : LiteralUnaryBinaryListItemsSubset items values) :
    evalLiteralUnaryBinaryListItemsWithFuel (fuel + 2) items = .ok values := by
  induction hSubset generalizing fuel with
  | nil =>
      rfl
  | cons hItem hItems ih =>
      cases hItem with
      | literal hLiteral =>
          have hHead := evalLiteralUnaryBinarySubsetWithFuel_of_subset
            (extra := fuel + 1) (LiteralUnaryBinarySubset.literal hLiteral)
          simp [evalLiteralUnaryBinaryListItemsWithFuel, hHead, ih]
          rfl
      | unary hInner hEval =>
          have hHead := evalLiteralUnaryBinarySubsetWithFuel_of_subset
            (extra := fuel) (LiteralUnaryBinarySubset.unary hInner hEval)
          simp [evalLiteralUnaryBinaryListItemsWithFuel, hHead, ih]
          rfl
      | binary hLeft hRight hEval =>
          have hHead := evalLiteralUnaryBinarySubsetWithFuel_of_subset
            (extra := fuel) (LiteralUnaryBinarySubset.binary hLeft hRight hEval)
          simp [evalLiteralUnaryBinaryListItemsWithFuel, hHead, ih]
          rfl

theorem evalLiteralUnaryBinaryListItemsWithFuel_monotone {fuel extra : Nat}
    {items : List Expr} {values : List Value}
    (hSubset : LiteralUnaryBinaryListItemsSubset items values)
    (_h : evalLiteralUnaryBinaryListItemsWithFuel (fuel + 2) items = .ok values) :
    evalLiteralUnaryBinaryListItemsWithFuel (fuel + extra + 2) items = .ok values := by
  exact evalLiteralUnaryBinaryListItemsWithFuel_of_subset
    (fuel := fuel + extra) hSubset

def evalNonrecursiveStaticAttrBindingsWithFuel (fuel : Nat) :
    List Binding -> M (List (String × Value))
  | [] => pure []
  | .staticAssign name expr :: bindings => do
      let value ← evalLiteralUnaryBinarySubsetWithFuel fuel expr
      let attrs ← evalNonrecursiveStaticAttrBindingsWithFuel fuel bindings
      pure ((name, value) :: attrs)
  | .inheritAssign _ :: _ =>
      theoremUnsupported "inherited static attrset fuel monotonicity theorem binding"
  | .dynamicAssign _ _ :: _ =>
      theoremUnsupported "dynamic static attrset fuel monotonicity theorem binding"

def evalNonrecursiveStaticAttrsetWithFuel (fuel : Nat)
    (bindings : List Binding) : M Value := do
  pure (.attrset (← evalNonrecursiveStaticAttrBindingsWithFuel fuel bindings))

inductive NonrecursiveStaticAttrBindingsSubset :
    List Binding -> List (String × Value) -> Prop where
  | nil : NonrecursiveStaticAttrBindingsSubset [] []
  | static {name : String} {expr : Expr} {value : Value} {cost : Nat}
      {bindings : List Binding} {attrs : List (String × Value)}
      (hValue : LiteralUnaryBinarySubset expr value cost)
      (hBindings : NonrecursiveStaticAttrBindingsSubset bindings attrs) :
      NonrecursiveStaticAttrBindingsSubset
        (.staticAssign name expr :: bindings) ((name, value) :: attrs)

theorem evalNonrecursiveStaticAttrBindingsWithFuel_of_subset {fuel : Nat}
    {bindings : List Binding} {attrs : List (String × Value)}
    (hSubset : NonrecursiveStaticAttrBindingsSubset bindings attrs) :
    evalNonrecursiveStaticAttrBindingsWithFuel (fuel + 2) bindings = .ok attrs := by
  induction hSubset generalizing fuel with
  | nil =>
      rfl
  | static hValue hBindings ih =>
      cases hValue with
      | literal hLiteral =>
          have hHead := evalLiteralUnaryBinarySubsetWithFuel_of_subset
            (extra := fuel + 1) (LiteralUnaryBinarySubset.literal hLiteral)
          simp [evalNonrecursiveStaticAttrBindingsWithFuel, hHead, ih]
          rfl
      | unary hInner hEval =>
          have hHead := evalLiteralUnaryBinarySubsetWithFuel_of_subset
            (extra := fuel) (LiteralUnaryBinarySubset.unary hInner hEval)
          simp [evalNonrecursiveStaticAttrBindingsWithFuel, hHead, ih]
          rfl
      | binary hLeft hRight hEval =>
          have hHead := evalLiteralUnaryBinarySubsetWithFuel_of_subset
            (extra := fuel) (LiteralUnaryBinarySubset.binary hLeft hRight hEval)
          simp [evalNonrecursiveStaticAttrBindingsWithFuel, hHead, ih]
          rfl

theorem evalNonrecursiveStaticAttrBindingsWithFuel_monotone {fuel extra : Nat}
    {bindings : List Binding} {attrs : List (String × Value)}
    (hSubset : NonrecursiveStaticAttrBindingsSubset bindings attrs)
    (_h : evalNonrecursiveStaticAttrBindingsWithFuel (fuel + 2) bindings =
      .ok attrs) :
    evalNonrecursiveStaticAttrBindingsWithFuel (fuel + extra + 2) bindings =
      .ok attrs := by
  exact evalNonrecursiveStaticAttrBindingsWithFuel_of_subset
    (fuel := fuel + extra) hSubset

theorem evalNonrecursiveStaticAttrsetWithFuel_monotone {fuel extra : Nat}
    {bindings : List Binding} {attrs : List (String × Value)}
    (hSubset : NonrecursiveStaticAttrBindingsSubset bindings attrs)
    (_h : evalNonrecursiveStaticAttrsetWithFuel (fuel + 2) bindings =
      .ok (.attrset attrs)) :
    evalNonrecursiveStaticAttrsetWithFuel (fuel + extra + 2) bindings =
      .ok (.attrset attrs) := by
  simp [evalNonrecursiveStaticAttrsetWithFuel,
    evalNonrecursiveStaticAttrBindingsWithFuel_of_subset
      (fuel := fuel + extra) hSubset]
  rfl

private theorem okResult_deterministic {α : Type} {result : M α} {left right : α}
    (hLeft : result = .ok left) (hRight : result = .ok right) :
    left = right := by
  rw [hLeft] at hRight
  cases hRight
  rfl

theorem evalLiteralBinarySubsetWithFuel_deterministic {fuel : Nat} {expr : Expr}
    {left right : Value}
    (hLeft : evalLiteralBinarySubsetWithFuel fuel expr = .ok left)
    (hRight : evalLiteralBinarySubsetWithFuel fuel expr = .ok right) :
    left = right := by
  exact okResult_deterministic hLeft hRight

theorem evalLiteralUnaryBinarySubsetWithFuel_deterministic {fuel : Nat}
    {expr : Expr} {left right : Value}
    (hLeft : evalLiteralUnaryBinarySubsetWithFuel fuel expr = .ok left)
    (hRight : evalLiteralUnaryBinarySubsetWithFuel fuel expr = .ok right) :
    left = right := by
  exact okResult_deterministic hLeft hRight

theorem evalLiteralUnaryBinaryListItemsWithFuel_deterministic {fuel : Nat}
    {items : List Expr} {left right : List Value}
    (hLeft : evalLiteralUnaryBinaryListItemsWithFuel fuel items = .ok left)
    (hRight : evalLiteralUnaryBinaryListItemsWithFuel fuel items = .ok right) :
    left = right := by
  exact okResult_deterministic hLeft hRight

theorem evalNonrecursiveStaticAttrBindingsWithFuel_deterministic {fuel : Nat}
    {bindings : List Binding} {left right : List (String × Value)}
    (hLeft : evalNonrecursiveStaticAttrBindingsWithFuel fuel bindings = .ok left)
    (hRight : evalNonrecursiveStaticAttrBindingsWithFuel fuel bindings = .ok right) :
    left = right := by
  exact okResult_deterministic hLeft hRight

theorem evalNonrecursiveStaticAttrsetWithFuel_deterministic {fuel : Nat}
    {bindings : List Binding} {left right : Value}
    (hLeft : evalNonrecursiveStaticAttrsetWithFuel fuel bindings = .ok left)
    (hRight : evalNonrecursiveStaticAttrsetWithFuel fuel bindings = .ok right) :
    left = right := by
  exact okResult_deterministic hLeft hRight

end Eval
end Core
end NixParserLean
