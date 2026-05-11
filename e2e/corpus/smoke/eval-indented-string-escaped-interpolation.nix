let
  name = "world";
in
  ''
    literal ''${name}
    actual ${name}
  ''

