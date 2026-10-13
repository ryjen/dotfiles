#!/usr/bin/env python3
"""Review Git-tracked dotfiles for accidentally publishable credential material.

This is a conservative current-tree gate, not a history/entropy credential scan.
Never print matched file contents, keys or credential values.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

DISALLOWED_SUFFIXES = {".pem", ".p12", ".pfx", ".key", ".agekey", ".sqlite", ".db"}
PRIVATE_PEM = re.compile(
    rb"-----BEGIN (?:RSA |EC |DSA |OPENSSH |ENCRYPTED )?PRIVATE KEY-----"
)
SOPS_ENTRY = re.compile(rb"(?m)^\s*(?:github_token|openai_api_key|anthropic_api_key)\s*:\s*ENC\[")
KEY_ENTRIES = re.compile(
    rb"(?m)^\s*(?:github_token|openai_api_key|anthropic_api_key)\s*:"
)
CHUNK = 65536


def tracked_paths(root: Path) -> list[Path]:
    p = subprocess.run(
        ["git", "-C", str(root), "ls-files", "--cached", "-z"],
        capture_output=True, check=True,
    )
    return [Path(os.fsdecode(n)) for n in p.stdout.split(b"\0") if n]


def is_blocked_name(rel: Path) -> bool:
    name = rel.name.lower()
    if name in {"id_rsa", "id_ed25519", "id_ecdsa", "credentials.json"}:
        return True
    if name == ".env" or (
        name.startswith(".env.") and
        not name.endswith((".example", ".sample", ".template"))
    ):
        return True
    if rel.suffix.lower() in DISALLOWED_SUFFIXES:
        return True
    return False


def has_private_pem(path: Path) -> bool:
    tail = b""
    with path.open("rb") as f:
        while chunk := f.read(CHUNK):
            data = tail + chunk
            if PRIVATE_PEM.search(data):
                return True
            tail = data[-100:]
    return False


def valid_sops_secrets(path: Path) -> bool:
    """Opt-in encrypted secrets.yaml is allowed, never a plaintext copy."""
    raw = path.read_bytes()
    if b"ENC[" not in raw or not re.search(rb"(?m)^sops:\s*$", raw):
        return False
    all_keys = KEY_ENTRIES.findall(raw)
    return len(all_keys) > 0 and len(all_keys) == len(SOPS_ENTRY.findall(raw))


def inspect(root: Path, files: list[Path]) -> list[tuple[str, str]]:
    findings: list[tuple[str, str]] = []
    for rel in sorted(files):
        # git ls-files paths are relative; never inspect outside the checkout.
        if rel.is_absolute() or ".." in rel.parts:
            findings.append((str(rel), "unsafe tracked path"))
            continue
        path = root / rel
        if path.is_symlink():
            findings.append((str(rel), "tracked symlink needs review"))
            continue
        if not path.is_file():
            findings.append((str(rel), "missing tracked file"))
            continue
        if rel.as_posix() == "secrets.yaml":
            if not valid_sops_secrets(path):
                findings.append((str(rel), "unencrypted SOPS file"))
        elif is_blocked_name(rel):
            findings.append((str(rel), "credential-like tracked path"))
        if has_private_pem(path):
            findings.append((str(rel), "private key PEM marker"))
    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=Path(__file__).resolve().parents[1], type=Path)
    args = parser.parse_args()
    try:
        errors = inspect(args.root, tracked_paths(args.root))
    except (OSError, subprocess.CalledProcessError) as exc:
        print("credential-gate: could not inspect tracked checkout (" +
              type(exc).__name__ + ")", file=sys.stderr)
        return 2
    if errors:
        for filename, reason in errors:
            # Escape newlines in file paths to prevent log spoofing.
            safe = filename.encode("unicode_escape").decode("ascii")
            print(f"credential-gate: blocked {safe}: {reason}", file=sys.stderr)
        return 1
    print("credential-gate: tracked files validated")
    return 0


if __name__ == "__main__":
    sys.exit(main())
