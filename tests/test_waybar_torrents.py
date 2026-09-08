from __future__ import annotations

import importlib.machinery
import importlib.util
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "files/home/.config/waybar/scripts/torrents"


def _load_renderer():
    loader = importlib.machinery.SourceFileLoader("waybar_torrents", str(SCRIPT))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    assert spec is not None
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


renderer = _load_renderer()


def _torrent(
    torrent_id: int,
    name: str,
    *,
    status: int = 4,
    percent_done: float = 0.5,
    rate_down: int = 1024 * 1024,
    rate_up: int = 0,
    eta: int = 120,
    error: int = 0,
    error_string: str = "",
) -> dict[str, object]:
    return {
        "id": torrent_id,
        "name": name,
        "status": status,
        "percentDone": percent_done,
        "rateDownload": rate_down,
        "rateUpload": rate_up,
        "eta": eta,
        "error": error,
        "errorString": error_string,
    }


def _payload(*torrents: dict[str, object]) -> dict[str, object]:
    return {
        "result": "success",
        "arguments": {"torrents": list(torrents)},
    }


def test_active_summary_and_transfer_rates() -> None:
    output = renderer.render_payload(
        _payload(
            _torrent(1, "download", rate_down=2 * 1024 * 1024),
            _torrent(
                2,
                "seed",
                status=6,
                percent_done=1.0,
                rate_down=0,
                rate_up=512 * 1024,
                eta=-1,
            ),
            _torrent(
                3,
                "stopped",
                status=0,
                percent_done=1.0,
                rate_down=0,
                eta=-1,
            ),
        )
    )

    assert output["class"] == "active"
    assert output["text"] == "󰇚 2/3"
    assert "2 active / 3 torrents" in output["tooltip"]
    assert "↓ 2.0 MiB/s · ↑ 512.0 KiB/s" in output["tooltip"]
    assert "download · downloading, ETA 2m 0s" in output["tooltip"]
    assert "seed · seeding" in output["tooltip"]


def test_empty_list_is_idle_and_still_clickable() -> None:
    output = renderer.render_payload(_payload())

    assert output["class"] == "idle"
    assert output["text"] == "󰇚 0"
    assert output["alt"] == "idle"
    assert "Click: open tremc" in output["tooltip"]


def test_torrent_error_is_visible_and_has_priority() -> None:
    output = renderer.render_payload(
        _payload(
            _torrent(1, "normal", status=0, rate_down=0, eta=-1),
            _torrent(
                2,
                "broken",
                status=0,
                rate_down=0,
                eta=-1,
                error=3,
                error_string="tracker failed",
            ),
        )
    )

    assert output["class"] == "error"
    assert output["alt"] == "error"
    lines = output["tooltip"].splitlines()
    assert "broken · error: tracker failed" in lines[4]


def test_dynamic_torrent_fields_are_markup_escaped() -> None:
    output = renderer.render_payload(_payload(_torrent(1, "<b>unsafe</b>")))

    assert "<b>unsafe</b>" not in output["tooltip"]
    assert "&lt;b&gt;unsafe&lt;/b&gt;" in output["tooltip"]


def test_invalid_percent_fails_closed() -> None:
    torrent = _torrent(1, "bad", percent_done=1.5)

    with pytest.raises(renderer.StatusError):
        renderer.render_payload(_payload(torrent))


def test_degraded_output_does_not_expose_markup() -> None:
    output = renderer.degraded_output("<b>rpc failed</b>")

    assert output["class"] == "error"
    assert output["text"] == "󰇚 !"
    assert "<b>rpc failed</b>" not in output["tooltip"]
    assert "&lt;b&gt;rpc failed&lt;/b&gt;" in output["tooltip"]
