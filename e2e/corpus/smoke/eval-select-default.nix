let
  attrs = {
    a.b = 41;
  };
in
  attrs.a.b + attrs.missing or 1
