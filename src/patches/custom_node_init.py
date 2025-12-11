# Model Downloader Custom Node
import os

# This node doesn't add any actual nodes to the graph
NODE_CLASS_MAPPINGS = {}
NODE_DISPLAY_NAME_MAPPINGS = {}

# Import our model downloader patch

# Register the web extension
WEB_DIRECTORY = os.path.join(
    os.path.dirname(os.path.dirname(os.path.realpath(__file__))), "custom_nodes/model_downloader/js"
)

# Ensure the js directory exists
if not os.path.exists(WEB_DIRECTORY):
    os.makedirs(WEB_DIRECTORY, exist_ok=True)


# Register web directory only
def setup_js_api(app, *args, **kwargs):
    """
    Set up the JavaScript API for the model downloader.
    This function only ensures the web directory is registered.
    API endpoints are now registered directly in the model_downloader/__init__.py file.

    Args:
        app: The aiohttp application

    Returns:
        The modified app
    """
    print("[MODEL_DOWNLOADER] setup_js_api called - web directory registered")

    # Log that the patch has been applied
    print("[MODEL_DOWNLOADER] Model downloader web directory registered successfully")

    return app


# API endpoints are now registered directly in the model_downloader/__init__.py file
# This file exists only for backwards compatibility and to ensure
# the custom node JS files are correctly served

print(f"Model Downloader patch loaded successfully from {WEB_DIRECTORY}")
