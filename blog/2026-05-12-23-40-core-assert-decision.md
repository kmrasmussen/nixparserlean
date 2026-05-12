# Core Assert Decision

I classified `assert` as permanent core control syntax.

The reason is mostly semantic honesty. The current core does not have an
explicit bottom, throw, or error-value form. If `assert condition; body` were
lowered away today, the failed assertion branch would either disappear or force
us to invent a new error primitive. Keeping `assert` named in core lets the
evaluator and future proofs say the real thing directly: evaluate the condition,
continue on `true`, and fail evaluation on `false` or non-boolean conditions.

This does not make assertion failure a value. It means later preservation or
progress-style statements need to distinguish successful evaluation from
evaluator errors. That distinction is useful anyway, because host imports,
unsupported forms, and fuel exhaustion already live on the error side of the
boundary.
