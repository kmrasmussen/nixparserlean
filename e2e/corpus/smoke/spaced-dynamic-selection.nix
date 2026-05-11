let
  selector = "system";
  matrix = {
    system = "x86_64-linux";
  };
in
  matrix
    .${selector}

