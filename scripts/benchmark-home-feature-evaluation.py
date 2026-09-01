#!/usr/bin/env python3
"""Compare isolated Home Manager feature evaluation cost."""

from __future__ import annotations

import argparse
import json
import statistics
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any, Sequence

MAX_REPEAT = 20
VARIANTS = {
    "graphical-base": "",
    "meeting": "dotfiles.meeting.enable = true;",
    "hermes": "dotfiles.agents.hermes.enable = true;",
    "antigravity": "dotfiles.agents.antigravity.enable = true;",
    "headroom": "dotfiles.headroom.proxy.enable = true;",
    "openwork": "dotfiles.openwork.enable = true;",
    "workstation-combined": """
      dotfiles.profiles.workstation.enable = true;
      dotfiles.meeting.enable = true;
      dotfiles.agents.hermes.enable = true;
      dotfiles.agents.antigravity.enable = true;
      dotfiles.headroom.proxy.enable = true;
    """,
    "dubnium-combined": """
      dotfiles.profiles.workstation.enable = true;
      dotfiles.meeting.enable = true;
      dotfiles.agents.hermes.enable = true;
      dotfiles.agents.antigravity.enable = true;
      dotfiles.headroom.proxy.enable = true;
      dotfiles.profiles.browser.enable = true;
      dotfiles.profiles.office.enable = true;
      dotfiles.openwork.enable = true;
      dotfiles.music.enable = true;
      dotfiles.music.musicDirectory = \"/mnt/isotope/Music\";
    """,
}
DEFAULT_VARIANTS = tuple(VARIANTS)


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compare isolated Home Manager feature evaluation cost"
    )
    parser.add_argument("--flake-dir", type=Path, default=Path("."))
    parser.add_argument("--repeat", type=int, default=3)
    parser.add_argument("--variant", action="append", dest="variants")
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("benchmark-results/home-feature-evaluation.json"),
    )
    return parser.parse_args(argv)


def validate(args: argparse.Namespace) -> str | None:
    if not args.flake_dir.is_dir():
        return "--flake-dir must be an existing directory"
    if not 1 <= args.repeat <= MAX_REPEAT:
        return f"--repeat must be between 1 and {MAX_REPEAT}"
    unknown = [name for name in args.variants or DEFAULT_VARIANTS if name not in VARIANTS]
    return f"unknown variant: {unknown[0]}" if unknown else None


def nix_expression(flake_dir: Path, config_text: str) -> str:
    root = json.dumps(str(flake_dir))
    return f'''let
  root = builtins.toPath {root};
  flake = builtins.getFlake (toString root);
  system = "x86_64-linux";
  username = "ryjen";
  pkgs = import flake.inputs.nixpkgs {{
    inherit system;
    config.allowUnfree = true;
  }};
  configuration = flake.inputs.home-manager.lib.homeManagerConfiguration {{
    inherit pkgs;
    extraSpecialArgs = {{
      inherit username;
      self = flake;
      hermes-agent = flake.inputs.hermes-agent;
      antigravity-nix = flake.inputs.antigravity-nix;
      git-autocommit = flake.inputs.git-autocommit;
    }};
    modules = [
      (root + "/home/ryjen/layers/graphical.nix")
      (root + "/home/ryjen/profiles/graphical.nix")
      flake.inputs.sops-nix.homeManagerModules.sops
      ({{ ... }}: {{
        home.username = username;
        home.homeDirectory = "/home/${{username}}";
        home.stateVersion = "25.05";
        programs.home-manager.enable = true;
        dotfiles.host.userSystemd.enable = true;
        {config_text}
      }})
    ];
  }};
in configuration.activationPackage.drvPath
'''


def evaluate(expression_path: Path, cwd: Path) -> tuple[float, int]:
    started = time.perf_counter()
    completed = subprocess.run(
        ["nix", "eval", "--impure", "--raw", "--file", str(expression_path)],
        cwd=cwd,
        stdout=subprocess.DEVNULL,
        check=False,
    )
    return round(time.perf_counter() - started, 6), completed.returncode


def git_metadata(cwd: Path) -> dict[str, Any]:
    def capture(*command: str) -> str | None:
        result = subprocess.run(
            command,
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            check=False,
        )
        return result.stdout.strip() if result.returncode == 0 else None

    revision = capture("git", "rev-parse", "HEAD")
    status = capture("git", "status", "--porcelain")
    return {
        "available": revision is not None and status is not None,
        "revision": revision,
        "dirty": bool(status) if status is not None else None,
    }


def atomic_write(path: Path, payload: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=path.parent,
            prefix=f".{path.name}.",
            suffix=".tmp",
            delete=False,
        ) as temporary:
            temporary_path = Path(temporary.name)
            temporary.write(payload)
        temporary_path.replace(path)
    except OSError:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)
        raise


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    error = validate(args)
    if error:
        print(error, file=sys.stderr)
        return 64

    flake_dir = args.flake_dir.resolve()
    selected = tuple(dict.fromkeys(args.variants or DEFAULT_VARIANTS))
    results: list[dict[str, Any]] = []

    with tempfile.TemporaryDirectory(prefix="dotfiles-feature-eval-") as directory:
        temporary_dir = Path(directory)
        for variant in selected:
            expression = temporary_dir / f"{variant}.nix"
            expression.write_text(
                nix_expression(flake_dir, VARIANTS[variant]), encoding="utf-8"
            )
            samples: list[float] = []
            for iteration in range(1, args.repeat + 1):
                elapsed, exit_code = evaluate(expression, flake_dir)
                if exit_code != 0:
                    print(
                        f"evaluation failed for {variant} iteration {iteration}",
                        file=sys.stderr,
                    )
                    return 1
                samples.append(elapsed)
            results.append(
                {
                    "variant": variant,
                    "count": len(samples),
                    "samples_seconds": samples,
                    "median_seconds": round(statistics.median(samples), 6),
                    "min_seconds": round(min(samples), 6),
                    "max_seconds": round(max(samples), 6),
                }
            )

    ranked = sorted(results, key=lambda item: item["median_seconds"])
    baseline = next(
        item["median_seconds"]
        for item in ranked
        if item["variant"] == "graphical-base"
    )
    for item in ranked:
        item["delta_from_graphical_base_seconds"] = round(
            item["median_seconds"] - baseline, 6
        )

    result = {
        "schema_version": 1,
        "kind": "home-feature-evaluation-comparison",
        "repeat": args.repeat,
        "repository": git_metadata(flake_dir),
        "timestamp_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "variants": ranked,
        "notes": {
            "evaluation_only": True,
            "uses_impure_local_flake_reference": True,
            "realizes_outputs": False,
            "activates_generation": False,
        },
    }
    payload = json.dumps(result, indent=2, sort_keys=True) + "\n"
    output = args.output if args.output.is_absolute() else flake_dir / args.output
    try:
        atomic_write(output, payload)
    except OSError as write_error:
        print(f"unable to write result: {write_error}", file=sys.stderr)
        return 73
    sys.stdout.write(payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
