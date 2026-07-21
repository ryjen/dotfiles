import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
VERIFIER = ROOT / "scripts/verify-configctl-contracts.py"
PROFILE = ROOT / "files/home/.local/share/dubnium/obs/v1/profile"
COLLECTION = ROOT / "files/home/.local/share/dubnium/obs/v1/scene-collection.json"

CONTRACT = """\
schemaVersion = 1
id = "obs-presentation"
kind = "obs-presentation"
enabled = true
risk = ["mutable-user-state"]
profile = "workstation"
tags = ["obs", "meeting", "presentation"]
description = "Install the versioned Dubnium OBS presentation profile and scene collection."

templateProfile = "$XDG_DATA_HOME/dubnium/obs/v1/profile"
templateCollection = "$XDG_DATA_HOME/dubnium/obs/v1/scene-collection.json"
settings = "$XDG_CONFIG_HOME/dubnium/meeting/obs-init.json"
profileName = "Dubnium Presentation"
collectionName = "Dubnium Meeting Presentation"
profileTarget = "$XDG_CONFIG_HOME/obs-studio/basic/profiles/Dubnium Presentation"
collectionTarget = "$XDG_CONFIG_HOME/obs-studio/basic/scenes/Dubnium Meeting Presentation.json"

[behavior]
createIfMissing = true
replace = false
backupBeforeReplace = true
atomicWrite = true
refuseWhileObsRunning = true
"""


class ConfigctlObsContractVerifierTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        init_dir = self.root / "contracts/configctl/init"
        init_dir.mkdir(parents=True)
        self.contract = init_dir / "obs-presentation.toml"
        self.contract.write_text(CONTRACT, encoding="utf-8")
        destination = self.root / "files/home/.local/share/dubnium/obs/v1"
        destination.mkdir(parents=True)
        shutil.copytree(PROFILE, destination / "profile")
        shutil.copy2(COLLECTION, destination / "scene-collection.json")

    def tearDown(self) -> None:
        self.temp.cleanup()

    def verify(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["python3", str(VERIFIER), str(self.root)],
            text=True,
            capture_output=True,
            check=False,
        )

    def mutate_contract(self, old: str, new: str) -> None:
        source = self.contract.read_text(encoding="utf-8")
        self.assertIn(old, source)
        self.contract.write_text(source.replace(old, new), encoding="utf-8")

    def assert_contract_rejected(self, message: str) -> None:
        result = self.verify()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(message, result.stderr)

    def test_accepts_reviewed_executor_contract(self) -> None:
        result = self.verify()
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_requires_enabled_obs_presentation_contract(self) -> None:
        self.contract.unlink()
        self.assert_contract_rejected("missing required OBS presentation init contract")

    def test_rejects_destination_outside_fixed_obs_profile_path(self) -> None:
        self.mutate_contract(
            "$XDG_CONFIG_HOME/obs-studio/basic/profiles/Dubnium Presentation",
            "$XDG_CONFIG_HOME/obs-studio/basic/scenes/Dubnium Presentation",
        )
        self.assert_contract_rejected("profileTarget must be")

    def test_rejects_destination_outside_fixed_obs_scenes_path(self) -> None:
        self.mutate_contract(
            "$XDG_CONFIG_HOME/obs-studio/basic/scenes/Dubnium Meeting Presentation.json",
            "$XDG_CONFIG_HOME/obs-studio/basic/profiles/Dubnium Meeting Presentation.json",
        )
        self.assert_contract_rejected("collectionTarget must be")

    def test_rejects_missing_template_asset(self) -> None:
        (self.root / "files/home/.local/share/dubnium/obs/v1/scene-collection.json").unlink()
        self.assert_contract_rejected("referenced templateCollection does not exist")

    def test_rejects_camera_identifier_in_versioned_template(self) -> None:
        path = self.root / "files/home/.local/share/dubnium/obs/v1/scene-collection.json"
        collection = json.loads(path.read_text(encoding="utf-8"))
        camera = next(source for source in collection["sources"] if source["id"] == "v4l2_input")
        camera["settings"]["device_id"] = "/dev/v4l/by-id/committed-camera"
        path.write_text(json.dumps(collection), encoding="utf-8")
        self.assert_contract_rejected("camera settings must not contain device_id")

    def test_rejects_camera_identifier_in_unrelated_nested_source(self) -> None:
        path = self.root / "files/home/.local/share/dubnium/obs/v1/scene-collection.json"
        collection = json.loads(path.read_text(encoding="utf-8"))
        collection["sources"][0]["settings"]["nested"] = {
            "device_id": "/dev/v4l/by-id/committed-camera"
        }
        path.write_text(json.dumps(collection), encoding="utf-8")
        self.assert_contract_rejected("device_id keys are forbidden")

    def test_rejects_default_replacement(self) -> None:
        self.mutate_contract("replace = false", "replace = true")
        self.assert_contract_rejected("[behavior].replace must be false")

    def test_rejects_any_risk_list_other_than_exact_single_value(self) -> None:
        invalid_risks = (
            '["mutable-user-state", "mutable-user-state"]',
            '["mutable-user-state", "destructive"]',
            '["destructive", "mutable-user-state"]',
        )
        for risks in invalid_risks:
            with self.subTest(risks=risks):
                self.mutate_contract(
                    'risk = ["mutable-user-state"]',
                    f"risk = {risks}",
                )
                self.assert_contract_rejected('risk must be exactly ["mutable-user-state"]')
                self.mutate_contract(
                    f"risk = {risks}",
                    'risk = ["mutable-user-state"]',
                )

    def test_rejects_fields_not_consumed_by_reviewed_executor(self) -> None:
        self.mutate_contract(
            'settings = "$XDG_CONFIG_HOME/dubnium/meeting/obs-init.json"',
            'settings = "$XDG_CONFIG_HOME/dubnium/meeting/obs-init.json"\nlegacyName = "Dubnium Presentation"',
        )
        self.assert_contract_rejected("unsupported obs-presentation fields: legacyName")

    def test_rejects_missing_explicit_names(self) -> None:
        expected_names = {
            "profileName": "Dubnium Presentation",
            "collectionName": "Dubnium Meeting Presentation",
        }
        for field, expected in expected_names.items():
            with self.subTest(field=field):
                line = f'{field} = "{expected}"\n'
                self.mutate_contract(line, "")
                self.assert_contract_rejected(f"missing required field '{field}'")
                self.mutate_contract("[behavior]", f'{field} = "{expected}"\n\n[behavior]')

    def test_rejects_mismatched_or_empty_explicit_names(self) -> None:
        expected_names = {
            "profileName": "Dubnium Presentation",
            "collectionName": "Dubnium Meeting Presentation",
        }
        for field, expected in expected_names.items():
            for value in ("Wrong Name", ""):
                with self.subTest(field=field, value=value):
                    self.mutate_contract(
                        f'{field} = "{expected}"',
                        f'{field} = "{value}"',
                    )
                    self.assert_contract_rejected(f"{field} must be '{expected}'")
                    self.mutate_contract(
                        f'{field} = "{value}"',
                        f'{field} = "{expected}"',
                    )

    def test_rejects_non_reviewed_behavior(self) -> None:
        for field, expected in (
            ("createIfMissing", "true"),
            ("backupBeforeReplace", "true"),
            ("atomicWrite", "true"),
            ("refuseWhileObsRunning", "true"),
        ):
            with self.subTest(field=field):
                self.mutate_contract(f"{field} = {expected}", f"{field} = false")
                self.assert_contract_rejected(f"[behavior].{field} must be true")
                self.mutate_contract(f"{field} = false", f"{field} = {expected}")


if __name__ == "__main__":
    unittest.main()
