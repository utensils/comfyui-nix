import asyncio
import json
import logging
import os
import time

import folder_paths
from aiohttp import ClientSession, ClientTimeout, web
from server import PromptServer

# Setup logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("model_downloader")

# HTTP status codes
HTTP_OK = 200

# Store active downloads with their progress information
active_downloads = {}


# Define the download model endpoint
async def download_model(request):
    """
    Handle POST requests to download models
    This function returns IMMEDIATELY after starting a background download
    """
    try:
        # Get request content type
        content_type = request.headers.get("Content-Type", "")

        # Initialize data dictionary
        data = {}

        # Handle different content types
        if "application/json" in content_type:
            # Parse JSON data
            data = await request.json()
        elif "application/x-www-form-urlencoded" in content_type:
            # Parse form data
            form_data = await request.post()
            data = dict(form_data)
        else:
            # Try to read the request body as text and parse parameters
            body = await request.text()
            logger.info(f"Request body: {body[:200]}...")  # Log first 200 chars of body

            # Try to extract parameters from the request body or query string
            if request.query:
                # Parse query parameters
                for key, value in request.query.items():
                    data[key] = value

            # If we still don't have data, try to parse as JSON as a fallback
            if not data and body:
                try:
                    data = json.loads(body)
                except json.JSONDecodeError:
                    # If all else fails, try to extract parameters from the URL-encoded body
                    try:
                        for param in body.split("&"):
                            if "=" in param:
                                key, value = param.split("=", 1)
                                data[key] = value
                    except Exception:
                        logger.exception("Error parsing request body")

        # Extra logging for debugging
        logger.info(f"Request headers: {request.headers}")
        logger.info(f"Parsed data: {data}")

        # Get parameters from the parsed data
        url = data.get("url")
        folder = data.get("folder")
        filename = data.get("filename")

        logger.info(f"Received download request for {filename} in folder {folder}")

        if not url or not folder or not filename:
            logger.error(
                f"Missing required parameters: url={url}, folder={folder}, filename={filename}"
            )
            return web.json_response({"success": False, "error": "Missing required parameters"})

        # Get the model folder path
        folder_path = folder_paths.get_folder_paths(folder)

        if not folder_path:
            logger.error(f"Invalid folder: {folder}")
            return web.json_response({"success": False, "error": f"Invalid folder: {folder}"})

        # Create the full path for the file
        full_path = os.path.join(folder_path[0], filename)

        logger.info(f"Will download model to {full_path}")

        # Generate a unique download ID
        download_id = f"{folder}_{filename}_{int(time.time())}"

        # Create a download entry
        active_downloads[download_id] = {
            "url": url,
            "folder": folder,
            "filename": filename,
            "path": full_path,
            "total_size": 0,
            "downloaded": 0,
            "percent": 0,
            "status": "downloading",
            "error": None,
            "start_time": time.time(),
            "download_id": download_id,
        }

        # Create a separate async task for the download
        # This allows us to return to the client immediately
        async def start_download():
            try:
                # Start the actual download
                await download_file(download_id, url, full_path)

            except Exception as e:
                logger.exception("Error in start_download")
                if download_id in active_downloads:
                    active_downloads[download_id]["status"] = "error"
                    active_downloads[download_id]["error"] = str(e)
                    await send_download_update(download_id)

        # Start the download as a separate task
        # We don't await this!
        PromptServer.instance.loop.create_task(start_download())

        # Immediately return a response to the client
        logger.info(f"Download {download_id} queued, returning immediately to client")
        return web.json_response(
            {
                "success": True,
                "download_id": download_id,
                "status": "queued",
                "message": "Download has been queued and will start automatically",
            }
        )

    except Exception as e:
        logger.exception("Error starting model download")
        return web.json_response({"success": False, "error": str(e)})


async def download_file(download_id, url, full_path):
    """
    Background task to download a file and update progress.
    Uses aiohttp for non-blocking downloads that won't starve the event loop.
    """
    try:
        logger.info(f"Starting download task for {download_id} from {url} to {full_path}")

        # First verify the destination directory exists and is writable
        try:
            target_directory = os.path.dirname(full_path)
            if not os.path.exists(target_directory):
                os.makedirs(target_directory, exist_ok=True)
                logger.info(f"Created directory: {target_directory}")

            # Check if the file already exists - if so, add timestamp to avoid conflicts
            if os.path.exists(full_path):
                logger.warning(
                    f"File already exists at {full_path}. Adding timestamp to avoid conflicts."
                )
                filename_parts = os.path.splitext(os.path.basename(full_path))
                timestamped_filename = f"{filename_parts[0]}_{int(time.time())}{filename_parts[1]}"
                full_path = os.path.join(target_directory, timestamped_filename)

                # Update the download entry with the new path
                if download_id in active_downloads:
                    active_downloads[download_id]["path"] = full_path
                    active_downloads[download_id]["filename"] = timestamped_filename
                    logger.info(f"Updated download path to: {full_path}")
        except Exception as e:
            logger.exception("Error preparing download directory")
            if download_id in active_downloads:
                active_downloads[download_id]["status"] = "error"
                active_downloads[download_id]["error"] = (
                    f"Failed to create download directory: {e!s}"
                )
                await send_download_update(download_id)
            return

        # Create ClientTimeout with reasonable values
        timeout = ClientTimeout(total=None, connect=30, sock_connect=30, sock_read=30)

        # Use aiohttp for fully non-blocking IO
        async with ClientSession(timeout=timeout) as session:
            # First do a HEAD request to get the content length and verify URL
            try:
                async with session.head(url, allow_redirects=True) as head_response:
                    if head_response.status == HTTP_OK:
                        content_length = head_response.headers.get("content-length")
                        if content_length:
                            total_size = int(content_length)
                            content_type = head_response.headers.get("content-type", "")

                            size_mb = total_size / (1024 * 1024)
                            logger.info(
                                f"File size from HEAD: {total_size} bytes ({size_mb:.2f} MB)"
                            )

                            # Update the download entry with the total size
                            if download_id in active_downloads:
                                active_downloads[download_id]["total_size"] = total_size
                                active_downloads[download_id]["content_type"] = content_type
                    else:
                        logger.warning(f"HEAD request returned status {head_response.status}")
            except Exception as e:
                logger.warning(f"HEAD request failed: {e}")

            # Start the actual download
            async with session.get(url, allow_redirects=True) as response:
                if response.status != HTTP_OK:
                    raise Exception(f"HTTP error {response.status}: {response.reason}")

                # Get file size if not already determined
                total_size = 0
                if download_id in active_downloads:
                    total_size = active_downloads[download_id].get("total_size", 0)

                if total_size == 0:
                    content_length = response.headers.get("content-length")
                    if content_length:
                        total_size = int(content_length)
                        # Update the download entry with the total size
                        if download_id in active_downloads:
                            active_downloads[download_id]["total_size"] = total_size
                            active_downloads[download_id]["content_type"] = response.headers.get(
                                "content-type", ""
                            )

                logger.info(f"Starting download of {total_size / (1024 * 1024):.2f} MB file")

                # Use a large chunk size (1MB) to reduce overhead
                downloaded = 0
                update_interval = 1.0  # Only send updates every 1 second
                last_update_time = 0
                percent_logged = -1  # Track last logged percentage
                # Extract filename from full_path
                extracted_filename = os.path.basename(full_path)
                logger.info(f"[{download_id}] Beginning data transfer for {extracted_filename}")

                # Track start time for speed calculations
                start_time = time.time()

                with open(full_path, "wb") as f:
                    async for chunk in response.content.iter_chunked(1024 * 1024):
                        if not chunk:
                            break

                        f.write(chunk)
                        downloaded += len(chunk)

                        # Update progress in memory
                        if download_id in active_downloads:
                            active_downloads[download_id]["downloaded"] = downloaded
                            current_percent = 0
                            if total_size > 0:
                                current_percent = int((downloaded / total_size) * 100)
                                active_downloads[download_id]["percent"] = current_percent

                            # Calculate download speed and ETA
                            current_time = time.time()
                            time_elapsed = current_time - start_time

                            # Calculate speed (downloaded bytes and time elapsed)
                            if downloaded > 0 and time_elapsed > 0:
                                # Calculate speed in MB/s
                                speed_mbps = downloaded / (1024 * 1024) / time_elapsed
                                active_downloads[download_id]["speed"] = round(speed_mbps, 2)

                                # Calculate ETA (total size and speed)
                                if total_size > 0 and speed_mbps > 0:
                                    bytes_remaining = total_size - downloaded
                                    seconds_remaining = bytes_remaining / (speed_mbps * 1024 * 1024)
                                    active_downloads[download_id]["eta"] = int(seconds_remaining)

                            # Log progress at 10% increments
                            if (
                                current_percent > 0
                                and current_percent % 10 == 0
                                and current_percent != percent_logged
                            ):
                                percent_logged = current_percent
                                speed = active_downloads[download_id].get("speed", 0)
                                eta = active_downloads[download_id].get("eta", 0)
                                eta_str = f", ETA: {eta // 60}m {eta % 60}s" if eta else ""
                                dl_mb = downloaded / (1024 * 1024)
                                total_mb = total_size / (1024 * 1024)
                                logger.info(
                                    f"[{download_id}] Download progress: {current_percent}% "
                                    f"({dl_mb:.2f} MB of {total_mb:.2f} MB, {speed} MB/s{eta_str})"
                                )

                            # Only send throttled updates
                            current_time = time.time()
                            if current_time - last_update_time >= update_interval:
                                last_update_time = current_time
                                await send_download_update(download_id)

        # Download completed successfully
        elapsed_time = (
            time.time() - active_downloads[download_id]["start_time"]
            if download_id in active_downloads
            else 0
        )
        download_speed = (
            (downloaded / elapsed_time) / (1024 * 1024) if elapsed_time > 0 else 0
        )  # MB/s

        dl_size_mb = downloaded / (1024 * 1024)
        logger.info(
            f"[{download_id}] Download completed: {dl_size_mb:.2f} MB "
            f"in {elapsed_time:.1f} seconds ({download_speed:.2f} MB/s)"
        )

        # Update status to completed
        if download_id in active_downloads:
            active_downloads[download_id]["status"] = "completed"
            active_downloads[download_id]["end_time"] = time.time()
            active_downloads[download_id]["downloaded"] = downloaded
            active_downloads[download_id]["percent"] = 100 if total_size > 0 else 0
            await send_download_update(download_id)

        logger.info(f"[{download_id}] Model downloaded successfully to {full_path}")

        # Keep the download info for 60 seconds so the frontend can see it completed
        await asyncio.sleep(60)
        active_downloads.pop(download_id, None)

    except Exception as e:
        logger.exception("Error downloading file")

        # Update status to error
        if download_id in active_downloads:
            active_downloads[download_id]["status"] = "error"
            active_downloads[download_id]["error"] = str(e)
            active_downloads[download_id]["end_time"] = time.time()

            # Send update
            await send_download_update(download_id)


async def send_download_update(download_id):
    """
    Send a WebSocket update to all clients about the status of a download
    """
    if download_id in active_downloads:
        download = active_downloads[download_id]

        # Log important status changes
        if download["status"] == "completed":
            logger.info(f"Download complete: {download.get('filename', '')}")
        elif download["status"] == "error":
            logger.info(f"Download error: {download.get('error', '')}")

        # Send WebSocket message with all info including speed and ETA
        try:
            # The send_sync method is synchronous despite its name, so don't use await
            PromptServer.instance.send_sync(
                "model_download_progress",
                {
                    "download_id": download_id,
                    "status": download["status"],
                    "percent": download.get("percent", 0),
                    "downloaded": download.get("downloaded", 0),
                    "total_size": download.get("total_size", 0),
                    "speed": download.get("speed", 0),
                    "eta": download.get("eta", 0),
                    "error": download.get("error"),
                },
            )
        except Exception:
            logger.exception("WebSocket error")


async def get_download_progress(request):
    """
    Get the progress of a download
    """
    try:
        download_id = request.match_info.get("download_id")

        if download_id in active_downloads:
            return web.json_response({"success": True, "download": active_downloads[download_id]})
        return web.json_response({"success": False, "error": "Download not found"})
    except Exception as e:
        return web.json_response({"success": False, "error": str(e)})


async def list_downloads(request):
    """
    List all active downloads
    """
    try:
        return web.json_response({"success": True, "downloads": active_downloads})
    except Exception as e:
        return web.json_response({"success": False, "error": str(e)})


# This function is kept for compatibility but endpoints are registered in __init__.py
def setup_js_api(app, *args, **kwargs):
    """
    This function remains for compatibility with ComfyUI extension system.
    API endpoints are now registered in the __init__.py file to avoid duplicates.

    Args:
        app: The aiohttp application

    Returns:
        The modified app
    """
    logger.info("Model downloader API endpoints are now registered in __init__.py")
    return app
