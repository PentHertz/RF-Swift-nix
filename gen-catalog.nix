# Transforms environments.nix into the flat catalog.json the RF Swift binary reads.
# Pure builtins only, so it works with `nix eval --json --file ./gen-catalog.nix`.
let
  environments = import ./environments.nix;
  # Keep synchronized with flake.nix so CLI/GUI metadata matches.
  commonPackages = [ "python3" "uv" "go" ];
  unique = values:
    builtins.foldl' (result: value:
      if builtins.elem value result then result else result ++ [ value ])
      [ ] values;
  names = builtins.attrNames environments;
  toEntry = name:
    let e = environments.${name}; in {
      inherit name;
      description = e.description or "";
      category = e.category or "";
      packages = unique (commonPackages ++ (e.packages or [ ]));
      prerequisites = e.prerequisites or [];
      missing = e.missing or [];
    };
in {
  version = "4.0.0";
  flake = "github:PentHertz/RF-Swift-nix";
  environments = builtins.map toEntry names;
}
