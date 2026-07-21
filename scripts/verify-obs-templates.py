#!/usr/bin/env python3
"""Semantically verify that the checked-in OBS templates are portable and safe."""

from __future__ import annotations

import configparser
import json
import re
import sys
from pathlib import Path
from typing import Any


PROFILE_VALUES = {
    "General": {"Name": "Dubnium Presentation"},
    "Video": {
        "BaseCX": "1920",
        "BaseCY": "1080",
        "OutputCX": "1920",
        "OutputCY": "1080",
        "FPSType": "0",
        "FPSCommon": "30",
    },
}
COLLECTION_NAME = "Dubnium Meeting Presentation"
SCENE_NAMES = ["Code Only", "Code + Camera"]
FORBIDDEN_SOURCE_ID_PARTS = ("audio", "browser", "ffmpeg", "media")
URI_SCHEME = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:")
FORBIDDEN_TEXT = (
    "/dev/video",
    "/home/",
    "/users/",
    "portal_restore_token",
    "restore_token",
    "output_path",
    "recording",
    "stream_key",
    "streamkey",
    "startstreaming",
    "startrecording",
    "startreplaybuffer",
    "startvirtualcam",
)


def fail(message: str) -> None:
    raise ValueError(message)


def load_profile(path: Path) -> None:
    parser = configparser.ConfigParser(interpolation=None)
    parser.optionxform = str
    with path.open(encoding="utf-8") as profile_file:
        parser.read_file(profile_file)

    if parser.sections() != list(PROFILE_VALUES):
        fail(f"profile sections must be exactly {list(PROFILE_VALUES)}")
    for section, expected in PROFILE_VALUES.items():
        if dict(parser.items(section)) != expected:
            fail(f"profile section {section} does not match the portable contract")


def shortcut(number: int) -> list[dict[str, Any]]:
    return [
        {
            "alt": True,
            "control": True,
            "key": f"OBS_KEY_{number}",
            "shift": False,
        }
    ]


def strings_in(value: Any):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for key, nested in value.items():
            yield from strings_in(key)
            yield from strings_in(nested)
    elif isinstance(value, list):
        for nested in value:
            yield from strings_in(nested)


def verify_collection(collection: dict[str, Any]) -> None:
    if collection.get("name") != COLLECTION_NAME:
        fail(f"scene collection name must be {COLLECTION_NAME}")

    if collection.get("saved_projectors") != []:
        fail("saved_projectors must be empty")

    scene_order = [scene.get("name") for scene in collection.get("scene_order", [])]
    if scene_order != SCENE_NAMES:
        fail(f"scenes must be exactly {SCENE_NAMES}")

    sources = collection.get("sources")
    if not isinstance(sources, list):
        fail("sources must be a list")

    source_ids = [source.get("id") for source in sources]
    if source_ids != ["pipewire-screen-capture-source", "v4l2_input", "scene", "scene"]:
        fail("sources must contain only one PipeWire source, one camera, and the two scenes")
    for source in sources:
        for field in ("id", "versioned_id"):
            source_id = source.get(field)
            if not isinstance(source_id, str):
                fail(f"source {field} must be a string")
            if any(part in source_id.lower() for part in FORBIDDEN_SOURCE_ID_PARTS):
                fail(f"forbidden source {field}: {source_id}")

    for value in strings_in(collection):
        if URI_SCHEME.match(value.lstrip()):
            fail(f"URI schemes are forbidden in scene collection data: {value}")

    pipewire = [source for source in sources if source.get("id") == "pipewire-screen-capture-source"]
    cameras = [source for source in sources if source.get("id") == "v4l2_input"]
    scenes = [source for source in sources if source.get("id") == "scene"]
    if len(pipewire) != 1:
        fail("exactly one shared PipeWire source is required")
    if len(cameras) != 1 or cameras[0].get("name") != "Camera Overlay":
        fail("exactly one Camera Overlay v4l2_input source is required")
    if cameras[0].get("settings") != {}:
        fail("camera settings must be empty")
    if [scene.get("name") for scene in scenes] != SCENE_NAMES:
        fail(f"scene sources must be exactly {SCENE_NAMES}")

    screen_uuid = pipewire[0].get("uuid")
    camera_uuid = cameras[0].get("uuid")
    if (
        not isinstance(screen_uuid, str)
        or not screen_uuid
        or not isinstance(camera_uuid, str)
        or not camera_uuid
        or screen_uuid == camera_uuid
    ):
        fail("PipeWire and camera UUIDs must be nonempty distinct strings")
    expected_items = {
        "Code Only": [("Screen Capture", screen_uuid)],
        "Code + Camera": [("Screen Capture", screen_uuid), ("Camera Overlay", camera_uuid)],
    }
    for scene in scenes:
        items = scene.get("settings", {}).get("items", [])
        actual_items = [(item.get("name"), item.get("source_uuid")) for item in items]
        if actual_items != expected_items[scene["name"]]:
            fail(f"unexpected scene items in {scene.get('name')}")
        for item in items:
            if item.get("source_uuid") in (screen_uuid, camera_uuid) and item.get("visible") is not False:
                fail(f"capture item {item.get('name')} in {scene.get('name')} must start hidden")

    if scenes[0].get("hotkeys", {}).get("OBSBasic.SelectScene") != shortcut(1):
        fail("Code Only must use CTRL+ALT+1")
    if scenes[1].get("hotkeys", {}).get("OBSBasic.SelectScene") != shortcut(2):
        fail("Code + Camera must use CTRL+ALT+2")
    camera_item = scenes[1]["settings"]["items"][1]
    camera_item_id = camera_item.get("id")
    if isinstance(camera_item_id, bool) or not isinstance(camera_item_id, (int, str)) or str(camera_item_id) == "":
        fail("Camera Overlay must have a scene-item ID")
    expected_camera_hotkeys = {
        f"libobs.hide_scene_item.{camera_item_id}": shortcut(3),
        f"libobs.show_scene_item.{camera_item_id}": shortcut(3),
    }
    camera_hotkeys = scenes[1].get("hotkeys", {})
    item_hotkeys = {
        name: bindings
        for name, bindings in camera_hotkeys.items()
        if name.startswith(("libobs.show_scene_item.", "libobs.hide_scene_item."))
    }
    if item_hotkeys != expected_camera_hotkeys:
        fail("Camera Overlay show/hide hotkeys must target its item ID with CTRL+ALT+3")

    for source in sources:
        for name, bindings in source.get("hotkeys", {}).items():
            for binding in bindings if isinstance(bindings, list) else []:
                if isinstance(binding, dict) and binding.get("key") == "OBS_KEY_3":
                    if source is not scenes[1] or name not in expected_camera_hotkeys:
                        fail("public key 3 may control only the Code + Camera camera item")

    serialized = json.dumps(collection, sort_keys=True).lower()
    if re.search(r"[a-z]:\\\\users\\\\", serialized):
        fail("absolute Windows home paths are forbidden")
    if re.search(r'/(?:root|var/home)/|["/]~/', serialized):
        fail("private home paths are forbidden")
    if "token" in serialized:
        fail("tokens are forbidden")
    for forbidden in FORBIDDEN_TEXT:
        if forbidden in serialized:
            fail(f"forbidden portable-template value: {forbidden}")


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    template_root = root / "files/home/.local/share/dubnium/obs/v1"
    profile_path = template_root / "profile/basic.ini"
    collection_path = template_root / "scene-collection.json"

    try:
        load_profile(profile_path)
        with collection_path.open(encoding="utf-8") as collection_file:
            collection = json.load(collection_file)
        if not isinstance(collection, dict):
            fail("scene collection root must be an object")
        verify_collection(collection)
    except (OSError, configparser.Error, json.JSONDecodeError, ValueError) as error:
        print(f"OBS template verification failed: {error}", file=sys.stderr)
        return 1

    print("OBS templates satisfy the portable contract")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
