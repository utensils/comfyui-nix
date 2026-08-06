{
  nixpkgs,
  pkgs,
  source,
  packages,
  pythonRuntime,
  nixosModule,
}:
let
  emptyExtendedPackage = packages.default.withExtraPythonPackages (_: [ ]);
  duplicateCorePackage = packages.default.withExtraPythonPackages (ps: [ ps.numpy ]);
  extendedPackage = packages.default.withExtraPythonPackages (ps: [
    ps.bcrypt
    ps.pyjwt
    ps.bleach
  ]);
  chainedPackage =
    (packages.default.withExtraPythonPackages (ps: [ ps.bcrypt ])).withExtraPythonPackages
      (ps: [
        ps.pyjwt
        ps.bleach
      ]);
  backendPackages = [
    packages.default
  ]
  ++ pkgs.lib.optional (packages ? cuda) packages.cuda
  ++ pkgs.lib.optional (packages ? rocm) packages.rocm
  ++ pkgs.lib.optional (packages ? xpu) packages.xpu;
  backendPackagesPreserved = pkgs.lib.all (
    package:
    let
      extended = package.withExtraPythonPackages (ps: [ ps.bcrypt ]);
    in
    package.pythonRuntime.pkgs.torch.outPath == extended.pythonRuntime.pkgs.torch.outPath
    && package.pythonRuntime.pkgs.numpy.outPath == extended.pythonRuntime.pkgs.numpy.outPath
  ) backendPackages;
  evalModule =
    serviceConfig:
    nixpkgs.lib.nixosSystem {
      system = pkgs.stdenv.hostPlatform.system;
      modules = [
        nixosModule
        {
          system.stateVersion = "26.05";
          services.comfyui = {
            enable = true;
          }
          // serviceConfig;
        }
      ];
    };
  defaultModuleSystem = evalModule { };
  moduleSystem = evalModule {
    extraPythonPackages = ps: [
      ps.bcrypt
      ps.pyjwt
      ps.bleach
    ];
  };
  unsupportedPackageSystem = evalModule {
    package = packages.default.overrideAttrs (_: {
      pname = "custom-comfy-ui";
    });
    extraPythonPackages = ps: [ ps.bcrypt ];
  };
  unsupportedPackageRejected = pkgs.lib.any (
    assertion:
    !assertion.assertion && pkgs.lib.hasInfix "cannot be combined with a custom" assertion.message
  ) unsupportedPackageSystem.config.assertions;
  backendModuleSpecs = [
    {
      gpuSupport = "none";
      package = packages.default;
    }
  ]
  ++ pkgs.lib.optional (packages ? cuda) {
    gpuSupport = "cuda";
    package = packages.cuda;
  }
  ++ pkgs.lib.optional (packages ? rocm) {
    gpuSupport = "rocm";
    package = packages.rocm;
  }
  ++ pkgs.lib.optional (packages ? xpu) {
    gpuSupport = "xpu";
    package = packages.xpu;
  };
  backendModulesPreserved = pkgs.lib.all (
    spec:
    let
      system = evalModule {
        inherit (spec) gpuSupport;
        extraPythonPackages = ps: [ ps.bcrypt ];
      };
      expected = spec.package.withExtraPythonPackages (ps: [ ps.bcrypt ]);
      execStart = system.config.systemd.services.comfyui.serviceConfig.ExecStart;
    in
    pkgs.lib.hasPrefix expected.outPath execStart
  ) backendModuleSpecs;
  defaultModuleExecStart =
    defaultModuleSystem.config.systemd.services.comfyui.serviceConfig.ExecStart;
  moduleExecStart = moduleSystem.config.systemd.services.comfyui.serviceConfig.ExecStart;
  mkExtraPythonPackagesCheck =
    {
      name,
      package,
      expectedCudaVersion ? null,
    }:
    let
      extended = package.withExtraPythonPackages (ps: [
        ps.bcrypt
        ps.pyjwt
        ps.bleach
      ]);
      expectedCudaSuffix =
        if expectedCudaVersion == null then
          null
        else
          "cu${pkgs.lib.replaceStrings [ "." ] [ "" ] expectedCudaVersion}";
    in
    assert package.pythonRuntime.pkgs.torch.outPath == extended.pythonRuntime.pkgs.torch.outPath;
    assert package.pythonRuntime.pkgs.numpy.outPath == extended.pythonRuntime.pkgs.numpy.outPath;
    pkgs.runCommand name
      {
        nativeBuildInputs = [ extended.pythonRuntime ];
      }
      ''
        ${extended.pythonRuntime}/bin/python - <<'PY'
        import aiohttp
        import bcrypt
        import bleach
        import jwt
        import numpy
        import torch

        assert aiohttp.__version__
        assert bcrypt.__version__
        assert bleach.__version__
        assert jwt.__version__
        assert numpy.__version__
        assert torch.__version__
        ${pkgs.lib.optionalString (expectedCudaVersion != null) ''
          assert torch.__version__.endswith("+${expectedCudaSuffix}")
          assert torch.version.cuda == "${expectedCudaVersion}"
        ''}
        PY
        touch $out
      '';
in
{
  package = packages.default;
}
// pkgs.lib.optionalAttrs (pkgs.stdenv.isDarwin || (pkgs.stdenv.isLinux && pkgs.stdenv.isx86_64)) {
  comfy-extras-imports =
    pkgs.runCommand "comfy-extras-imports"
      {
        nativeBuildInputs = [ pythonRuntime ];
      }
      ''
        test -f ${packages.default.customNodes.rgthree-comfy}/web/comfyui/label.js
        grep -q 'name: "rgthree.Label"' \
          ${packages.default.customNodes.rgthree-comfy}/web/comfyui/label.js

        PYTHONPATH=${packages.default.comfyuiSrc} ${pythonRuntime}/bin/python - <<'PY'
        import importlib.util
        import sys

        import kornia
        import kornia_rs
        import comfy_extras.nodes_post_processing
        import comfy_extras.nodes_latent
        import comfy_extras.nodes_canny
        import comfy_extras.nodes_morphology

        assert kornia.__version__
        assert kornia_rs.__file__

        ltxvideo_path = "${packages.default.customNodes.ltxvideo}"
        spec = importlib.util.spec_from_file_location(
            "comfyui_ltxvideo",
            f"{ltxvideo_path}/__init__.py",
            submodule_search_locations=[ltxvideo_path],
        )
        assert spec and spec.loader
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        spec.loader.exec_module(module)
        assert module.NODE_CLASS_MAPPINGS
        PY
        touch $out
      '';
}
# XPU build-only check (Linux x86_64 only).
# The project maintainer has no Intel GPU, so runtime testing relies on external
# contributors. This check at least verifies the wheel patching and closure build
# succeed, catching the most common regression class (missing runtime libs,
# broken overlay, upstream wheel metadata changes).
// pkgs.lib.optionalAttrs (packages ? xpu) {
  package-xpu = packages.xpu;
}
// pkgs.lib.optionalAttrs (packages ? cuda) {
  extra-python-packages-cuda = mkExtraPythonPackagesCheck {
    name = "extra-python-packages-cuda";
    package = packages.cuda;
    expectedCudaVersion = "13.0";
  };
}
// pkgs.lib.optionalAttrs (packages ? rocm) {
  extra-python-packages-rocm = mkExtraPythonPackagesCheck {
    name = "extra-python-packages-rocm";
    package = packages.rocm;
  };
}
// pkgs.lib.optionalAttrs (packages ? xpu) {
  extra-python-packages-xpu = mkExtraPythonPackagesCheck {
    name = "extra-python-packages-xpu";
    package = packages.xpu;
  };
}
// {

  extra-python-packages =
    assert emptyExtendedPackage.outPath == packages.default.outPath;
    assert emptyExtendedPackage.pythonRuntime.outPath == pythonRuntime.outPath;
    assert duplicateCorePackage.pythonRuntime.outPath == pythonRuntime.outPath;
    assert backendPackagesPreserved;
    assert pkgs.lib.hasPrefix packages.default.outPath defaultModuleExecStart;
    assert pkgs.lib.hasPrefix extendedPackage.outPath moduleExecStart;
    assert unsupportedPackageRejected;
    assert backendModulesPreserved;
    pkgs.runCommand "extra-python-packages"
      {
        nativeBuildInputs = [ chainedPackage.pythonRuntime ];
      }
      ''
        ${chainedPackage.pythonRuntime}/bin/python - <<'PY'
        import aiohttp
        import bcrypt
        import bleach
        import jwt
        import numpy
        import torch

        assert aiohttp.__version__
        assert bcrypt.__version__
        assert bleach.__version__
        assert jwt.__version__
        assert numpy.__version__
        assert torch.__version__
        PY
        touch $out
      '';

  extra-python-packages-runtime = mkExtraPythonPackagesCheck {
    name = "extra-python-packages-runtime";
    package = packages.default;
  };

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
