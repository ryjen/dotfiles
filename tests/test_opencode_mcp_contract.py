"""Contract tests for declarative OpenCode MCP server registration.

MCP servers must be rendered into the Home Manager-owned
``~/.config/opencode/config.json`` so they survive rebuilds and stop drifting
into the hand-written ``opencode.json`` override file.
"""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE = ROOT / "modules" / "home" / "opencode.nix"
HEADROOM = ROOT / "modules" / "home" / "headroom.nix"
WORKSTATION = ROOT / "home" / "ryjen" / "profiles" / "workstation.nix"
CATALOG = ROOT / "home" / "ryjen" / "user.example.nix"
FRAGMENTS = (
    "files/home/.config/opencode/config.d/dubnium/config.json",
    "files/home/.config/opencode/config.d/technetium/config.json",
)


def test_opencode_renders_declarative_mcp_servers() -> None:
    module = MODULE.read_text(encoding="utf-8")

    assert "mcp = lib.mkOption" in module
    assert "lib.types.attrsOf" in module
    assert "builtins.fromJSON" in module
    assert "builtins.toJSON" in module
    assert '"opencode/config.json"' in module


def test_headroom_registers_its_mcp_server() -> None:
    headroom = HEADROOM.read_text(encoding="utf-8")

    assert "dotfiles.opencode.mcp.headroom" in headroom
    assert "cfg.mcp.package" in headroom
    assert '"mcp"' in headroom
    assert '"serve"' in headroom


def test_serena_mcp_is_declared_by_the_workstation_profile() -> None:
    workstation = WORKSTATION.read_text(encoding="utf-8")

    assert "opencode.mcp.serena" in workstation
    assert "start-mcp-server" in workstation


def test_managed_fragments_do_not_hardcode_mcp_servers() -> None:
    for relative in FRAGMENTS:
        content = (ROOT / relative).read_text(encoding="utf-8")
        assert '"mcp"' not in content, relative


def test_option_is_listed_in_the_user_catalog() -> None:
    catalog = CATALOG.read_text(encoding="utf-8")

    assert "dotfiles.opencode.mcp" in catalog
