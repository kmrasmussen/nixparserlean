let
  key = "score";

  defaults = rec {
    base = 40;
    bonus = 2;
    total = base + bonus;
  };

  mkPackage = args@{ name, base ? args.defaults.total, ... }:
    rec {
      label = name;
      score = base;
      doubled = score + score;
    };

  package = mkPackage {
    name = "demo";
    defaults = defaults;
  };

  table = {
    "${package.label}-${key}" = package.doubled;
  };
in
  with table;
  demo-score
