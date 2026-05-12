# Comment And Whitespace Scanner Totality

The parser has another low-level `partial` island removed.

`skipLineComment`, `skipBlockComment`, and `skipSpace` now keep their public
wrapper shape, but delegate to input-length fuel helpers. The fuel is sized
from the remaining parser input, and every recursive step consumes input before
the helper recurs.

This is intentionally mechanical. Comments are still discarded as whitespace,
block comments still do not become AST nodes, and unterminated block comments
preserve the previous scanner behavior. The important result is that line,
column, and offset tracking stayed stable while the scanner became transparent
to Lean's termination checker.

I checked the existing parse-fail fixtures before and after the change:

- `lambda-body-parse-error.nix`: offset 7, line 2, column 1.
- `missing-equals.nix`: offset 11, line 2, column 10.
- `unterminated-list.nix`: offset 4, line 2, column 1.

The default parser manifest and the pinned external manifest both still pass.
