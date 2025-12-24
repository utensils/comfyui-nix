# Custom node utilities for ComfyUI
#
# This library provides helpers for building and managing custom nodes.
# Users can use these helpers or simply pass fetchFromGitHub derivations directly.
#
# Usage in NixOS config:
#   services.comfyui.customNodes = {
#     my-node = comfyui-nix.lib.mkCustomNode { ... };
#   };
#
# Or directly:
#   services.comfyui.customNodes = {
#     my-node = pkgs.fetchFromGitHub { ... };
#   };
{ lib, pkgs }:
let
  # Helper to create a custom node derivation
  # This is a thin wrapper that allows for future extensions
  # (e.g., dependency bundling, patching, validation)
  mkCustomNode =
    {
      name,
      src,
    # Future options (not yet implemented):
    # pythonDeps ? [],      # Additional Python packages
    # patches ? [],         # Patches to apply
    # postInstall ? "",     # Post-install script
    }:
    # For now, just return the source directly
    # In the future, this could wrap the source in a derivation
    # that handles dependencies, patches, etc.
    pkgs.runCommand "comfyui-node-${name}" { inherit src; } ''
      cp -r $src $out
    '';

  # Fetch a custom node from GitHub
  # Convenience wrapper around fetchFromGitHub with sensible defaults
  fetchFromGitHub =
    {
      owner,
      repo,
      rev,
      hash,
      # Optional: specify a subdirectory if the node isn't at repo root
      subdir ? null,
    }:
    let
      src = pkgs.fetchFromGitHub {
        inherit
          owner
          repo
          rev
          hash
          ;
      };
    in
    if subdir != null then "${src}/${subdir}" else src;

in
{
  inherit mkCustomNode fetchFromGitHub;

  # Placeholder for future curated nodes (Option 2)
  # When we add pre-packaged nodes, they'll be available here:
  #
  # nodes = {
  #   impact-pack = mkCustomNode { ... };
  #   controlnet-aux = mkCustomNode { ... };
  # };
}
