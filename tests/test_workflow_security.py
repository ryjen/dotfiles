from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).resolve().parents[1] / "checks" / "verify-workflow-security.py"
SPEC = importlib.util.spec_from_file_location("workflow_security", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
workflow_security = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(workflow_security)

PINNED_CHECKOUT = "actions/checkout@11d5960a326750d5838078e36cf38b85af677262"


def workflow_text(
    *,
    action: str = PINNED_CHECKOUT,
    persist_credentials: bool = True,
    timeout: bool = True,
    job_permissions: str = "",
    trigger: str = "pull_request:",
    uses_key: str = "uses:",
) -> str:
    persist = "\n        with:\n          persist-credentials: false" if persist_credentials else ""
    timeout_line = "\n    timeout-minutes: 5" if timeout else ""
    permissions = f"\n    permissions:\n      {job_permissions}" if job_permissions else ""
    return f"""name: test

on:
  {trigger}

permissions:
  contents: read

jobs:
  verify:
    runs-on: ubuntu-latest{timeout_line}{permissions}
    steps:
      - name: Checkout
        {uses_key} {action}{persist}
      - name: Verify
        run: echo ok
"""


class WorkflowSecurityTests(unittest.TestCase):
    def validate(self, text: str) -> list[str]:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            workflow_dir = root / ".github" / "workflows"
            workflow_dir.mkdir(parents=True)
            workflow = workflow_dir / "test.yml"
            workflow.write_text(text, encoding="utf-8")
            return workflow_security.validate_workflow(workflow, root)

    def test_accepts_pinned_read_only_workflow(self) -> None:
        self.assertEqual([], self.validate(workflow_text()))

    def test_accepts_spacing_around_uses_colon(self) -> None:
        self.assertEqual([], self.validate(workflow_text(uses_key="uses :")))

    def test_rejects_mutable_action(self) -> None:
        errors = self.validate(workflow_text(action="actions/checkout@v4"))
        self.assertTrue(any("mutable action reference" in error for error in errors))

    def test_rejects_mutable_action_with_spacing_around_uses_colon(self) -> None:
        errors = self.validate(workflow_text(action="actions/checkout@v4", uses_key="uses :"))
        self.assertTrue(any("mutable action reference" in error for error in errors))

    def test_rejects_checkout_credential_persistence(self) -> None:
        errors = self.validate(workflow_text(persist_credentials=False))
        self.assertTrue(any("persist-credentials" in error for error in errors))

    def test_rejects_missing_timeout(self) -> None:
        errors = self.validate(workflow_text(timeout=False))
        self.assertTrue(any("timeout-minutes" in error for error in errors))

    def test_rejects_job_write_permission(self) -> None:
        errors = self.validate(workflow_text(job_permissions="contents: write"))
        self.assertTrue(any("must not override" in error for error in errors))

    def test_rejects_scalar_job_permissions(self) -> None:
        text = workflow_text().replace(
            "    runs-on: ubuntu-latest\n",
            "    runs-on: ubuntu-latest\n    permissions: write-all\n",
        )
        errors = self.validate(text)
        self.assertTrue(any("must not override" in error for error in errors))

    def test_rejects_inline_job_permissions(self) -> None:
        text = workflow_text().replace(
            "    runs-on: ubuntu-latest\n",
            "    runs-on: ubuntu-latest\n    permissions: { contents: write }\n",
        )
        errors = self.validate(text)
        self.assertTrue(any("must not override" in error for error in errors))

    def test_rejects_pull_request_target(self) -> None:
        errors = self.validate(workflow_text(trigger="pull_request_target:"))
        self.assertTrue(any("pull_request_target" in error for error in errors))

    def test_rejects_flow_style_trigger_mapping(self) -> None:
        text = workflow_text().replace("on:\n  pull_request:\n", "on: [pull_request_target]\n")
        errors = self.validate(text)
        self.assertTrue(any("block mapping syntax" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
