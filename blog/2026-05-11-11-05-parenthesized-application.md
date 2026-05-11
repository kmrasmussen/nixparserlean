# Parenthesized Application Arguments

The first new backlog ticket paid off quickly: parenthesized application
arguments were the next real parser pressure point from the pinned nixpkgs
corpus.

Two common shapes now parse:

```nix
lib.makeExtensible (lib.extends f rattrs)
removeAttrs (import ./. { inherit system; }) [ "_type" ]
```

The subtle part was not only adding `(` as an application argument start. The
parser also needed to preserve errors after it had committed to a construct.
Previously, speculative lambda parsing could accept a header and then hide a
body failure by backtracking. Application parsing had a similar issue: after
seeing a plausible argument start, it could swallow the argument parser's
error and leave a misleading error at the call site.

The new shape is stricter in the useful places:

- lambda parsing only backtracks before a header and colon are accepted;
- application parsing propagates argument errors after an argument start is
  recognized;
- unary markers such as `-` and `!` are not treated as application argument
  starts, because application arguments are parsed at the selection/atom
  layer and those tokens belong to the operator table unless parenthesized.

The external manifest moved from four expected parse failures to three passes
and one expected parse failure. The remaining blocker is now clearer:
`inherit (self.trivial) "or"` needs quoted names in inherit lists.
