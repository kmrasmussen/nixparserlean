let
  imported = import ./import-target.nix;
in imported.value + 41
