# Host Effect Evaluator Shape

The host import lane now has a documented next shape.

The choice is not to put filesystem behavior into `CoreEval`, and not to jump
straight to an effect-typed core. The next implementation target is a
host-aware import substitution layer in `HostEval.lean`: keep reifying simple
imported values as today, but add an internal host value slot for imported
values that cannot be represented as core syntax, especially closures.

That keeps the pure evaluator useful for proof work while giving the host lane a
place to grow. The first follow-up slice is concrete: make one repo-local
imported-function application work through `--eval-imports`, keep the existing
diagnostic stable until that implementation lands, and avoid search paths,
network fetchers, or store realization.
