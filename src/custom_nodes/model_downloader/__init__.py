# Model Downloader Custom Node
import importlib.util
import logging
import os
import sys
import time
import traceback

# Setup logging
logger = logging.getLogger("model_downloader")

# This node doesn't add any actual nodes to the graph
NODE_CLASS_MAPPINGS = {}
NODE_DISPLAY_NAME_MAPPINGS = {}

# Register the web extension directory for ComfyUI to find the JavaScript files
WEB_DIRECTORY = os.path.join(os.path.dirname(os.path.realpath(__file__)), "js")

# Make sure WEB_DIRECTORY exists
if not os.path.exists(WEB_DIRECTORY):
    os.makedirs(WEB_DIRECTORY, exist_ok=True)

# Add the current directory to the path to ensure we can import our modules
current_dir = os.path.dirname(os.path.realpath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

# Import the model_downloader_patch module
try:
    # Import directly from current directory by filename
    spec = importlib.util.spec_from_file_location(
        "model_downloader_patch", os.path.join(current_dir, "model_downloader_patch.py")
    )
    if spec is None or spec.loader is None:
        msg = "Failed to load model_downloader_patch module"
        raise ImportError(msg)
    model_downloader_patch = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(model_downloader_patch)

    # Get the handler functions
    download_model = model_downloader_patch.download_model
    get_download_progress = model_downloader_patch.get_download_progress
    list_downloads = model_downloader_patch.list_downloads

    logger.info("Successfully imported model downloader module")
except Exception:
    logger.exception("Error importing model_downloader_patch")

    # Define dummy functions to avoid errors
    from aiohttp import web

    async def download_model(request):
        return web.json_response({"success": False, "error": "Model downloader not available"})

    async def get_download_progress(request):
        return web.json_response({"success": False, "error": "Model downloader not available"})

    async def list_downloads(request):
        return web.json_response({"success": False, "error": "Model downloader not available"})


# Define API handler for ComfyUI extension system
def setup_js_api(app, *args, **kwargs):
    try:
        from aiohttp import web
    except ImportError:
        logger.exception("Error importing web from aiohttp")
        return app

    logger.info("Registering model downloader API endpoints")

    # Define route patterns to check for
    route_patterns = ["/api/download-model", "/api/download-progress/", "/api/downloads"]

    # Check if any of our routes already exist
    existing_routes = set()
    for route in app.router.routes():
        route_str = str(route)
        for pattern in route_patterns:
            if pattern in route_str:
                existing_routes.add(pattern)
                logger.info(f"Found existing route matching {pattern}")

    # Register each endpoint if it doesn't already exist
    if "/api/download-model" not in existing_routes:
        app.router.add_post("/api/download-model", download_model)
        logger.info("Registered /api/download-model endpoint")

    if "/api/download-progress/" not in existing_routes:
        app.router.add_get("/api/download-progress/{download_id}", get_download_progress)
        logger.info("Registered /api/download-progress endpoint")

    if "/api/downloads" not in existing_routes:
        app.router.add_get("/api/downloads", list_downloads)
        logger.info("Registered /api/downloads endpoint")

    logger.info("Model downloader API endpoints registered successfully")
    return app


# Try to register immediately if PromptServer is available
try:
    from aiohttp import web
    from server import PromptServer

    logger.info("Attempting immediate API endpoint registration")

    if (
        hasattr(PromptServer, "instance")
        and PromptServer.instance is not None
        and hasattr(PromptServer.instance, "app")
    ):
        app = PromptServer.instance.app
        setup_js_api(app)
    else:
        logger.warning(
            "PromptServer.instance not available yet, will register later via setup_js_api"
        )
except Exception:
    logger.exception("Error during immediate API registration")
    logger.debug("Will try again when ComfyUI calls setup_js_api function")

# Module initialization completed
