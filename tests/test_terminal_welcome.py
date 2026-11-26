"""Exercise the real Zsh welcome with a non-root PTY and isolated commands."""
import os
import shlex
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ZSH = shutil.which("zsh")
SOURCE = ROOT / "files/home/.config/zsh/welcome.zsh"
MOTD = ROOT / "files/system/motd"
ART = MOTD.with_name("motd.d")
DRIVER = 'source "$WELCOME_SOURCE" "$WELCOME_MOTD" "$WELCOME_ART" "$WELCOME_PROFILE" "$WELCOME_SED" "$WELCOME_DATE"'
VARS = (
    "CI", "SSH_CONNECTION", "SSH_TTY", "SSH_CLIENT", "DOTFILES_WELCOME",
    "DOTFILES_WELCOME_SHOWN", "DOTFILES_MOTD", "NO_COLOR",
)


class WelcomeTests(unittest.TestCase):
    def setUp(self):
        self.assertIsNotNone(ZSH, "Zsh must be available")
        self.assertNotEqual(os.geteuid(), 0, "Run as a non-root test user")
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        root = Path(self.tmp.name)
        self.bin = root / "bin"
        self.bin.mkdir()
        self.minimal = root / "minimal"
        self.minimal.mkdir()
        for directory in (self.bin, self.minimal):
            (directory / "cat").symlink_to(shutil.which("cat"))
        scripts = {
            "fortune": 'printf "FORTUNE_MARKER\n"',
            "cowsay": 'printf "COW_MARKER\n"; cat',
            "lolcat": 'printf "RAINBOW_MARKER\n"; cat',
            "task": 'printf "TASK_MARKER %s\n" "$*"',
        }
        for name, body in scripts.items():
            path = self.bin / name
            path.write_text("#!/bin/sh\n" + body + "\n")
            path.chmod(0o755)
        self.env = dict(os.environ)
        for key in VARS:
            self.env.pop(key, None)
        self.env.update(
            PATH=str(self.bin), TERM="xterm-256color", HOME=str(root),
            ZDOTDIR=str(root), WELCOME_SOURCE=str(SOURCE), WELCOME_MOTD=str(MOTD),
            WELCOME_ART=str(ART), WELCOME_PROFILE="dubnium",
            WELCOME_SED=shutil.which("sed"), WELCOME_DATE=shutil.which("date"),
            WELCOME_ZSH=ZSH,
        )

    def invoke(self, *, interactive=True, terminal=True, repeat=False, **overrides):
        env = dict(self.env, **overrides)
        code = DRIVER
        if repeat:
            code += '; "$WELCOME_ZSH" -fic ' + "'" + DRIVER + "'"
        args = [ZSH, "-fic" if interactive else "-fc", code]
        if not terminal:
            result = subprocess.run(args, env=env, stdin=subprocess.DEVNULL,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                    timeout=10, check=True)
            return result.stdout.decode(errors="replace")
        # util-linux script provides a controlling terminal, not just tty fds.
        script = shutil.which("script")
        self.assertIsNotNone(script, "util-linux script must be available")
        env["SHELL"] = "/bin/sh"
        result = subprocess.run(
            [script, "-q", "-e", "-c", shlex.join(args), "/dev/null"],
            env=env, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, timeout=10, check=True,
        )
        return result.stdout.decode(errors="replace").replace("\r\n", "\n")

    def test_fixed_and_pipeline(self):
        result = self.invoke(DOTFILES_MOTD="dubnium")
        for marker in ("D U B N I U M", "FORTUNE_MARKER", "COW_MARKER",
                       "RAINBOW_MARKER", "TASK_MARKER todo"):
            self.assertIn(marker, result)

    def test_plain(self):
        result = self.invoke(DOTFILES_MOTD="micrantha", NO_COLOR="1")
        self.assertIn("micrantha.com", result)
        self.assertNotIn("RAINBOW_MARKER", result)
        self.assertIn("TASK_MARKER rc.color=off todo", result)
        self.assertNotIn("\x1b", result)

    def test_suppression(self):
        for overrides in (
            {"DOTFILES_WELCOME": "0"}, {"CI": "true"}, {"TERM": "dumb"},
            {"SSH_CONNECTION": "fixture"}, {"DOTFILES_WELCOME_SHOWN": "1"},
        ):
            with self.subTest(overrides=overrides):
                self.assertEqual(self.invoke(**overrides), "")
        self.assertEqual(self.invoke(interactive=False), "")
        non_tty = self.invoke(terminal=False)
        self.assertNotIn("FORTUNE_MARKER", non_tty)
        self.assertNotIn("TASK_MARKER", non_tty)
        self.assertNotIn("micrantha.com", non_tty)

    def test_ssh_opt_in(self):
        self.assertIn("FORTUNE_MARKER", self.invoke(SSH_CONNECTION="fixture",
                                                   DOTFILES_WELCOME="1"))

    def test_nested(self):
        self.assertEqual(self.invoke(repeat=True).count("FORTUNE_MARKER"), 1)

    def test_optional_commands_missing(self):
        result = self.invoke(PATH=str(self.minimal), DOTFILES_MOTD="unix")
        self.assertIn("UNIX", result)
        self.assertNotIn("FORTUNE_MARKER", result)
        self.assertNotIn("TASK_MARKER", result)

    def test_selection(self):
        self.assertIn("micrantha.com", self.invoke(DOTFILES_MOTD="../missing"))
        self.assertEqual(self.invoke(DOTFILES_MOTD="daily"),
                         self.invoke(DOTFILES_MOTD="daily"))
        for _ in range(5):
            result = self.invoke(DOTFILES_MOTD="random", WELCOME_PROFILE="other")
            self.assertNotIn("D U B N I U M", result)
            self.assertIn("FORTUNE_MARKER", result)


if __name__ == "__main__":
    unittest.main()
