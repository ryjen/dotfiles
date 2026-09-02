from __future__ import annotations

import re
import sys
from pathlib import Path

import yaml

SHA_RE = re.compile(r"^[0-9a-f]{40}$")
PULL_REQUEST_TARGET_RE = re.compile(r"(?m)^\s*pull_request_target\s*:")


def fail(errors: list[str], workflow: Path, message: str) -> None:
    errors.append(f"{workflow}: {message}")


def action_is_immutable(value: str) -> bool:
    if value.startswith("./"):
        return True
    if value.startswith("docker://"):
        return "@sha256:" in value
    if "@" not in value:
        return False
    _, ref = value.rsplit("@", 1)
    return bool(SHA_RE.fullmatch(ref))


def validate_workflow(workflow: Path, repo_root: Path) -> list[str]:
    errors: list[str] = []
    text = workflow.read_text(encoding="utf-8")

    if PULL_REQUEST_TARGET_RE.search(text):
        fail(errors, workflow.relative_to(repo_root), "pull_request_target is forbidden")

    try:
        document = yaml.safe_load(text)
    except yaml.YAMLError as exc:
        fail(errors, workflow.relative_to(repo_root), f"invalid YAML: {exc}")
        return errors

    if not isinstance(document, dict):
        fail(errors, workflow.relative_to(repo_root), "workflow root must be a mapping")
        return errors

    permissions = document.get("permissions")
    if permissions != {"contents": "read"}:
        fail(
            errors,
            workflow.relative_to(repo_root),
            "workflow-level permissions must be exactly 'contents: read'",
        )

    jobs = document.get("jobs")
    if not isinstance(jobs, dict) or not jobs:
        fail(errors, workflow.relative_to(repo_root), "workflow must define jobs")
        return errors

    for job_name, job in jobs.items():
        if not isinstance(job, dict):
            fail(errors, workflow.relative_to(repo_root), f"job {job_name!r} must be a mapping")
            continue

        if "timeout-minutes" not in job:
            fail(errors, workflow.relative_to(repo_root), f"job {job_name!r} has no timeout-minutes")

        job_permissions = job.get("permissions")
        if isinstance(job_permissions, dict):
            writable = [name for name, access in job_permissions.items() if access == "write"]
            if writable:
                fail(
                    errors,
                    workflow.relative_to(repo_root),
                    f"job {job_name!r} grants write permissions: {', '.join(sorted(writable))}",
                )

        steps = job.get("steps", [])
        if not isinstance(steps, list):
            fail(errors, workflow.relative_to(repo_root), f"job {job_name!r} steps must be a list")
            continue

        for index, step in enumerate(steps, start=1):
            if not isinstance(step, dict):
                continue
            uses = step.get("uses")
            if not isinstance(uses, str):
                continue

            if not action_is_immutable(uses):
                fail(
                    errors,
                    workflow.relative_to(repo_root),
                    f"job {job_name!r} step {index} uses mutable action reference {uses!r}",
                )

            if uses.startswith("actions/checkout@"):
                with_options = step.get("with")
                persist_credentials = (
                    with_options.get("persist-credentials") if isinstance(with_options, dict) else None
                )
                if persist_credentials is not False:
                    fail(
                        errors,
                        workflow.relative_to(repo_root),
                        f"job {job_name!r} checkout step {index} must set persist-credentials: false",
                    )

    return errors


def main() -> int:
    repo_root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    workflow_dir = repo_root / ".github" / "workflows"
    workflows = sorted([*workflow_dir.glob("*.yml"), *workflow_dir.glob("*.yaml")])

    if not workflows:
        print("no GitHub Actions workflows found", file=sys.stderr)
        return 1

    errors: list[str] = []
    for workflow in workflows:
        errors.extend(validate_workflow(workflow, repo_root))

    if errors:
        print("GitHub Actions workflow security policy failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"validated workflow security policy for {len(workflows)} workflow(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
