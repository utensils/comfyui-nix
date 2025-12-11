#!/usr/bin/env python3
"""
Persistence package for ComfyUI
This package handles persistence of models, outputs, and other user data
"""

from .persistence import patch_folder_paths, setup_persistence

__all__ = ["patch_folder_paths", "setup_persistence"]
