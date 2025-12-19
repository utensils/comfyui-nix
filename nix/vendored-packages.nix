{
  pkgs,
  python,
  versions,
}:
{
  comfyuiFrontendPackage = python.pkgs.buildPythonPackage {
    pname = "comfyui-frontend-package";
    version = versions.vendored.frontendPackage.version;
    format = "wheel";
    src = pkgs.fetchurl {
      url = versions.vendored.frontendPackage.url;
      hash = versions.vendored.frontendPackage.hash;
    };
    doCheck = false;
  };

  comfyuiWorkflowTemplates = python.pkgs.buildPythonPackage {
    pname = "comfyui-workflow-templates";
    version = versions.vendored.workflowTemplates.version;
    format = "wheel";
    src = pkgs.fetchurl {
      url = versions.vendored.workflowTemplates.url;
      hash = versions.vendored.workflowTemplates.hash;
    };
    doCheck = false;
  };

  comfyuiEmbeddedDocs = python.pkgs.buildPythonPackage {
    pname = "comfyui-embedded-docs";
    version = versions.vendored.embeddedDocs.version;
    format = "wheel";
    src = pkgs.fetchurl {
      url = versions.vendored.embeddedDocs.url;
      hash = versions.vendored.embeddedDocs.hash;
    };
    doCheck = false;
  };
}
