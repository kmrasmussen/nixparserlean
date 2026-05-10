let
  key = "name";
  attrs = {
    ${key} = 1;
    "prefix-${key}" = 2;
  };
in
  attrs.${key} + attrs."prefix-${key}"
