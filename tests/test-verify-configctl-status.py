"""Regression tests for fail-closed Neovim loader authority evidence."""

import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "verify_configctl_status", ROOT / "checks/verify-configctl-status.py"
)
assert SPEC and SPEC.loader
verifier = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(verifier)


class NeovimEvidenceTest(unittest.TestCase):
    def test_block_comment_cannot_prove_runtime_loader(self):
        for prefix, suffix in (("--[[", "]]"), ("--[=[", "]=]"), ("--[[", "")):
            with self.subTest(prefix=prefix, suffix=suffix):
                lines = verifier.active_lua_lines(
                    'source_lua_file("~/.config/nvim/local.lua")\n'
                    + prefix
                    + '\nsource_lua_dir("~/.config/nvim/custom")\n'
                    + suffix
                    + '\n'
                )
                self.assertNotIn('source_lua_dir("~/.config/nvim/custom")', lines)

    def test_runtime_validator_rejects_disabled_loader(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            module = root / "modules/home/neovim.nix"
            module.parent.mkdir(parents=True)
            module.write_text('xdg.configFile."nvim" = {};', encoding="utf-8")
            lua = root / "files/home/.config/nvim/init.lua"
            lua.parent.mkdir(parents=True)
            lua.write_text(
                'source_lua_file("~/.config/nvim/local.lua")\n'
                '--[[\nsource_lua_dir("~/.config/nvim/custom")\n]]\n'
                'source_lua_dir("~/.config/nvim/adopted")\n',
                encoding="utf-8",
            )
            entry = {
                "local": "local.lua",
                "custom": "custom",
                "adopted": "adopted",
                "authority_refs": ["files/home/.config/nvim/init.lua"],
            }
            with patch.object(verifier, "REPO_ROOT", root):
                with self.assertRaisesRegex(SystemExit, "missing active exact Neovim custom"):
                    verifier.validate_home_manager_authority("nvim", entry, module)


if __name__ == "__main__":
    unittest.main()
