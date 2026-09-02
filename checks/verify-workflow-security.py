from __future__ import annotations

import re
import sys
from pathlib import Path

SHA_RE = re.compile(r"^[0-9a-f]{40}$")
USES_RE = re.compile(r"^\s*(?:-\s*)?uses:\s*([^\s#]+)")
PULL_REQUEST_TARGET_RE = re.compile(r"(?m)^\s*pull_request_target\s*:")
TIMEOUT_RE = re.compile(r"^\s{4}timeout-minutes:\s*[1-9][0-9]*\s*(?:#.*)?$")
PERSIST_CREDENTIALS_RE = re.compile(r"^\s+persist-credentials:\s*false\s*(?:#.*)?$")


def indentation(line: str) -> int:
    return len(line) - len(line.lstrip(" "))


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


def indented_block(lines: list[str], start: int, parent_indent: int) -> list[str]:
    block: list[str] = []
    for line in lines[start + 1 :]:
        if line.strip() and indentation(line) <= parent_indent:
            break
        block.append(line)
    return block


def validate_permissions(lines: list[str], workflow: Path, errors: list[str]) -> None:
    try:
        permissions_index = next(
            index
            for index, line in enumerate(lines)
            if indentation(line) == 0 and line.strip() == "permissions:"
        )
    except StopIteration:
        fail(errors, workflow, "missing workflow-level permissions")
        return

    entries: dict[str, str] = {}
    for line in indented_block(lines, permissions_index, 0):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        match = re.match(r"^\s{2}([^:#]+):\s*([^\s#]+)", line)
        if not match:
            fail(errors, workflow, f"unrecognized workflow permission line: {line.strip()!r}")
            continue
        entries[match.group(1).strip()] = match.group(2).strip()

    if entries != {"contents": "read"}:
        fail(errors, workflow, "workflow-level permissions must be exactly 'contents: read'")


def validate_jobs(lines: list[str], workflow: Path, errors: list[str]) -> None:
    try:
        jobs_index = next(
            index for index, line in enumerate(lines) if indentation(line) == 0 and line.strip() == "jobs:"
        )
    except StopIteration:
        fail(errors, workflow, "workflow must define jobs")
        return

    job_headers: list[tuple[int, str]] = []
    for index in range(jobs_index + 1, len(lines)):
        line = lines[index]
        if line.strip() and indentation(line) == 0:
            break
        match = re.match(r"^\s{2}([A-Za-z0-9_-]+):\s*(?:#.*)?$", line)
        if match:
            job_headers.append((index, match.group(1)))

    if not job_headers:
        fail(errors, workflow, "workflow must define at least one job")
        return

    for position, (start, job_name) in enumerate(job_headers):
        end = job_headers[position + 1][0] if position + 1 < len(job_headers) else len(lines)
        job_lines = lines[start + 1 : end]

        if not any(TIMEOUT_RE.match(line) for line in job_lines):
            fail(errors, workflow, f"job {job_name!r} has no timeout-minutes")

        for index, line in enumerate(job_lines):
            if indentation(line) == 4 and line.strip() == "permissions:":
                for permission_line in indented_block(job_lines, index, 4):
                    match = re.match(r"^\s{6}([^:#]+):\s*([^\s#]+)", permission_line)
                    if match and match.group(2) == "write":
                        fail(
                            errors,
                            workflow,
                            f"job {job_name!r} grants write permission {match.group(1).strip()!r}",
                        )


def checkout_step_has_persist_false(lines: list[str], uses_index: int) -> bool:
    step_start = uses_index
    while step_start >= 0:
        line = lines[step_start]
        if indentation(line) == 6 and line.lstrip().startswith("- "):
            break
        step_start -= 1

    if step_start < 0:
        return False

    step_end = len(lines)
    for index in range(step_start + 1, len(lines)):
        line = lines[index]
        if indentation(line) == 6 and line.lstrip().startswith("- "):
            step_end = index
            break

    return any(PERSIST_CREDENTIALS_RE.match(line) for line in lines[step_start:step_end])


def validate_actions(lines: list[str], workflow: Path, errors: list[str]) -> None:
    for index, line in enumerate(lines):
        match = USES_RE.match(line)
        if not match:
            continue

        uses = match.group(1)
        if not action_is_immutable(uses):
            fail(errors, workflow, f"mutable action reference {uses!r}")

        if uses.startswith("actions/checkout@") and not checkout_step_has_persist_false(lines, index):
            fail(errors, workflow, "actions/checkout must set persist-credentials: false")


def validate_workflow(workflow: Path, repo_root: Path) -> list[str]:
    relative = workflow.relative_to(repo_root)
    text = workflow.read_text(encoding="utf-8")
    lines = text.splitlines()
    errors: list[str] = []

    if PULL_REQUEST_TARGET_RE.search(text):
        fail(errors, relative, "pull_request_target is forbidden")

    validate_permissions(lines, relative, errors)
    validate_jobs(lines, relative, errors)
    validate_actions(lines, relative, errors)
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
