from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "files/home/.local/bin/dub-phone-camera"
MODULE = ROOT / "modules/home/meeting.nix"
USER_EXAMPLE = ROOT / "home/ryjen/user.example.nix"


def run_helper(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", str(SCRIPT), *args],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )


class PhoneCameraTest(unittest.TestCase):
    def test_meeting_module_installs_phone_camera_tooling(self) -> None:
        source = MODULE.read_text()
        self.assertIn("phoneCamera.enable", source)
        self.assertIn("pkgs.android-tools", source)
        self.assertIn("pkgs.scrcpy", source)
        self.assertIn("pkgs.v4l-utils", source)
        self.assertIn("dub-phone-camera", source)

    def test_user_example_catalogs_phone_camera_toggle(self) -> None:
        self.assertIn(
            "dotfiles.meeting.phoneCamera.enable = true;",
            USER_EXAMPLE.read_text(),
        )

    def test_helper_prefers_usb_and_camera_source(self) -> None:
        source = SCRIPT.read_text()
        self.assertIn("--select-usb", source)
        self.assertIn("--video-source=camera", source)
        self.assertIn("--camera-facing=", source)
        self.assertIn("--v4l2-sink=", source)
        self.assertIn("--no-playback", source)
        self.assertNotIn("--select-tcpip", source)

    def test_helper_documents_native_uvc_path(self) -> None:
        result = run_helper("--help")
        self.assertIn("Native Android USB webcam mode", result.stdout)
        self.assertIn("Webcam", result.stdout)
        self.assertIn("v4l2loopback", result.stdout)

    def test_helper_has_stable_version_surface(self) -> None:
        result = run_helper("--version")
        self.assertEqual(result.stdout, "dub-phone-camera 1\n")


if __name__ == "__main__":
    unittest.main()
