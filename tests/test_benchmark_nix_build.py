from __future__ import annotations

import importlib.util
import io
import json
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from types import ModuleType
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "benchmark-nix-build.py"


def load_module() -> ModuleType:
    spec = importlib.util.spec_from_file_location("benchmark_nix_build", SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"unable to load {SCRIPT}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


benchmark = load_module()


class BenchmarkNixBuildTests(unittest.TestCase):
    def test_evaluation_and_realization_are_separate_commands(self) -> None:
        target = '.#homeConfigurations."ryjen@dubnium".activationPackage'
        drv = "/nix/store/example.drv"
        self.assertEqual(
            benchmark.evaluation_command(target),
            ["nix", "eval", "--raw", f"{target}.drvPath"],
        )
        self.assertEqual(
            benchmark.realization_command(drv),
            ["nix-store", "--realise", drv],
        )
        self.assertNotIn(target, benchmark.realization_command(drv))

    def test_timed_command_keeps_child_stdout_out_of_json_stream(self) -> None:
        completed = subprocess.CompletedProcess(
            args=["fake"],
            returncode=0,
            stdout="child noise\n",
        )
        stdout = io.StringIO()
        with mock.patch.object(benchmark, "run", return_value=completed):
            with redirect_stdout(stdout):
                measurement = benchmark.timed_command(
                    "test",
                    1,
                    ["fake"],
                    cwd=ROOT,
                    capture_stdout=True,
                )
        self.assertEqual(stdout.getvalue(), "")
        self.assertEqual(measurement.stdout, "child noise\n")

    def test_substituters_are_fingerprinted_not_exposed(self) -> None:
        raw = {
            "max-jobs": {"value": 4},
            "cores": {"value": 3},
            "max-substitution-jobs": {"value": 16},
            "substituters": {
                "value": (
                    "https://user:secret@cache.internal.example/path?token=bad "
                    "https://cache.nixos.org"
                )
            },
        }
        with mock.patch.object(benchmark, "read_nix_config", return_value=raw):
            with mock.patch.object(benchmark, "capture", return_value="nix 2.test"):
                metadata = benchmark.nix_metadata(ROOT)
        encoded = json.dumps(metadata)
        self.assertNotIn("cache.internal.example", encoded)
        self.assertNotIn("secret", encoded)
        self.assertEqual(metadata["settings"]["substituters"]["count"], 2)
        self.assertEqual(len(metadata["settings"]["substituters"]["sha256"]), 64)

    def test_nix_metadata_unavailable_is_explicit(self) -> None:
        with mock.patch.object(benchmark, "read_nix_config", return_value=None):
            with mock.patch.object(benchmark, "capture", return_value=None):
                metadata = benchmark.nix_metadata(ROOT)
        self.assertIsNone(metadata["version"])
        self.assertFalse(metadata["settings"]["available"])
        self.assertIsNone(metadata["settings"]["max-jobs"])

    def test_main_propagates_benchmark_failure(self) -> None:
        samples = [benchmark.Sample("evaluate", 1, 0.1, 1)]
        stdout = io.StringIO()
        with mock.patch.object(benchmark, "benchmark_build", return_value=samples):
            with mock.patch.object(
                benchmark,
                "repository_metadata",
                return_value={"available": True, "revision": "abc", "dirty": False},
            ):
                with mock.patch.object(
                    benchmark,
                    "nix_metadata",
                    return_value={"version": "nix", "settings": {}},
                ):
                    with redirect_stdout(stdout):
                        exit_code = benchmark.main(["build", "--repeat", "1"])
        self.assertEqual(exit_code, 1)
        self.assertEqual(json.loads(stdout.getvalue())["samples"][0]["exit_code"], 1)

    def test_main_reports_output_file_failure_with_parseable_stdout(self) -> None:
        samples = [benchmark.Sample("evaluate", 1, 0.1, 0)]
        stdout = io.StringIO()
        with mock.patch.object(benchmark, "benchmark_build", return_value=samples):
            with mock.patch.object(
                benchmark,
                "repository_metadata",
                return_value={"available": True, "revision": "abc", "dirty": False},
            ):
                with mock.patch.object(
                    benchmark,
                    "nix_metadata",
                    return_value={"version": "nix", "settings": {}},
                ):
                    with mock.patch.object(
                        benchmark,
                        "atomic_write_json",
                        side_effect=OSError("denied"),
                    ):
                        with redirect_stdout(stdout):
                            exit_code = benchmark.main(
                                ["build", "--repeat", "1", "--json", "result.json"]
                            )
        self.assertEqual(exit_code, 73)
        self.assertEqual(json.loads(stdout.getvalue())["schema_version"], 2)

    def test_repository_metadata_unavailable_is_not_reported_clean(self) -> None:
        with mock.patch.object(
            benchmark,
            "capture_status",
            side_effect=[(False, None), (False, None)],
        ):
            metadata = benchmark.repository_metadata(ROOT)
        self.assertEqual(
            metadata,
            {"available": False, "revision": None, "dirty": None},
        )

    def test_repository_status_failure_does_not_claim_clean_tree(self) -> None:
        with mock.patch.object(
            benchmark,
            "capture_status",
            side_effect=[(True, "abc123"), (False, None)],
        ):
            metadata = benchmark.repository_metadata(ROOT)
        self.assertFalse(metadata["available"])
        self.assertEqual(metadata["revision"], "abc123")
        self.assertIsNone(metadata["dirty"])

    def test_activation_defaults_to_one_but_explicit_repeat_is_honored(self) -> None:
        args = benchmark.parse_args(["activate"])
        self.assertEqual(benchmark.effective_repeat(args), 1)
        args = benchmark.parse_args(["activate", "--repeat", "4"])
        self.assertEqual(benchmark.effective_repeat(args), 4)
        args = benchmark.parse_args(["build"])
        self.assertEqual(benchmark.effective_repeat(args), 3)

    def test_external_target_is_rejected_to_preserve_provenance(self) -> None:
        args = benchmark.parse_args(["build", "--target", "github:owner/repo#package"])
        repeat = benchmark.effective_repeat(args)
        self.assertIsNotNone(benchmark.validate_args(args, repeat))

    def test_repeat_bounds_fail_closed(self) -> None:
        args = benchmark.parse_args(["build", "--repeat", "0"])
        self.assertIn("between", benchmark.validate_args(args, 0))
        args = benchmark.parse_args(["build", "--repeat", "21"])
        self.assertIn("between", benchmark.validate_args(args, 21))

    def test_missing_activation_program_returns_failure_sample(self) -> None:
        evaluate_sample = benchmark.Sample("evaluate", 1, 0.1, 0)
        realize_sample = benchmark.Sample("realize", 1, 0.2, 0)
        with tempfile.TemporaryDirectory() as directory:
            output = str(Path(directory) / "missing-output")
            with mock.patch.object(
                benchmark,
                "evaluate_target",
                return_value=(evaluate_sample, "/nix/store/example.drv"),
            ):
                with mock.patch.object(
                    benchmark,
                    "realize_drv",
                    return_value=(realize_sample, [output]),
                ):
                    samples = benchmark.benchmark_activation(
                        benchmark.DEFAULT_TARGET,
                        1,
                        cwd=ROOT,
                    )
        self.assertEqual(samples[-1].phase, "activate")
        self.assertEqual(samples[-1].exit_code, 66)

    def test_atomic_json_write_failure_is_reported_without_corrupting_stdout(self) -> None:
        result = {"ok": True}
        payload = json.dumps(result) + "\n"
        with tempfile.TemporaryDirectory() as directory:
            parent_as_file = Path(directory) / "not-a-directory"
            parent_as_file.write_text("x", encoding="utf-8")
            with self.assertRaises(OSError):
                benchmark.atomic_write_json(parent_as_file / "result.json", payload)

    def test_main_emits_parseable_json_without_hostname_by_default(self) -> None:
        samples = [benchmark.Sample("evaluate", 1, 0.1, 0)]
        stdout = io.StringIO()
        with mock.patch.object(benchmark, "benchmark_build", return_value=samples):
            with mock.patch.object(
                benchmark,
                "repository_metadata",
                return_value={"available": True, "revision": "abc", "dirty": False},
            ):
                with mock.patch.object(
                    benchmark,
                    "nix_metadata",
                    return_value={"version": "nix", "settings": {}},
                ):
                    with redirect_stdout(stdout):
                        exit_code = benchmark.main(["build", "--repeat", "1"])
        self.assertEqual(exit_code, 0)
        parsed = json.loads(stdout.getvalue())
        self.assertNotIn("hostname", parsed["host"])
        self.assertEqual(parsed["schema_version"], 2)


if __name__ == "__main__":
    unittest.main()
