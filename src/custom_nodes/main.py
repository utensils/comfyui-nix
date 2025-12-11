"""
Main entry point for the custom nodes module.

This module initializes and loads all custom nodes in the src/custom_nodes directory,
ensuring they are properly registered with ComfyUI.
"""

# Import the model_downloader module
from . import model_downloader


def initialize_custom_nodes():
    """
    Initialize all custom nodes in the module.
    This ensures all nodes are properly registered with ComfyUI.
    """
    print("Initializing custom nodes from src/custom_nodes...")

    # Initialize the model downloader
    print(
        f"Model Downloader module initialized with web directory: {model_downloader.WEB_DIRECTORY}"
    )

    # Here we could add initialization for other custom nodes in the future

    print("Custom nodes initialization complete")


# Run initialization when imported
initialize_custom_nodes()
