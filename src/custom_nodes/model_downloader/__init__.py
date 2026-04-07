# Model Downloader Custom Node
"""Custom node for downloading models in ComfyUI."""

from __future__ import annotations

import importlib.util
import logging
import os
import sys
from collections.abc import Awaitable, Callable
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from aiohttp import web

# Setup logging
logger = logging.getLogger("model_downloader")

# This node doesn't add any actual nodes to the graph
NODE_CLASS_MAPPINGS: dict[str, type[Any]] = {}
NODE_DISPLAY_NAME_MAPPINGS: dict[str, str] = {}

# Register the web extension directory for ComfyUI to find the JavaScript files
WEB_DIRECTORY = os.path.join(os.path.dirname(os.path.realpath(__file__)), "js")

# Make sure WEB_DIRECTORY exists
if not os.path.exists(WEB_DIRECTORY):
    os.makedirs(WEB_DIRECTORY, exist_ok=True)

# Add the current directory to the path to ensure we can import our modules
current_dir = os.path.dirname(os.path.realpath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

# Type aliases for handler functions
DownloadHandler = Callable[["web.Request"], Awaitable["web.Response"]]

# Import the model_downloader_patch module and get handler functions
_download_model_handler: DownloadHandler | None = None
_get_download_progress_handler: DownloadHandler | None = None
_list_downloads_handler: DownloadHandler | None = None
_resolve_folder_handler: DownloadHandler | None = None

try:
    spec = importlib.util.spec_from_file_location(
        "model_downloader_patch", os.path.join(current_dir, "model_downloader_patch.py")
    )
    if spec is None or spec.loader is None:
        msg = "Failed to load model_downloader_patch module"
        raise ImportError(msg)

    model_downloader_patch = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(model_downloader_patch)

    # Get the handler functions
    _download_model_handler = model_downloader_patch.download_model
    _get_download_progress_handler = model_downloader_patch.get_download_progress
    _list_downloads_handler = model_downloader_patch.list_downloads
    _resolve_folder_handler = model_downloader_patch.resolve_folder

    logger.info("Successfully imported model downloader module")
except ImportError:
    logger.exception("Error importing model_downloader_patch")


async def download_model(request: Any) -> Any:
    """Download model handler - delegates to loaded module or returns error."""
    if _download_model_handler is not None:
        return await _download_model_handler(request)
    from aiohttp import web

    return web.json_response({"success": False, "error": "Model downloader not available"})


async def get_download_progress(request: Any) -> Any:
    """Get download progress handler - delegates to loaded module or returns error."""
    if _get_download_progress_handler is not None:
        return await _get_download_progress_handler(request)
    from aiohttp import web

    return web.json_response({"success": False, "error": "Model downloader not available"})


async def list_downloads(request: Any) -> Any:
    """List downloads handler - delegates to loaded module or returns error."""
    if _list_downloads_handler is not None:
        return await _list_downloads_handler(request)
    from aiohttp import web

    return web.json_response({"success": False, "error": "Model downloader not available"})


async def resolve_folder(request: Any) -> Any:
    """Resolve folder handler - delegates to loaded module or returns error."""
    if _resolve_folder_handler is not None:
        return await _resolve_folder_handler(request)
    from aiohttp import web

    return web.json_response({"success": False, "error": "Model downloader not available"})


def setup_js_api(app: Any, *args: Any, **kwargs: Any) -> Any:
    """
    Define API handler for ComfyUI extension system.

    Args:
        app: The aiohttp application instance.
        *args: Additional positional arguments (unused).
        **kwargs: Additional keyword arguments (unused).

    Returns:
        The modified app instance.
    """
    try:
        from aiohttp import web
    except ImportError:
        logger.exception("Error importing web from aiohttp")
        return app

    logger.info("Registering model downloader API endpoints")

    # Define route patterns to check for
    route_patterns = [
        "/model-downloader/download",
        "/model-downloader/progress/",
        "/model-downloader/downloads",
        "/model-downloader/resolve-folder/",
    ]

    # Check if any of our routes already exist
    existing_routes: set[str] = set()
    for route in app.router.routes():
        route_str = str(route)
        for pattern in route_patterns:
            if pattern in route_str:
                existing_routes.add(pattern)
                logger.info("Found existing route matching %s", pattern)

    # Register each endpoint if it doesn't already exist
    if "/model-downloader/download" not in existing_routes:
        app.router.add_post("/model-downloader/download", download_model)
        logger.info("Registered /model-downloader/download endpoint")

    if "/model-downloader/progress/" not in existing_routes:
        app.router.add_get("/model-downloader/progress/{download_id}", get_download_progress)
        logger.info("Registered /model-downloader/progress endpoint")

    if "/model-downloader/downloads" not in existing_routes:
        app.router.add_get("/model-downloader/downloads", list_downloads)
        logger.info("Registered /model-downloader/downloads endpoint")

    if "/model-downloader/resolve-folder/" not in existing_routes:
        app.router.add_get("/model-downloader/resolve-folder/{filename}", resolve_folder)
        logger.info("Registered /model-downloader/resolve-folder endpoint")

    logger.info("Model downloader API endpoints registered successfully")
    return app


# Register routes immediately if PromptServer is available.
# In ComfyUI v0.17+, setup_js_api may not be called for custom nodes,
# so we register routes at import time as the primary mechanism.
try:
    from server import PromptServer  # type: ignore[import-not-found]

    if (
        hasattr(PromptServer, "instance")
        and PromptServer.instance is not None
        and hasattr(PromptServer.instance, "app")
    ):
        setup_js_api(PromptServer.instance.app)
except (ImportError, AttributeError):
    logger.debug("PromptServer not available, will register via setup_js_api")
