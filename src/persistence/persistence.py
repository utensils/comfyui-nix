#!/usr/bin/env python3

"""
Persistence module for ComfyUI
This script ensures models and other user data persist across runs
"""

import logging
import os
import shutil
import sys
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("persistence")


# Helper functions
def ensure_dir(path):
    """Ensure a directory exists"""
    os.makedirs(path, exist_ok=True)


def create_symlink(source, target):
    """Create a symlink, removing target first if it exists"""
    target_path = Path(target)
    if target_path.exists() or target_path.is_symlink():
        if target_path.is_dir() and not target_path.is_symlink():
            shutil.rmtree(target_path)
        else:
            target_path.unlink()

    # Create parent dirs if needed
    target_path.parent.mkdir(parents=True, exist_ok=True)

    # Create the symlink
    os.symlink(source, target, target_is_directory=Path(source).is_dir())
    logger.info(f"Created symlink: {source} -> {target}")


# Define paths
def patch_model_downloader():
    """Minimal patch for model_downloader to ensure it works with our folder paths"""
    try:
        # Ensure the model_downloader_patch.py is properly loaded
        # This is important because the custom node will try to import it
        app_dir = os.environ.get("COMFY_APP_DIR")
        if app_dir:
            # Check if model_downloader_patch.py exists in the app directory
            patch_file = os.path.join(app_dir, "model_downloader_patch.py")
            if not os.path.exists(patch_file):
                # If it doesn't exist, try to find it in the custom_nodes directory
                custom_node_patch = os.path.join(
                    app_dir, "custom_nodes", "model_downloader", "model_downloader_patch.py"
                )
                if os.path.exists(custom_node_patch):
                    # Create a symlink or copy the file to the app directory
                    try:
                        os.symlink(custom_node_patch, patch_file)
                        logger.info(
                            f"Created symlink for model_downloader_patch.py: "
                            f"{custom_node_patch} -> {patch_file}"
                        )
                    except Exception:
                        # If symlink fails, try to copy the file
                        import shutil

                        shutil.copy2(custom_node_patch, patch_file)
                        logger.info(
                            f"Copied model_downloader_patch.py to app directory: "
                            f"{custom_node_patch} -> {patch_file}"
                        )

        # The model downloader will use folder_paths.get_folder_paths which is already patched
        # by our patch_folder_paths function
        logger.info("Model downloader will use patched folder paths")
    except Exception:
        logger.exception("Error preparing model downloader")


def patch_folder_paths(base_dir):
    """Patch the folder_paths module to use our persistent directories"""
    try:
        import folder_paths

        # Store the original get_folder_paths function
        original_get_folder_paths = folder_paths.get_folder_paths

        # Override folder paths with our persistent paths
        def patched_get_folder_paths(folder_name):
            # Get original paths
            original_paths = original_get_folder_paths(folder_name)

            # If we have a persistent directory for this folder, use it instead
            persistent_path = os.path.join(base_dir, "models", folder_name)
            if os.path.exists(persistent_path):
                logger.info(f"Using persistent path for {folder_name}: {persistent_path}")
                # Handle case where original_paths might not have a second element
                if len(original_paths) > 1:
                    return ([persistent_path], original_paths[1])
                return ([persistent_path], [])

            return original_paths

        # Also store the original get_folder_paths function with a different name
        # so nodes can access it directly if needed
        folder_paths.get_folder_paths_original = original_get_folder_paths

        # Add a helper function to get the first path from a folder
        # This helps nodes that expect a string path instead of a list
        def get_first_folder_path(folder_name):
            paths = folder_paths.get_folder_paths(folder_name)
            if paths and len(paths) > 0 and len(paths[0]) > 0:
                return paths[0][0]
            return None

        # Add this helper function to the folder_paths module
        folder_paths.get_first_folder_path = get_first_folder_path

        # Replace the function
        folder_paths.get_folder_paths = patched_get_folder_paths

        # Also set output and input directories to our persistent directories
        output_dir = os.path.join(base_dir, "output")
        if os.path.exists(output_dir):
            logger.info(f"Setting output directory to: {output_dir}")
            folder_paths.set_output_directory(output_dir)

        input_dir = os.path.join(base_dir, "input")
        if os.path.exists(input_dir):
            logger.info(f"Setting input directory to: {input_dir}")
            folder_paths.set_input_directory(input_dir)

        # Set the temp directory
        temp_dir = os.path.join(base_dir, "temp")
        if not os.path.exists(temp_dir):
            os.makedirs(temp_dir, exist_ok=True)
        folder_paths.set_temp_directory(temp_dir)

        # Set user directory
        user_dir = os.path.join(base_dir, "user")
        if os.path.exists(user_dir):
            logger.info(f"Setting user directory to: {user_dir}")
            folder_paths.set_user_directory(user_dir)

        # Override paths in the module
        folder_paths.output_directory = output_dir
        folder_paths.input_directory = input_dir
        folder_paths.temp_directory = temp_dir
        folder_paths.user_directory = user_dir

        logger.info("Path patching complete")
    except ImportError:
        logger.warning("Could not import folder_paths module, skipping patching")
    except Exception:
        logger.exception("Error patching folder_paths")


def setup_persistence():
    """
    Set up the persistence for ComfyUI.

    Creates symlinks between the app directory and persistent storage.
    """
    # Create the persistent directory if it doesn't exist
    base_dir = os.environ.get(
        "COMFY_USER_DIR", os.path.join(os.path.expanduser("~"), ".config", "comfy-ui")
    )
    logger.info(f"Using persistent directory: {base_dir}")

    # Get ComfyUI path - this is the directory where ComfyUI is installed
    # The app directory is where the main.py file is located
    app_dir = os.environ.get("COMFY_APP_DIR", None)
    if not app_dir:
        # If not set in environment, try to find it relative to this file
        current_dir = os.path.dirname(os.path.realpath(__file__))
        # Check if we're in src/persistence or directly in the app dir
        if os.path.basename(current_dir) == "persistence":
            app_dir = os.path.dirname(current_dir)  # Go up one level
            if os.path.basename(app_dir) == "src":
                app_dir = os.path.join(os.path.dirname(app_dir), "app")  # Go up and into app
        else:
            app_dir = current_dir  # Assume we're already in the app dir

    # Verify the app directory exists
    if not os.path.exists(app_dir):
        logger.warning(f"App directory not found at {app_dir}, using current directory")
        app_dir = os.getcwd()

    logger.info(f"Using app directory: {app_dir}")

    # Set the app directory in the environment for other modules to use
    os.environ["COMFY_APP_DIR"] = app_dir

    # Define the essential directories to persist
    # Model directories - where downloaded models are stored
    model_dirs = [
        "checkpoints",  # Main model checkpoints (most important)
        "loras",  # LoRA models for fine-tuning
        "vae",  # Variational autoencoders
        "controlnet",  # ControlNet models
        "embeddings",  # Textual embeddings
        "upscale_models",  # Models for upscaling images
        "clip",  # CLIP text encoders
        "diffusers",  # Diffusers models
    ]

    # User data directories - where user-generated content is stored
    user_dirs = [
        "output",  # Generated images
        "input",  # User-provided input images
        "user",  # User configurations and workflows
        "temp",  # Temporary files
    ]

    # Create persistent directories
    os.makedirs(base_dir, exist_ok=True)
    os.makedirs(os.path.join(base_dir, "models"), exist_ok=True)

    # Create model subdirectories and symlink them
    for model_dir in model_dirs:
        persistent_path = os.path.join(base_dir, "models", model_dir)
        app_path = os.path.join(app_dir, "models", model_dir)

        # Create the persistent directory
        os.makedirs(persistent_path, exist_ok=True)

        # Create the symlink
        try:
            # Remove the existing directory or symlink if it exists
            if os.path.exists(app_path) or os.path.islink(app_path):
                if os.path.islink(app_path):
                    os.unlink(app_path)
                else:
                    # If it's a directory, we need to move its contents first
                    # to avoid losing any existing models
                    if os.path.isdir(app_path) and os.listdir(app_path):
                        # Copy any files that don't exist in the persistent directory
                        for item in os.listdir(app_path):
                            src = os.path.join(app_path, item)
                            dst = os.path.join(persistent_path, item)
                            if not os.path.exists(dst):
                                if os.path.isdir(src):
                                    shutil.copytree(src, dst)
                                else:
                                    shutil.copy2(src, dst)
                    # Now remove the directory
                    shutil.rmtree(app_path)

            # Create the symlink
            os.symlink(persistent_path, app_path)
            logger.info(f"Created symlink: {persistent_path} -> {app_path}")
        except Exception:
            logger.exception(f"Error creating symlink for {model_dir}")

    # Create user directories and symlink them
    for user_dir in user_dirs:
        persistent_path = os.path.join(base_dir, user_dir)
        app_path = os.path.join(app_dir, user_dir)

        # Create the persistent directory
        os.makedirs(persistent_path, exist_ok=True)

        # Create the symlink
        try:
            # Remove the existing directory or symlink if it exists
            if os.path.exists(app_path) or os.path.islink(app_path):
                if os.path.islink(app_path):
                    os.unlink(app_path)
                else:
                    # If it's a directory, we need to move its contents first
                    # to avoid losing any existing files
                    if os.path.isdir(app_path) and os.listdir(app_path):
                        # Copy any files that don't exist in the persistent directory
                        for item in os.listdir(app_path):
                            src = os.path.join(app_path, item)
                            dst = os.path.join(persistent_path, item)
                            if not os.path.exists(dst):
                                if os.path.isdir(src):
                                    shutil.copytree(src, dst)
                                else:
                                    shutil.copy2(src, dst)
                    # Now remove the directory
                    shutil.rmtree(app_path)

            # Create the symlink
            os.symlink(persistent_path, app_path)
            logger.info(f"Created symlink: {persistent_path} -> {app_path}")
        except Exception:
            logger.exception(f"Error creating symlink for {user_dir}")

    # Set up environment
    os.environ["COMFY_SAVE_PATH"] = os.path.join(base_dir, "user")

    # Set command line args if needed
    if "--base-directory" not in sys.argv:
        sys.argv.extend(["--base-directory", base_dir])

    # Also patch folder_paths module at runtime for extra compatibility
    patch_folder_paths(base_dir)

    # Patch the model downloader to ensure it works with our folder paths
    try:
        patch_model_downloader()
    except Exception:
        logger.exception("Error patching model downloader")

    logger.info(f"Persistence setup complete using {base_dir}")
    return base_dir


# Run setup_persistence when the module is imported
base_dir = setup_persistence()

# This allows direct execution
if __name__ == "__main__":
    print("Persistence setup complete")
