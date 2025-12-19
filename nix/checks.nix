{
  pkgs,
  source,
  packages,
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
        ${pkgs.pyright}/bin/pyright src/
        touch $out
      '';

  shellcheck =
    pkgs.runCommand "shellcheck"
      {
        nativeBuildInputs = [ pkgs.shellcheck ];
        src = source;
      }
      ''
        cp -r $src source
        chmod -R u+w source
        cd source/scripts
        shellcheck -x launcher.sh config.sh install.sh
        shellcheck logger.sh runtime.sh persistence.sh template_inputs.sh
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
