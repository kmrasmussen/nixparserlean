# Core With Decision

`with` stays in the core language for now.

The alternative was to lower `with scope; body` away during desugaring, but that
would require an explicit environment-passing representation or a second copy
of lookup semantics in the desugarer. Keeping `withExpr` in core is cleaner for
the current model because the evaluator already owns environments.

The documented invariant is lexical-first fallback:

- evaluate the `with` scope once;
- require it to be an attrset;
- append that attrset's names as fallback lookup entries for the body;
- keep existing lexical bindings, lambda parameters, and recursive bindings at
  higher lookup priority.

There is no behavior change in this slice. The follow-up is `TICKET-0080`,
which should turn that invariant into a checked theorem for a restricted pure
subset.
