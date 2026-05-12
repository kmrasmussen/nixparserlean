# String Scanner Totality

Quoted and indented string scanning now use total fuel-bounded helpers.

The scanner loops moved out of the parser `partial` mutual block by taking the
expression parser as an explicit parameter. That keeps interpolation behavior
unchanged while letting `quotedStringGoFuel` and `indentedStringGoFuel`
terminate on an input-length fuel argument.

The supported escape behavior did not change. Quoted strings still support the
existing `\n`, `\t`, `\"`, and `\\` escapes, and indented strings still
support interpolation plus the `''${` literal `${` escape. The public string
helpers still parse from the same token boundary and return the same
`StringPart` shape.

Verification covered the Lean build, the default parser manifest, and the
pinned external manifest. The default manifest still exercises quoted string
interpolation, indented string interpolation, and escaped indented
interpolation.
