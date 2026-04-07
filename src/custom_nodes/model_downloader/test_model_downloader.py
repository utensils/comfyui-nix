"""Tests for model_downloader_patch module.

These tests mock ComfyUI-specific imports (folder_paths, server) and aiohttp
to test the pure logic of the model downloader: path resolution, writability
checks, skip-if-exists, HF auth headers, and progress tracking.
"""

from __future__ import annotations

import asyncio
import json
import os
import sys
import types
from typing import Any
from unittest.mock import AsyncMock, MagicMock, patch

import pytest  # type: ignore[import-not-found]

# ---------------------------------------------------------------------------
# Mock ComfyUI and aiohttp modules that aren't available outside the runtime
# ---------------------------------------------------------------------------

_folder_paths_mock = types.ModuleType("folder_paths")
_folder_paths_mock.get_folder_paths = MagicMock(return_value=["/data/models/checkpoints"])  # type: ignore[attr-defined]

_server_mock = types.ModuleType("server")
_prompt_server_instance = MagicMock()
_prompt_server_instance.send_sync = MagicMock()
_prompt_server_instance.loop = asyncio.new_event_loop()
_prompt_server_class = MagicMock()
_prompt_server_class.instance = _prompt_server_instance
_server_mock.PromptServer = _prompt_server_class  # type: ignore[attr-defined]

# Mock aiohttp if not available (dev shell may not have it)
if "aiohttp" not in sys.modules:
    _aiohttp = types.ModuleType("aiohttp")
    _aiohttp.ClientSession = MagicMock()  # type: ignore[attr-defined]
    _aiohttp.ClientTimeout = MagicMock()  # type: ignore[attr-defined]
    _aiohttp_web = types.ModuleType("aiohttp.web")
    _aiohttp_web.Request = MagicMock()  # type: ignore[attr-defined]

    def _json_response(data, **kwargs):
        resp = MagicMock()
        resp.body = json.dumps(data).encode()
        return resp

    _aiohttp_web.json_response = _json_response  # type: ignore[attr-defined]
    _aiohttp_web.Response = MagicMock()  # type: ignore[attr-defined]
    _aiohttp.web = _aiohttp_web  # type: ignore[attr-defined]
    sys.modules["aiohttp"] = _aiohttp
    sys.modules["aiohttp.web"] = _aiohttp_web

sys.modules["folder_paths"] = _folder_paths_mock
sys.modules["server"] = _server_mock

# Now import the module under test
import model_downloader_patch as mdp  # noqa: E402

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(autouse=True)
def _clear_downloads():
    """Clear active downloads before each test."""
    mdp.active_downloads.clear()
    yield
    mdp.active_downloads.clear()


@pytest.fixture
def tmp_model_dir(tmp_path):
    """Create a temporary writable model directory."""
    d = tmp_path / "models" / "checkpoints"
    d.mkdir(parents=True)
    return d


@pytest.fixture
def tmp_readonly_dir(tmp_path):
    """Create a temporary read-only directory."""
    d = tmp_path / "readonly"
    d.mkdir(parents=True)
    d.chmod(0o555)
    yield d
    # Restore permissions for cleanup
    d.chmod(0o755)


# ---------------------------------------------------------------------------
# Tests: _find_writable_path
# ---------------------------------------------------------------------------


class TestFindWritablePath:
    def test_returns_first_writable_dir(self, tmp_model_dir):
        result = mdp._find_writable_path([str(tmp_model_dir)], "model.safetensors")
        assert result == os.path.join(str(tmp_model_dir), "model.safetensors")

    def test_skips_readonly_dir(self, tmp_model_dir, tmp_readonly_dir):
        result = mdp._find_writable_path(
            [str(tmp_readonly_dir), str(tmp_model_dir)], "model.safetensors"
        )
        assert result == os.path.join(str(tmp_model_dir), "model.safetensors")

    def test_returns_none_when_all_readonly(self, tmp_readonly_dir):
        result = mdp._find_writable_path([str(tmp_readonly_dir)], "model.safetensors")
        assert result is None

    def test_returns_none_for_empty_list(self):
        result = mdp._find_writable_path([], "model.safetensors")
        assert result is None

    def test_creates_missing_first_dir(self, tmp_path):
        new_dir = str(tmp_path / "new" / "dir")
        result = mdp._find_writable_path([new_dir], "model.safetensors")
        assert result == os.path.join(new_dir, "model.safetensors")
        assert os.path.isdir(new_dir)

    def test_skips_nonexistent_prefers_existing_writable(self, tmp_model_dir):
        result = mdp._find_writable_path(
            ["/nonexistent/path", str(tmp_model_dir)], "model.safetensors"
        )
        assert result == os.path.join(str(tmp_model_dir), "model.safetensors")


# ---------------------------------------------------------------------------
# Tests: _prepare_download_path
# ---------------------------------------------------------------------------


class TestPrepareDownloadPath:
    def test_returns_path_when_file_does_not_exist(self, tmp_model_dir):
        full_path = str(tmp_model_dir / "new_model.safetensors")
        result = asyncio.run(mdp._prepare_download_path("dl_1", full_path, remote_size=1000))
        assert result == full_path

    def test_skips_when_file_exists_with_matching_size(self, tmp_model_dir):
        # Create a file with known size
        model_file = tmp_model_dir / "existing.safetensors"
        data = b"x" * 5000
        model_file.write_bytes(data)

        download_id = "dl_skip"
        mdp.active_downloads[download_id] = {
            "status": "downloading",
            "total_size": 0,
            "downloaded": 0,
            "percent": 0,
        }

        with patch.object(mdp, "send_download_update", new_callable=AsyncMock):
            result = asyncio.run(
                mdp._prepare_download_path(download_id, str(model_file), remote_size=5000)
            )

        assert result is None
        assert mdp.active_downloads[download_id]["status"] == "skipped"
        assert mdp.active_downloads[download_id]["percent"] == 100
        assert mdp.active_downloads[download_id]["total_size"] == 5000

    def test_renames_when_file_exists_with_different_size(self, tmp_model_dir):
        model_file = tmp_model_dir / "existing.safetensors"
        model_file.write_bytes(b"x" * 3000)

        download_id = "dl_rename"
        mdp.active_downloads[download_id] = {
            "status": "downloading",
            "path": str(model_file),
            "filename": "existing.safetensors",
        }

        result = asyncio.run(
            mdp._prepare_download_path(download_id, str(model_file), remote_size=5000)
        )

        assert result is not None
        assert result != str(model_file)
        assert "existing_" in result
        assert result.endswith(".safetensors")

    def test_renames_when_remote_size_unknown(self, tmp_model_dir):
        model_file = tmp_model_dir / "existing.safetensors"
        model_file.write_bytes(b"x" * 3000)

        download_id = "dl_unknown"
        mdp.active_downloads[download_id] = {
            "status": "downloading",
            "path": str(model_file),
            "filename": "existing.safetensors",
        }

        result = asyncio.run(
            mdp._prepare_download_path(download_id, str(model_file), remote_size=0)
        )

        assert result is not None
        assert result != str(model_file)

    def test_creates_missing_directory(self, tmp_path):
        new_dir = tmp_path / "new_folder"
        full_path = str(new_dir / "model.safetensors")

        result = asyncio.run(mdp._prepare_download_path("dl_mkdir", full_path, remote_size=1000))

        assert result == full_path
        assert new_dir.is_dir()


# ---------------------------------------------------------------------------
# Tests: _get_hf_token
# ---------------------------------------------------------------------------


class TestGetHfToken:
    def test_returns_token_from_env(self):
        with patch.dict(os.environ, {"HF_TOKEN": "hf_test123"}, clear=False):
            assert mdp._get_hf_token() == "hf_test123"

    def test_prefers_hf_token_over_others(self):
        env = {"HF_TOKEN": "hf_first", "HUGGINGFACE_HUB_TOKEN": "hf_second"}
        with patch.dict(os.environ, env, clear=False):
            assert mdp._get_hf_token() == "hf_first"

    def test_returns_none_when_no_token(self, tmp_path):
        env_clear = dict.fromkeys(("HF_TOKEN", "HUGGINGFACE_HUB_TOKEN", "HUGGINGFACE_TOKEN"), "")
        with (
            patch.dict(os.environ, env_clear, clear=False),
            patch("pathlib.Path.home", return_value=tmp_path),
        ):
            assert mdp._get_hf_token() is None

    def test_reads_token_from_file(self, tmp_path):
        token_dir = tmp_path / ".cache" / "huggingface"
        token_dir.mkdir(parents=True)
        (token_dir / "token").write_text("hf_from_file\n")

        env_clear = dict.fromkeys(("HF_TOKEN", "HUGGINGFACE_HUB_TOKEN", "HUGGINGFACE_TOKEN"), "")
        with (
            patch.dict(os.environ, env_clear, clear=False),
            patch("pathlib.Path.home", return_value=tmp_path),
        ):
            assert mdp._get_hf_token() == "hf_from_file"

    def test_reads_stored_tokens_json(self, tmp_path):
        token_dir = tmp_path / ".cache" / "huggingface"
        token_dir.mkdir(parents=True)
        stored = {"huggingface.co": {"token": "hf_stored_json"}}
        (token_dir / "stored_tokens").write_text(json.dumps(stored))

        env_clear = dict.fromkeys(("HF_TOKEN", "HUGGINGFACE_HUB_TOKEN", "HUGGINGFACE_TOKEN"), "")
        with (
            patch.dict(os.environ, env_clear, clear=False),
            patch("pathlib.Path.home", return_value=tmp_path),
        ):
            assert mdp._get_hf_token() == "hf_stored_json"


# ---------------------------------------------------------------------------
# Tests: _auth_headers_for_url
# ---------------------------------------------------------------------------


class TestAuthHeadersForUrl:
    def test_returns_bearer_for_huggingface(self):
        with patch.object(mdp, "_get_hf_token", return_value="hf_abc"):
            headers = mdp._auth_headers_for_url("https://huggingface.co/model/resolve/main/m.st")
            assert headers == {"Authorization": "Bearer hf_abc"}

    def test_returns_bearer_for_hf_subdomain(self):
        with patch.object(mdp, "_get_hf_token", return_value="hf_abc"):
            headers = mdp._auth_headers_for_url("https://cdn-lfs.huggingface.co/repos/abc")
            assert headers == {"Authorization": "Bearer hf_abc"}

    def test_returns_empty_for_non_hf(self):
        headers = mdp._auth_headers_for_url("https://civitai.com/api/download/models/123")
        assert headers == {}

    def test_returns_empty_for_http(self):
        headers = mdp._auth_headers_for_url("http://huggingface.co/model")
        assert headers == {}

    def test_returns_empty_when_no_token(self):
        with patch.object(mdp, "_get_hf_token", return_value=None):
            headers = mdp._auth_headers_for_url("https://huggingface.co/model")
            assert headers == {}

    def test_handles_invalid_url(self):
        headers = mdp._auth_headers_for_url("not-a-url")
        assert headers == {}


# ---------------------------------------------------------------------------
# Tests: _update_download_progress
# ---------------------------------------------------------------------------


class TestUpdateDownloadProgress:
    def test_updates_percent_and_speed(self):
        mdp.active_downloads["dl_prog"] = {
            "downloaded": 0,
            "percent": 0,
            "total_size": 1000,
        }
        start = mdp.time.time() - 1.0  # 1 second ago

        mdp._update_download_progress("dl_prog", 500, 1000, start)

        assert mdp.active_downloads["dl_prog"]["downloaded"] == 500
        assert mdp.active_downloads["dl_prog"]["percent"] == 50
        assert "speed" in mdp.active_downloads["dl_prog"]
        assert "eta" in mdp.active_downloads["dl_prog"]

    def test_handles_zero_total_size(self):
        mdp.active_downloads["dl_zero"] = {
            "downloaded": 0,
            "percent": 0,
            "total_size": 0,
        }
        start = mdp.time.time() - 1.0

        mdp._update_download_progress("dl_zero", 500, 0, start)

        assert mdp.active_downloads["dl_zero"]["downloaded"] == 500
        # percent not set when total_size is 0
        assert mdp.active_downloads["dl_zero"]["percent"] == 0

    def test_ignores_missing_download_id(self):
        # Should not raise
        mdp._update_download_progress("nonexistent", 500, 1000, mdp.time.time())


# ---------------------------------------------------------------------------
# Tests: _finalize_download
# ---------------------------------------------------------------------------


class TestFinalizeDownload:
    def test_marks_completed(self, tmp_model_dir):
        mdp.active_downloads["dl_fin"] = {
            "start_time": mdp.time.time() - 10,
            "status": "downloading",
        }

        mdp._finalize_download("dl_fin", 5000, 5000, str(tmp_model_dir / "model.st"))

        assert mdp.active_downloads["dl_fin"]["status"] == "completed"
        assert mdp.active_downloads["dl_fin"]["percent"] == 100
        assert mdp.active_downloads["dl_fin"]["downloaded"] == 5000
        assert "end_time" in mdp.active_downloads["dl_fin"]

    def test_handles_zero_total_size(self):
        mdp.active_downloads["dl_fin0"] = {
            "start_time": mdp.time.time() - 1,
            "status": "downloading",
        }

        mdp._finalize_download("dl_fin0", 5000, 0, "/path/model.st")

        assert mdp.active_downloads["dl_fin0"]["percent"] == 0

    def test_ignores_missing_download_id(self):
        mdp._finalize_download("nonexistent", 5000, 5000, "/path")


# ---------------------------------------------------------------------------
# Tests: download_model (HTTP handler)
# ---------------------------------------------------------------------------


class TestDownloadModelHandler:
    def _make_request(self, data: dict[str, Any]) -> MagicMock:
        """Create a mock aiohttp request with JSON data."""
        request = MagicMock()
        request.headers = {"Content-Type": "application/json"}
        request.json = AsyncMock(return_value=data)
        return request

    def test_rejects_missing_params(self):
        request = self._make_request({"url": "https://example.com/model.st"})
        response = asyncio.run(mdp.download_model(request))
        body = json.loads(response.body)  # type: ignore[arg-type]
        assert body["success"] is False
        assert "Missing required parameters" in body["error"]

    def test_rejects_invalid_folder(self):
        with patch.object(
            _folder_paths_mock, "get_folder_paths", side_effect=KeyError("invalid_folder")
        ):
            request = self._make_request(
                {
                    "url": "https://example.com/model.st",
                    "folder": "invalid_folder",
                    "filename": "model.st",
                }
            )
            response = asyncio.run(mdp.download_model(request))
            body = json.loads(response.body)  # type: ignore[arg-type]
            assert body["success"] is False
            assert "Invalid folder" in body["error"]

    def test_rejects_no_writable_path(self, tmp_readonly_dir):
        with patch.object(
            _folder_paths_mock, "get_folder_paths", return_value=[str(tmp_readonly_dir)]
        ):
            request = self._make_request(
                {
                    "url": "https://example.com/model.st",
                    "folder": "checkpoints",
                    "filename": "model.st",
                }
            )
            response = asyncio.run(mdp.download_model(request))
            body = json.loads(response.body)  # type: ignore[arg-type]
            assert body["success"] is False
            assert "No writable directory" in body["error"]

    def test_queues_download_successfully(self, tmp_model_dir):
        with patch.object(
            _folder_paths_mock, "get_folder_paths", return_value=[str(tmp_model_dir)]
        ):
            _prompt_server_instance.loop.create_task = MagicMock()
            request = self._make_request(
                {
                    "url": "https://huggingface.co/model/resolve/main/model.safetensors",
                    "folder": "checkpoints",
                    "filename": "model.safetensors",
                }
            )
            response = asyncio.run(mdp.download_model(request))
            body = json.loads(response.body)  # type: ignore[arg-type]
            assert body["success"] is True
            assert body["status"] == "queued"
            assert "download_id" in body


# ---------------------------------------------------------------------------
# Tests: send_download_update
# ---------------------------------------------------------------------------


class TestSendDownloadUpdate:
    def test_sends_skipped_status(self):
        mdp.active_downloads["dl_ws"] = {
            "status": "skipped",
            "filename": "model.st",
            "percent": 100,
            "downloaded": 5000,
            "total_size": 5000,
            "speed": 0,
            "eta": 0,
            "error": None,
        }

        asyncio.run(mdp.send_download_update("dl_ws"))

        _prompt_server_instance.send_sync.assert_called()
        call_args = _prompt_server_instance.send_sync.call_args
        assert call_args[0][0] == "model_download_progress"
        assert call_args[0][1]["status"] == "skipped"

    def test_ignores_missing_download(self):
        # Should not raise
        asyncio.run(mdp.send_download_update("nonexistent"))
