let x = 1; in
rec {
  inherit x;
  y = x + 1;
}.y
