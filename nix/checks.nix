{
  pkgs,
  source,
  packages,
  pythonRuntime,
}:
{
  package = packages.default;
}
# XPU build-only check (Linux x86_64 only).
# The project maintainer has no Intel GPU, so runtime testing relies on external
# contributors. This check at least verifies the wheel patching and closure build
# succeed, catching the most common regression class (missing runtime libs,
# broken overlay, upstream wheel metadata changes).
// pkgs.lib.optionalAttrs (packages ? xpu) {
  package-xpu = packages.xpu;
}
// {

  pytest =
    let
      pytestPython = pkgs.python3.withPackages (ps: [ ps.pytest ]);
    in
    pkgs.runCommand "pytest"
      {
        nativeBuildInputs = [ pytestPython ];
        src = source;
      }
      ''
        cp -r $src source
        chmod -R u+w source
        cd source
        PYTHONPATH=src/custom_nodes/model_downloader \
          ${pytestPython}/bin/pytest \
          src/custom_nodes/model_downloader/test_model_downloader.py -v
        touch $out
      '';

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
        nativeBuildInputs = [
          pkgs.nixfmt-rfc-style
          pkgs.findutils
        ];
        src = source;
      }
      ''
        cp -r $src source
        chmod -R u+w source
        cd source
        # Find all .nix files explicitly to avoid deprecation warning
        find . -name '*.nix' -type f -exec nixfmt --check {} +
        touch $out
      '';

  shellcheck =
    pkgs.runCommand "shellcheck"
      {
        nativeBuildInputs = [
          pkgs.shellcheck
          pkgs.findutils
        ];
        src = source;
      }
      ''
        cp -r $src source
        chmod -R u+w source
        cd source
        # Check all shell scripts in scripts/
        find scripts -name '*.sh' -type f -exec shellcheck {} +
        touch $out
      '';
}
