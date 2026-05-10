let
  attrs = {
    "foo-bar".nested = 41;
    plain = { "child-name" = 1; };
  };
in
  attrs."foo-bar".nested + (if attrs.plain ? "child-name" then 1 else 0)
