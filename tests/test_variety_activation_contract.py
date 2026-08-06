import os
import stat
import subprocess
import textwrap
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
HYPR_MODULE = ROOT / "modules" / "home" / "hypr.nix"
ACTIVATION_START = (
    '    home.activation.configureVarietyWallpaperFolders = '
    'lib.hm.dag.entryAfter [ "writeBoundary" ] \'\'\n'
)
MANAGED_LINES = [
    "download_folder = ~/Pictures/wallpaper/variety/downloaded",
    "fetched_folder = ~/Pictures/wallpaper/variety/fetched",
    "favorites_folder = ~/Pictures/wallpaper/variety/favorites",
    "copyto_folder = ~/Pictures/wallpaper/variety/favorites",
    "wallpaper_auto_rotate = False",
    "change_enabled = False",
    "change_on_start = False",
]


def _activation_script() -> str:
    content = HYPR_MODULE.read_text(encoding="utf-8")
    body = content.split(ACTIVATION_START, maxsplit=1)[1].split(
        "\n    '';", maxsplit=1
    )[0]
    script = textwrap.dedent(body)
    for nix_prefix in (
        "${pkgs.coreutils}/bin/",
        "${pkgs.gnugrep}/bin/",
        "${pkgs.diffutils}/bin/",
    ):
        script = script.replace(nix_prefix, "")
    assert "${pkgs." not in script
    return script


def _run_activation(
    home: Path,
    *,
    path: str | None = None,
    suffix: str = "",
) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["HOME"] = str(home)
    if path is not None:
        env["PATH"] = path
    return subprocess.run(
        [
            "bash",
            "-e",
            "-u",
            "-o",
            "pipefail",
            "-c",
            f"{_activation_script()}\n{suffix}",
        ],
        check=False,
        capture_output=True,
        text=True,
        env=env,
    )


def _config_path(home: Path) -> Path:
    return home / ".config" / "variety" / "variety.conf"


def test_noop_activation_preserves_content_and_mtime(tmp_path: Path) -> None:
    config = _config_path(tmp_path)
    config.parent.mkdir(parents=True)
    expected = "unmanaged_setting = keep\n" + "\n".join(MANAGED_LINES) + "\n"
    config.write_text(expected, encoding="utf-8")
    config.chmod(0o600)
    fixed_time_ns = 1_700_000_000_000_000_000
    os.utime(config, ns=(fixed_time_ns, fixed_time_ns))
    initial_mtime_ns = config.stat().st_mtime_ns

    result = _run_activation(tmp_path)

    assert result.returncode == 0, result.stderr
    assert config.read_text(encoding="utf-8") == expected
    assert config.stat().st_mtime_ns == initial_mtime_ns
    assert stat.S_IMODE(config.stat().st_mode) == 0o600


def test_activation_preserves_unmanaged_settings_and_updates_managed_values(
    tmp_path: Path,
) -> None:
    config = _config_path(tmp_path)
    config.parent.mkdir(parents=True)
    config.write_text(
        "unmanaged_setting = keep\n"
        "download_folder = /obsolete\n"
        "change_enabled = True\n",
        encoding="utf-8",
    )
    config.chmod(0o644)

    result = _run_activation(tmp_path)

    assert result.returncode == 0, result.stderr
    actual = config.read_text(encoding="utf-8")
    assert "unmanaged_setting = keep\n" in actual
    assert "/obsolete" not in actual
    assert "change_enabled = True" not in actual
    for line in MANAGED_LINES:
        assert actual.count(f"{line}\n") == 1
    assert stat.S_IMODE(config.stat().st_mode) == 0o600


def test_activation_propagates_grep_errors_without_replacing_config(
    tmp_path: Path,
) -> None:
    config = _config_path(tmp_path)
    config.parent.mkdir(parents=True)
    original = "unmanaged_setting = keep\n"
    config.write_text(original, encoding="utf-8")

    fake_bin = tmp_path / "fake-bin"
    fake_bin.mkdir()
    fake_grep = fake_bin / "grep"
    fake_grep.write_text("#!/bin/sh\nexit 2\n", encoding="utf-8")
    fake_grep.chmod(0o755)

    result = _run_activation(
        tmp_path,
        path=f"{fake_bin}{os.pathsep}{os.environ['PATH']}",
    )

    assert result.returncode == 2
    assert config.read_text(encoding="utf-8") == original


def test_activation_cleanup_trap_does_not_leak(tmp_path: Path) -> None:
    leak_target = tmp_path / "trap-must-not-leak"

    result = _run_activation(
        tmp_path,
        suffix=f'tmp="{leak_target}"\ntouch "$tmp"',
    )

    assert result.returncode == 0, result.stderr
    assert leak_target.exists()
