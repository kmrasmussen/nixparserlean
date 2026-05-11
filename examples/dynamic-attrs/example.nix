let
  key = "answer";
  attrs = {
    ${key} = 42;
  };
in
  attrs.${key}
