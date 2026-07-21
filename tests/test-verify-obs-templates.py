import copy
import importlib.util
import json
from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
COLLECTION_PATH = ROOT / "files/home/.local/share/dubnium/obs/v1/scene-collection.json"
VERIFIER_PATH = ROOT / "scripts/verify-obs-templates.py"

spec = importlib.util.spec_from_file_location("verify_obs_templates", VERIFIER_PATH)
assert spec and spec.loader
verifier = importlib.util.module_from_spec(spec)
sys.dont_write_bytecode = True
spec.loader.exec_module(verifier)


class ObsTemplateVerifierTest(unittest.TestCase):
    def setUp(self) -> None:
        self.collection = json.loads(COLLECTION_PATH.read_text())

    def assert_rejected(self, mutate) -> None:
        collection = copy.deepcopy(self.collection)
        mutate(collection)
        with self.assertRaises(ValueError):
            verifier.verify_collection(collection)

    def test_rejects_general_uri_scheme_in_nested_settings(self) -> None:
        self.assert_rejected(
            lambda collection: collection["sources"][0]["settings"].update(
                {"selection": "custom+obs:private-target"}
            )
        )

    def test_rejects_url_in_top_level_collection_data(self) -> None:
        self.assert_rejected(
            lambda collection: collection.update({"external_state": "ssh://private-host/session"})
        )

    def test_rejects_url_used_as_dictionary_key(self) -> None:
        self.assert_rejected(
            lambda collection: collection.update({"custom+obs:private-state": {}})
        )

    def test_rejects_wrong_collection_name(self) -> None:
        self.assert_rejected(
            lambda collection: collection.update({"name": "Dubnium Presentation"})
        )

    def test_rejects_forbidden_current_and_versioned_source_ids(self) -> None:
        for field in ("id", "versioned_id"):
            with self.subTest(field=field):
                self.assert_rejected(
                    lambda collection, field=field: collection["sources"][0].update(
                        {field: "browser_source"}
                    )
                )

    def test_rejects_capture_item_reference_that_does_not_resolve(self) -> None:
        self.assert_rejected(
            lambda collection: collection["sources"][3]["settings"]["items"][1].update(
                {"source_uuid": "missing-camera-source"}
            )
        )

    def test_rejects_empty_capture_uuid_even_when_items_match(self) -> None:
        def mutate(collection) -> None:
            old_uuid = collection["sources"][0]["uuid"]
            collection["sources"][0]["uuid"] = ""
            for scene in collection["sources"][2:]:
                for item in scene["settings"]["items"]:
                    if item["source_uuid"] == old_uuid:
                        item["source_uuid"] = ""

        self.assert_rejected(mutate)

    def test_rejects_shared_capture_uuid_even_when_items_match(self) -> None:
        def mutate(collection) -> None:
            screen_uuid = collection["sources"][0]["uuid"]
            camera_uuid = collection["sources"][1]["uuid"]
            collection["sources"][1]["uuid"] = screen_uuid
            for item in collection["sources"][3]["settings"]["items"]:
                if item["source_uuid"] == camera_uuid:
                    item["source_uuid"] = screen_uuid

        self.assert_rejected(mutate)

    def test_rejects_camera_hotkey_for_wrong_scene_item(self) -> None:
        def mutate(collection) -> None:
            hotkeys = collection["sources"][3]["hotkeys"]
            hotkeys["libobs.show_scene_item.1"] = hotkeys.pop("libobs.show_scene_item.2")

        self.assert_rejected(mutate)

    def test_rejects_public_key_three_on_another_item(self) -> None:
        self.assert_rejected(
            lambda collection: collection["sources"][2]["hotkeys"].update(
                {"libobs.show_scene_item.1": verifier.shortcut(3)}
            )
        )

    def test_accepts_portable_obs_identifiers(self) -> None:
        verifier.verify_collection(self.collection)


if __name__ == "__main__":
    unittest.main()
