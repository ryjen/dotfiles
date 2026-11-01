"""Smoke-test the read-only disk I/O Waybar adapter on Linux."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "files/home/.config/waybar/scripts/disk-space"


def test_disk_widget_shell_syntax() -> None:
    subprocess.run(["bash", "-n", str(SCRIPT)], check=True)


@pytest.mark.skipif(
    not Path("/proc/diskstats").is_file()
    or not all(shutil.which(command) for command in ("findmnt", "df", "awk", "numfmt")),
    reason="Linux /proc and required mount inspection tools are needed",
)
def test_disk_widget_labels_io_before_capacity_and_distinguishes_psi(tmp_path: Path) -> None:
    env = dict(os.environ)
    env.update(
        {
            "XDG_RUNTIME_DIR": str(tmp_path),
            "WAYBAR_DISK_IO_SAMPLE_SECONDS": "0.05",
            "WAYBAR_DISK_BTRFS_CACHE_SECONDS": "3600",
        }
    )
    result = subprocess.run(
        ["bash", str(SCRIPT)],
        check=True,
        text=True,
        capture_output=True,
        env=env,
        timeout=15,
    )
    payload = json.loads(result.stdout)
    assert payload["text"].startswith("󰓅 ")
    assert "󰋊" in payload["text"]
    assert "Root device I/O" in payload["tooltip"]
    assert "PSI avg10: some " in payload["tooltip"]
    assert "Device busy time is not application stall time" in payload["tooltip"]
    assert payload["class"] in ("normal", "warning", "critical")
    assert isinstance(payload["percentage"], int)
