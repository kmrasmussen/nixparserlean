let
  pkgs.hello = ./hello;
  version = "1.0";
in
  "${pkgs.hello}/bin/hello-${version}"
