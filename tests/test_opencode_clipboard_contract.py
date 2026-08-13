from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE = ROOT / "modules" / "home" / "opencode.nix"
WORKSTATION = ROOT / "home" / "ryjen" / "profiles" / "workstation.nix"


def test_opencode_clipboard_workaround_is_scoped_and_detached() -> None:
    module = MODULE.read_text(encoding="utf-8")

    assert "https://github.com/anomalyco/opencode/issues/42162" in module
    assert 'pkgs.writeShellScriptBin "wl-copy"' in module
    assert (
        'exec ${pkgs.util-linux}/bin/setsid '
        '${pkgs.wl-clipboard}/bin/wl-copy "$@"'
    ) in module
    assert 'export PATH="${wlCopyShim}/bin:$PATH"' in module
    assert 'exec "${npmBin}/opencode" "$@"' in module
    assert 'home.sessionPath = lib.mkBefore [ "${opencodeWrapper}/bin" ];' in module


def test_opencode_integration_is_workstation_owned() -> None:
    module = MODULE.read_text(encoding="utf-8")
    workstation = WORKSTATION.read_text(encoding="utf-8")

    assert "default = false;" in module
    assert "dotfiles.opencode.enable = lib.mkDefault true;" in workstation
