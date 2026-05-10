let
  pkgs.hello = ./hello;
in
  ''
  echo ${pkgs.hello}
  ''
