let
  x = y + 1;
  y = 41;
  attrs = rec {
    base = x;
    answer = base;
  };
in
  attrs.answer
