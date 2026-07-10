#!/usr/bin/env python3
"""Regression checks for git-autocommit's immutable staged-tree behavior."""

from __future__ import annotations

import argparse
import importlib.machinery
import importlib.util
import os
import subprocess
import sys
import tempfile
from pathlib import Path


def run(*args: str, cwd: Path) -> str:
    return subprocess.run(
        ["git", *args],
        cwd=cwd,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    ).stdout.strip()


def load_module(path: Path):
    loader = importlib.machinery.SourceFileLoader("git_autocommit", str(path))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    if spec is None:
        raise RuntimeError("unable to load git-autocommit")
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


def write(path: Path, value: str) -> None:
    path.write_text(value, encoding="utf-8")


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit("usage: verify-git-autocommit.py PATH_TO_SCRIPT")
    module = load_module(Path(sys.argv[1]).resolve())

    with tempfile.TemporaryDirectory(prefix="git-autocommit-test-") as directory:
        repo = Path(directory)
        run("init", "-q", cwd=repo)
        run("config", "user.name", "Test User", cwd=repo)
        run("config", "user.email", "test@example.invalid", cwd=repo)

        write(repo / "alpha.txt", "alpha base\n")
        write(repo / "delete.txt", "delete base\n")
        run("add", "alpha.txt", "delete.txt", cwd=repo)
        run("commit", "-q", "-m", "chore: seed repository", cwd=repo)
        base = run("rev-parse", "HEAD", cwd=repo)

        write(repo / "alpha.txt", "alpha staged\n")
        write(repo / "beta.txt", "beta staged\n")
        (repo / "delete.txt").unlink()
        run("add", "alpha.txt", "beta.txt", "delete.txt", cwd=repo)
        snapshot = run("write-tree", cwd=repo)

        write(repo / "alpha.txt", "alpha unstaged drift\n")
        write(repo / "beta.txt", "beta unstaged drift\n")
        write(repo / "delete.txt", "resurrected but unstaged\n")

        previous = Path.cwd()
        os.chdir(repo)
        try:
            config_path = module.git_config_path()
            assert config_path == repo / ".git" / "autocommit.toml"
            write(
                config_path,
                'model = "config-model"\nmax_commits = 3\nsingle_commit = true\n',
            )
            config = module.load_config()
            args = argparse.Namespace(
                base_url=None,
                model=None,
                timeout=None,
                prompt_dir=None,
                single=False,
            )
            settings = module.resolve_settings(args, config)
            assert settings["model"] == "config-model"
            assert settings["max_commits"] == 3
            assert settings["single_commit"] is True

            module.assert_snapshot_unchanged(base, snapshot)
            first_tree = module.build_commit_tree(base, snapshot, ["alpha.txt"])
            first = run(
                "commit-tree",
                first_tree,
                "-p",
                base,
                "-m",
                "test: first group",
                cwd=repo,
            )
            second_tree = module.build_commit_tree(
                first, snapshot, ["beta.txt", "delete.txt"]
            )

            original_create = module.create_signed_commit_object
            calls = 0

            def create_with_index_race(tree: str, parent: str, message: str) -> str:
                nonlocal calls
                calls += 1
                commit = run(
                    "commit-tree", tree, "-p", parent, "-m", message, cwd=repo
                )
                if calls == 1:
                    write(repo / "gamma.txt", "concurrent staged change\n")
                    run("add", "gamma.txt", cwd=repo)
                return commit

            module.create_signed_commit_object = create_with_index_race
            plan = [
                {"message": "test: first group", "files": ["alpha.txt"]},
                {
                    "message": "test: second group",
                    "files": ["beta.txt", "delete.txt"],
                },
            ]
            try:
                module.create_signed_commits(plan, base, snapshot)
            except module.AutocommitError:
                pass
            else:
                raise AssertionError("index race did not abort commit application")
            finally:
                module.create_signed_commit_object = original_create

            assert run("rev-parse", "HEAD", cwd=repo) == base
        finally:
            os.chdir(previous)

        assert run("show", f"{first_tree}:alpha.txt", cwd=repo) == "alpha staged"
        assert run("show", f"{second_tree}:beta.txt", cwd=repo) == "beta staged"
        assert subprocess.run(
            ["git", "cat-file", "-e", f"{second_tree}:delete.txt"],
            cwd=repo,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        ).returncode != 0
        assert second_tree == snapshot

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
