let
  xs = [ 1 ] ++ [ 2 ];
  comparison = 1 < 2 && 2 <= 2 && 3 > 2 && 3 >= 3 && 1 != 2;
  negated = !false;
  negative = -(1 + 2);
in
  comparison -> negated
