let
  mk = args@{ name, base ? 40, extra ? 2, ... }:
    {
      label = name;
      score = base + extra;
      seen = args.name;
    };
in
  (mk { name = "demo"; ignored = true; }).score
