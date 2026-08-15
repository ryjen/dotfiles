import json
from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]


def eval_waybar(profile: str) -> list[dict[str, object]]:
    attr = (
        f'path:{ROOT}#homeConfigurations."ryjen@{profile}".config.xdg.configFile.'
        '"waybar/config.jsonc".text'
    )
    result = subprocess.run(
        ["nix", "eval", "--raw", attr],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    rendered = json.loads(result.stdout)
    if not isinstance(rendered, list):
        raise AssertionError("Waybar configuration must be a JSON array")
    return rendered


def eval_presentation_output(value: str) -> subprocess.CompletedProcess[str]:
    expression = f'''
      let
        flake = builtins.getFlake "path:{ROOT}";
        pkgs = import flake.inputs.nixpkgs {{ system = "x86_64-linux"; }};
        evaluated = flake.inputs.home-manager.lib.homeManagerConfiguration {{
          inherit pkgs;
          modules = [
            {ROOT}/modules/home/meeting.nix
            {{
              dotfiles.meeting.presentationOutput = {json.dumps(value)};
              home.username = "test";
              home.homeDirectory = "/home/test";
              home.stateVersion = "25.05";
            }}
          ];
        }};
      in evaluated.config.dotfiles.meeting.presentationOutput
    '''
    return subprocess.run(
        ["nix", "eval", "--impure", "--raw", "--expr", expression],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )


class MeetingConfigTest(unittest.TestCase):
    def test_presentation_output_accepts_drm_connector_names(self) -> None:
        for output in ("DP-1", "HDMI-A-1", "eDP-1", "DP-1-1"):
            with self.subTest(output=output):
                result = eval_presentation_output(output)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, output)

    def test_presentation_output_rejects_unsafe_values(self) -> None:
        invalid = (
            "",
            "DP 1",
            "DP\t1",
            "DP,1",
            "DP:1",
            "*",
            "DP-*",
            "DP-?",
            "!DP-1",
            "DP-1;exec",
            "DP-1$(id)",
            "DP-1/../../x",
            "DP_1",
        )
        for output in invalid:
            with self.subTest(output=output):
                result = eval_presentation_output(output)
                self.assertNotEqual(result.returncode, 0, output)

    def test_module_is_registered_and_enabled_by_workstation(self) -> None:
        registry = (ROOT / "modules/home/default.nix").read_text()
        profile = (ROOT / "home/ryjen/profiles/workstation.nix").read_text()
        self.assertIn("./meeting.nix", registry)
        self.assertIn("dotfiles.meeting.enable = lib.mkDefault true;", profile)

    def test_hypr_source_order(self) -> None:
        source = (ROOT / "modules/home/hypr.nix").read_text()
        adopted = source.index("${managedHyprConfig}")
        meeting = source.index("custom.d/meeting.conf")
        local = source.index("/hypr/local.conf", meeting)
        custom = source.index("custom.d/*.conf", local)
        self.assertLess(adopted, meeting)
        self.assertLess(meeting, local)
        self.assertLess(local, custom)

    def test_super_p_is_reserved_for_presentation(self) -> None:
        for name in ("dubnium.conf", "technetium.conf"):
            source = (ROOT / "files/home/.config/hypr/adopted.d" / name).read_text()
            self.assertNotIn("bind = $mainMod, code:33, pseudo,", source)
            self.assertIn("bind = $mainMod CTRL, code:33, pseudo,", source)

    def test_obs_helper_path_is_shell_escaped_for_hyprland_exec(self) -> None:
        source = (ROOT / "modules/home/meeting.nix").read_text()
        self.assertIn(
            'obsHotkeyHelper = lib.escapeShellArg "${config.home.homeDirectory}/.local/bin/dub-obs-hotkey";',
            source,
        )
        for action in ("code-only", "code-camera", "camera-toggle"):
            self.assertIn(f"exec, ${{obsHotkeyHelper}} {action}", source)

    def test_meeting_verify_waybar_is_structurally_private(self) -> None:
        bars = eval_waybar("meeting-verify")
        self.assertEqual(len(bars), 2)
        self.assertEqual(bars[0]["output"], ["!DP-1", "*"])
        self.assertEqual(bars[1]["output"], "DP-1")
        self.assertEqual(bars[1].get("modules-left"), ["hyprland/workspaces#presentation"])
        self.assertEqual(bars[1].get("modules-center"), [])
        self.assertEqual(bars[1].get("modules-right"), ["custom/meeting#presentation"])

        approved = {
            "hyprland/workspaces#presentation",
            "custom/meeting#presentation",
        }
        modules = {
            module
            for key in ("modules-left", "modules-center", "modules-right")
            for module in bars[1].get(key, [])
        }
        self.assertEqual(modules, approved)
        forbidden = (
            "window",
            "media",
            "music",
            "clock",
            "cpu",
            "memory",
            "temperature",
            "tray",
            "audio",
            "pulse",
            "wireplumber",
        )
        self.assertFalse(any(term in module for term in forbidden for module in modules))
        self.assertEqual(
            bars[1]["hyprland/workspaces#presentation"],
            {
                "active-only": True,
                "all-outputs": False,
                "disable-click": True,
                "disable-scroll": True,
                "format": "Presentation",
                "tooltip": False,
            },
        )
        self.assertNotIn("on-click", bars[1]["hyprland/workspaces#presentation"])
        self.assertFalse(bars[1]["custom/meeting#presentation"]["tooltip"])
        self.assertNotIn("on-click", bars[1]["custom/meeting#presentation"])

    def test_null_output_is_non_matching_for_both_variants(self) -> None:
        workstation = eval_waybar("dubnium")
        laptop = eval_waybar("technetium")

        for bars in (workstation, laptop):
            self.assertEqual(len(bars), 2)
            self.assertEqual(bars[0]["output"], ["*"])
            self.assertEqual(bars[1]["output"], "DUBNIUM/NO-PRESENTATION-OUTPUT")
            self.assertEqual(
                bars[1]["hyprland/workspaces#presentation"],
                {
                    "active-only": True,
                    "all-outputs": False,
                    "disable-click": True,
                    "disable-scroll": True,
                    "format": "Presentation",
                    "tooltip": False,
                },
            )
        self.assertNotIn("custom/backlight", workstation[0]["modules-right"])
        self.assertIn("custom/backlight", laptop[0]["modules-right"])

    def test_meeting_session_script_is_not_a_dubctl_extension(self) -> None:
        script = ROOT / "files/home/.local/bin/dub-meeting-session"
        self.assertTrue(script.exists(), "dub-meeting-session script must exist")
        self.assertFalse((ROOT / "files/home/.local/bin/dubctl-meeting").exists())
        self.assertFalse((ROOT / "files/home/.local/bin/dubctl-meeting-session").exists())
        content = script.read_text()
        self.assertIn("--help", content)
        self.assertIn("--version", content)
        self.assertIn("start", content)
        self.assertIn("stop", content)
        self.assertIn("status", content)
        self.assertIn("dubnium-meeting-mode", content)
        self.assertNotIn("dubctl meeting", content)

    def test_meeting_nix_installs_non_dubctl_session_helper(self) -> None:
        source = (ROOT / "modules/home/meeting.nix").read_text()
        self.assertIn("dub-meeting-session", source)
        self.assertNotIn("dubctl-meeting", source)
        self.assertIn("dubnium-meeting-mode", source)


if __name__ == "__main__":
    unittest.main()
