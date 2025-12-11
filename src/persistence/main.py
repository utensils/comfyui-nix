#!/usr/bin/env python3
# Custom main.py to ensure path persistence in ComfyUI

import logging
import os
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("persistence")

# Import our persistence module
try:
    # First try to import using relative import if this is run as part of a package
    try:
        from .persistence import setup_persistence  # noqa: F401
    except ImportError:
        # If that fails, try to import using an absolute path based on file location
        script_dir = os.path.dirname(os.path.realpath(__file__))
        sys.path.insert(0, script_dir)
        import persistence  # noqa: F401

    # Get the persistent directory but don't run the setup again
    # The setup will be run when the module is imported
    PERSISTENT_DIR = os.environ.get(
        "COMFY_USER_DIR", os.path.join(os.path.expanduser("~"), ".config", "comfy-ui")
    )
except ImportError:
    logger.exception("Could not import persistent module, falling back to basic setup")
    # Define the persistent base directory - get from environment or use default
    PERSISTENT_DIR = os.environ.get(
        "COMFY_USER_DIR", os.path.join(os.path.expanduser("~"), ".config", "comfy-ui")
    )
    logger.info(f"Using persistent directory: {PERSISTENT_DIR}")

# Force the base directory in command line arguments
if "--base-directory" not in sys.argv:
    sys.argv.append("--base-directory")
    sys.argv.append(PERSISTENT_DIR)
else:
    # Find the index and replace its value
    index = sys.argv.index("--base-directory")
    if index + 1 < len(sys.argv):
        sys.argv[index + 1] = PERSISTENT_DIR

# Make sure the --persistent flag is set
if "--persistent" not in sys.argv:
    sys.argv.append("--persistent")

# Output current arguments for debugging
logger.info(f"Command line arguments: {sys.argv}")

# Set environment variables
os.environ["COMFY_USER_DIR"] = PERSISTENT_DIR
os.environ["COMFY_SAVE_PATH"] = os.path.join(PERSISTENT_DIR, "user")

# Import and run the original main
app_dir = os.path.dirname(os.path.realpath(__file__))
original_main = os.path.join(app_dir, "main.py")

logger.info(f"Executing original main.py: {original_main}")

# Make sure the app directory is in the Python path
app_dir = os.path.dirname(original_main)
sys.path.insert(0, app_dir)

# Set current directory to the app directory to ensure relative imports work
os.chdir(app_dir)

# Set environment variable for the app directory so persistence.py can find it
os.environ["COMFY_APP_DIR"] = app_dir

# Ensure utils is recognized as a package if it exists
utils_dir = os.path.join(app_dir, "utils")
utils_init = os.path.join(utils_dir, "__init__.py")
if os.path.exists(utils_dir) and os.path.isdir(utils_dir) and not os.path.exists(utils_init):
    # Make sure __init__.py exists
    with open(utils_init, "w") as f:
        f.write("# Auto-generated __init__.py for utils package")

# Instead of trying to execute the main.py file directly,
# we'll use a simpler approach by directly running main.py as a subprocess
# This avoids Python module import issues


# Build the command to run main.py with all the valid arguments
# Filter out the --persistent argument which is not recognized by main.py
filtered_args = [arg for arg in sys.argv[1:] if arg != "--persistent"]
cmd = [sys.executable, original_main, *filtered_args]

# Log the command we're about to run
logger.info(f"Running command: {' '.join(cmd)}")

# Execute the command and replace the current process
# Make sure to preserve all environment variables, especially LD_LIBRARY_PATH
os.execve(sys.executable, cmd, os.environ)
