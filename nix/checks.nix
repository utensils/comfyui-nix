{
  pkgs,
  source,
  packages,
  pythonRuntime,
}:
{
  package = packages.default;

  ruff-check =
    pkgs.runCommand "ruff-check"
      {
        nativeBuildInputs = [ pkgs.ruff ];
        src = source;
      }
      ''
        cp -r $src source
        chmod -R u+w source
        cd source
        ${pkgs.ruff}/bin/ruff check --no-cache src/
        touch $out
      '';

  pyright-check =
    pkgs.runCommand "pyright-check"
      {
        nativeBuildInputs = [ pkgs.pyright ];
        src = source;
      }
      ''
        cp -r $src source
        chmod -R u+w source
        cd source
        ${pkgs.pyright}/bin/pyright \
          --pythonpath ${pythonRuntime}/bin/python \
          src/
        touch $out
      '';

  nixfmt =
    pkgs.runCommand "nixfmt-check"
      {
        nativeBuildInputs = [ pkgs.nixfmt-rfc-style ];
        src = source;
      }
      ''
        cp -r $src source
        chmod -R u+w source
        cd source
        nixfmt --check flake.nix nix
        touch $out
      '';
}
