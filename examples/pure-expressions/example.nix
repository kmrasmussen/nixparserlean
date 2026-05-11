let
  values = {
    base = 6 * 7;
    ok = 3 < 4;
  };
in
  if values.ok then values.base else 0
