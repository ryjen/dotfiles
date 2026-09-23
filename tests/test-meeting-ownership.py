from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
MEETING = ROOT / "modules/home/meeting.nix"
BROWSER = ROOT / "modules/home/browser.nix"
PROFILE = ROOT / "home/ryjen/profiles/workstation.nix"


class MeetingOwnershipTest(unittest.TestCase):
    def test_packages_and_phone_helper_are_outside_meeting_ux_gate(self):
        source = MEETING.read_text()
        outside, gated = source.split("config = lib.mkMerge [", 1)[1].split("(lib.mkIf cfg.enable {", 1)
        self.assertIn("lib.optionals cfg.zoom.enable [ pkgs.zoom-us ]", outside)
        for package in ("pkgs.android-tools", "pkgs.scrcpy", "pkgs.v4l-utils"):
            self.assertIn(package, outside)
        self.assertIn('home.file.".local/bin/dubctl-phone-camera"', outside)
        self.assertNotIn("pkgs.zoom-us", gated)
        self.assertNotIn("pkgs.scrcpy", gated)

    def test_zoom_and_teams_rules_are_independently_gated(self):
        source = MEETING.read_text()
        self.assertIn("zoom.enable = lib.mkEnableOption", source)
        self.assertIn("default = false;", source)
        self.assertIn("teams.enable = lib.mkEnableOption", source)
        self.assertIn("lib.optionalString cfg.zoom.enable", source)
        self.assertIn("lib.optionalString cfg.teams.enable", source)
        self.assertNotIn("pkgs.chromium", source)

    def test_browser_owns_chromium_and_workstation_defaults_are_explicit(self):
        self.assertIn("pkgs.chromium", BROWSER.read_text())
        profile = PROFILE.read_text()
        self.assertIn("zoom.enable = lib.mkDefault true;", profile)
        self.assertIn("teams.enable = lib.mkDefault true;", profile)

    def test_phone_camera_is_a_path_extension_not_meeting_session_command(self):
        source = MEETING.read_text()
        self.assertIn('source = ../../files/home/.local/bin/dubctl-phone-camera;', source)
        self.assertFalse((ROOT / "files/home/.local/bin/dub-phone-camera").exists())
        self.assertTrue((ROOT / "files/home/.local/bin/dubctl-phone-camera").exists())


if __name__ == "__main__":
    unittest.main()
