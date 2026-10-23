from pathlib import Path
import os
import subprocess
import tempfile
import textwrap
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "files/home/.local/bin/dubctl-phone-camera"
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
        self.assertIn("dubctl-phone-camera", source)
        self.assertNotIn("dub-phone-camera", source)

    def test_user_example_catalogs_phone_camera_toggle(self) -> None:
        self.assertIn(
            "dotfiles.meeting.phoneCamera.enable = true;",
            USER_EXAMPLE.read_text(),
        )

    def test_helper_prefers_usb_camera_without_audio_capture(self) -> None:
        source = SCRIPT.read_text()
        self.assertIn("--select-usb", source)
        self.assertIn("--video-source=camera", source)
        self.assertIn("--camera-facing=", source)
        self.assertIn("--v4l2-sink=", source)
        self.assertIn("--no-audio", source)
        self.assertIn("--no-playback", source)
        self.assertNotIn("--select-tcpip", source)

    def test_helper_uses_bounded_adaptive_camera_size(self) -> None:
        source = SCRIPT.read_text()
        self.assertIn("DUBNIUM_PHONE_CAMERA_MAX_SIZE", source)
        self.assertIn("--max-size=", source)
        self.assertNotIn("--camera-size=", source)

    def test_helper_prefers_verified_stable_host_contract_before_sysfs_fallback(self) -> None:
        source = SCRIPT.read_text()
        function = source.split("find_loopback_device() {", 1)[1].split("\n}\n\nlist_devices()", 1)[0]
        override = function.index("DUBNIUM_PHONE_CAMERA_DEVICE")
        stable = function.index('local stable_device="/dev/dubnium-camera"')
        verification = function.index('/sys/class/video4linux/$resolved_name/format')
        sysfs_fallback = function.index("for sysdev in /sys/class/video4linux/video*")
        self.assertLess(override, stable)
        self.assertLess(stable, verification)
        self.assertLess(verification, sysfs_fallback)
        self.assertIn('readlink -f -- "$stable_device"', function)

    def test_helper_uses_v4l2loopback_sysfs_interface_for_discovery(self) -> None:
        source = SCRIPT.read_text()
        self.assertIn("/sys/class/video4linux/video*", source)
        self.assertIn('[[ -e "$sysdev/format" ]]', source)
        self.assertNotIn("device/driver/module", source)

    def test_helper_documents_native_uvc_path(self) -> None:
        result = run_helper("--help")
        self.assertIn("Native Android USB webcam mode", result.stdout)
        self.assertIn("Webcam", result.stdout)
        self.assertIn("v4l2loopback", result.stdout)
        self.assertIn("/dev/dubnium-camera", result.stdout)
        self.assertIn("dubnium.videoMeeting.virtualCamera.enable", result.stdout)
        self.assertNotIn("dubnium.camera.virtual.enable", SCRIPT.read_text())

    def test_helper_has_stable_version_surface(self) -> None:
        result = run_helper("--version")
        self.assertEqual(result.stdout, "dubctl-phone-camera 3\n")


class PhoneCameraCapturePathTest(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        base = Path(tmp.name)
        self.bin_dir = base / "bin"
        self.bin_dir.mkdir()
        self.sink = base / "video99"
        self.sink.write_text("")
        self.scrcpy_args = base / "scrcpy-args"

        stub_scrcpy = textwrap.dedent(
            """\
            #!/usr/bin/env bash
            printf '%s\\n' "$@" > "$CAPTURE_ARGS_FILE"
            exit 0
            """
        )
        stub_adb = textwrap.dedent(
            """\
            #!/usr/bin/env bash
            if [ "$1 $2 $3 $4" = "-d shell getprop ro.build.version.sdk" ]; then
              if [ -n "${FAKE_ADB_FAIL-}" ]; then
                printf 'fake adb failure\\n' >&2
                exit 1
              fi
              printf '%s\\n' "$FAKE_SDK"
              exit 0
            fi
            printf 'unexpected adb argv: %s\\n' "$*" >&2
            exit 2
            """
        )
        (self.bin_dir / "scrcpy").write_text(stub_scrcpy)
        (self.bin_dir / "adb").write_text(stub_adb)
        for stub in (self.bin_dir / "scrcpy", self.bin_dir / "adb"):
            stub.chmod(0o755)

    def run_capture_request(self, facing: str, env_extra: dict[str, str]) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        env["PATH"] = f"{self.bin_dir}{os.pathsep}{env['PATH']}"
        env.update(env_extra)
        env["DUBNIUM_PHONE_CAMERA_DEVICE"] = str(self.sink)
        env["CAPTURE_ARGS_FILE"] = str(self.scrcpy_args)
        return subprocess.run(
            ["bash", str(SCRIPT), facing],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
            env=env,
        )

    def test_back_mirrors_display_below_android_twelve(self) -> None:
        result = self.run_capture_request("back", {"FAKE_SDK": "30"})
        self.assertIn("Android 12", result.stderr)
        self.assertIn("Mirroring the Android display", result.stderr)
        args = self.scrcpy_args.read_text()
        self.assertIn("--video-source=display", args)
        self.assertIn(f"--v4l2-sink={self.sink}", args)
        self.assertIn("--select-usb", args)
        self.assertIn("--no-audio", args)
        self.assertIn("--no-playback", args)
        self.assertNotIn("--video-source=camera", args)
        self.assertNotIn("--camera-facing=", args)

    def test_front_captures_camera_on_android_twelve_and_up(self) -> None:
        result = self.run_capture_request("front", {"FAKE_SDK": "34"})
        self.assertEqual(result.stderr, "")
        args = self.scrcpy_args.read_text()
        self.assertIn("--video-source=camera", args)
        self.assertIn("--camera-facing=front", args)
        self.assertIn(f"--v4l2-sink={self.sink}", args)
        self.assertNotIn("--video-source=display", args)

    def test_unknown_android_version_keeps_camera_fallback_status_quo(self) -> None:
        result = self.run_capture_request("back", {"FAKE_ADB_FAIL": "1"})
        self.assertEqual(result.stderr, "")
        args = self.scrcpy_args.read_text()
        self.assertIn("--video-source=camera", args)
        self.assertIn("--camera-facing=back", args)


if __name__ == "__main__":
    unittest.main()
