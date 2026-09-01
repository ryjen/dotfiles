from __future__ import annotations

import importlib.machinery
import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "files/home/.config/waybar/scripts/github-runners"
ACTION = ROOT / "files/home/.config/waybar/scripts/github-runners-action"


def _load_renderer():
    loader = importlib.machinery.SourceFileLoader("waybar_github_runners", str(SCRIPT))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    assert spec is not None
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


renderer = _load_renderer()


def _payload(
    *,
    active: int = 2,
    running: int = 2,
    capacity: int = 4,
    available: int = 2,
    ambiguous: int = 0,
    ordinary_state: str = "active",
    effective_state: str = "resumed",
    runtime_valid: bool = True,
    service_valid: bool = True,
) -> dict[str, object]:
    workers = []
    for index in range(active):
        worker_id = f"{index + 1:032x}"
        repository_key = "dotfiles" if index % 2 == 0 else "career-workflows"
        workers.append(
            {
                "repositoryKey": repository_key,
                "workerId": worker_id,
                "runnerName": f"dubnium-test-{worker_id[:12]}",
                "phase": "worker-started" if index < running else "jit-minted",
                "workerUnitActive": index < running,
                "runnerId": index + 1,
            }
        )

    return {
        "administrativeStateValid": True,
        "effectiveState": effective_state,
        "ordinaryRuntimeState": ordinary_state,
        "controllerValidation": {"valid": True},
        "repositoryPolicies": [
            {"key": "dotfiles", "repository": "ryjen/dotfiles"},
            {"key": "career-workflows", "repository": "ryjen/career-workflows"},
        ],
        "controllerService": {
            "valid": service_valid,
            "reason": (
                "controller-service-running"
                if service_valid
                else "controller-service-not-running"
            ),
        },
        "controllerRuntime": {
            "valid": runtime_valid,
            "reason": (
                "controller-status-valid"
                if runtime_valid
                else "controller-status-invalid"
            ),
            "capacity": capacity,
            "ownedWorkerCount": active,
            "ambiguousWorkerCount": ambiguous,
            "runningWorkerCount": running,
            "availableCapacity": available,
            "workers": workers,
        },
    }


def test_healthy_status_uses_owned_workers_as_active_count() -> None:
    output = renderer.render_payload(_payload(active=2, running=1))

    assert output["class"] == "healthy"
    assert output["text"] == " 2/4 · 2 free"
    assert "2 active / 4 capacity / 2 available" in output["tooltip"]
    assert "Running units: 1" in output["tooltip"]
    assert "ryjen/dotfiles" in output["tooltip"]
    assert "ryjen/career-workflows" in output["tooltip"]


def test_full_capacity_is_busy_not_degraded() -> None:
    output = renderer.render_payload(_payload(active=4, running=4, available=0))

    assert output["class"] == "busy"
    assert "⚠" not in output["text"]


def test_resumed_zero_worker_state_is_idle() -> None:
    output = renderer.render_payload(
        _payload(
            active=0,
            running=0,
            available=4,
            ordinary_state="eligible",
        )
    )

    assert output["class"] == "idle"


def test_administratively_suspended_state_is_distinct_from_idle() -> None:
    output = renderer.render_payload(
        _payload(
            active=0,
            running=0,
            available=4,
            ordinary_state="suspended",
            effective_state="suspended",
        )
    )

    assert output["class"] == "suspended"


def test_ambiguous_worker_state_is_degraded_without_inventing_capacity() -> None:
    output = renderer.render_payload(
        _payload(
            active=2,
            running=1,
            available=2,
            ambiguous=1,
            ordinary_state="unverified",
        )
    )

    assert output["class"] == "degraded"
    assert output["text"] == " 2/4 · 2 free ⚠"
    assert "Ambiguous workers: 1" in output["tooltip"]


def test_inconsistent_counts_fail_closed() -> None:
    payload = _payload(active=2, running=2, available=3)
    payload["controllerRuntime"]["ownedWorkerCount"] = 5  # type: ignore[index]

    with pytest.raises(renderer.StatusError):
        renderer.render_payload(payload)


def test_dynamic_tooltip_fields_are_markup_escaped() -> None:
    payload = _payload()
    payload["repositoryPolicies"][0]["repository"] = "ryjen/<b>dotfiles</b>"  # type: ignore[index]

    output = renderer.render_payload(payload)

    assert "<b>dotfiles</b>" not in output["tooltip"]
    assert "&lt;b&gt;dotfiles&lt;/b&gt;" in output["tooltip"]


def test_unknown_capacity_renders_unknown_not_zero(tmp_path: Path) -> None:
    payload = _payload(active=0, running=0, available=4)
    runtime = payload["controllerRuntime"]
    assert isinstance(runtime, dict)
    runtime["valid"] = False
    runtime["reason"] = "controller-status-command-timeout"
    runtime["capacity"] = None
    runtime["availableCapacity"] = None

    fixture = tmp_path / "status.json"
    fixture.write_text(json.dumps(payload), encoding="utf-8")
    env = dict(os.environ)
    env["WAYBAR_GITHUB_RUNNERS_STATUS_FILE"] = str(fixture)

    completed = subprocess.run(
        [sys.executable, str(SCRIPT)],
        check=True,
        capture_output=True,
        text=True,
        env=env,
    )
    output = json.loads(completed.stdout)

    assert output["class"] == "degraded"
    assert output["text"] == " ?/? · ? free ⚠"
    assert "0/0" not in output["text"]


def test_malformed_status_file_renders_degraded_json(tmp_path: Path) -> None:
    fixture = tmp_path / "status.json"
    fixture.write_text("not-json", encoding="utf-8")
    env = dict(os.environ)
    env["WAYBAR_GITHUB_RUNNERS_STATUS_FILE"] = str(fixture)

    completed = subprocess.run(
        [sys.executable, str(SCRIPT)],
        check=True,
        capture_output=True,
        text=True,
        env=env,
    )
    output = json.loads(completed.stdout)

    assert output["class"] == "degraded"
    assert output["alt"] == "unverified"
    assert "Status unavailable" in output["tooltip"]


def test_click_actions_are_shell_valid_and_read_only() -> None:
    subprocess.run(["bash", "-n", str(ACTION)], check=True)
    contents = ACTION.read_text(encoding="utf-8")

    assert "dubctl runners watch" in contents
    assert '"$self" queue-view' in contents
    assert "dubctl runners queue view" in contents
    assert "Press Enter to close" in contents
    assert 'exec "$terminal" --hold' not in contents
    for mutation in (
        "dubctl runners suspend",
        "dubctl runners resume",
        "dubctl runners reconcile",
    ):
        assert mutation not in contents
