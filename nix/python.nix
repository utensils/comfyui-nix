# Base CPython interpreter shared by every package set in this flake.
#
# Linux follows upstream ComfyUI,
# which calls Python 3.13 "very well supported" and ships it in the official portable builds.
#
# Apple Silicon stays on 3.12.
# torch is pinned to 2.5.1 there because of MPS regressions on macOS 26,
# and that release has no cp313 macOS wheel.
# The first one is torch 2.6.0.
{ pkgs }:
if pkgs.stdenv.hostPlatform.isDarwin then pkgs.python312 else pkgs.python313
