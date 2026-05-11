let
  selector = "answer";
  values = {
    answer = 42;
  };
in
  values
    .${selector}

