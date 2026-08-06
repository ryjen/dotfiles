from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
HYPR_MODULE = ROOT / "modules" / "home" / "hypr.nix"


def test_variety_activation_is_content_and_metadata_gated() -> None:
    content = HYPR_MODULE.read_text(encoding="utf-8")

    assert "${pkgs.diffutils}/bin/cmp -s" in content
    assert 'touch "$variety_config"' not in content
    assert 'cat "$tmp" > "$variety_config"' not in content
    assert '${pkgs.coreutils}/bin/install -m 0600 "$tmp" "$variety_config"' in content
    assert "trap '${pkgs.coreutils}/bin/rm -f \"$tmp\"' EXIT" in content
    assert '${pkgs.coreutils}/bin/stat -c %a "$variety_config"' in content
    assert '[ "$(${pkgs.coreutils}/bin/stat -c %a "$variety_config")" != "600" ]' in content
