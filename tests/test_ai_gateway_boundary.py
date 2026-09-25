from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

CLIENT_CONFIGS = (
    "modules/home/headroom.nix",
    "files/home/.config/hermes/base.yaml",
    "files/home/.config/planoai/dubnium.yaml",
    "files/home/.config/opencode/config.d/dubnium/config.json",
    "files/home/.config/opencode/config.d/technetium/config.json",
    "home/ryjen/user.example.nix",
)


def test_normal_ai_clients_do_not_reference_raw_llm_runtime() -> None:
    for relative_path in CLIENT_CONFIGS:
        content = (ROOT / relative_path).read_text(encoding="utf-8")
        assert "127.0.0.1:8000" not in content, relative_path


def test_local_client_configs_use_supervisor_alias() -> None:
    hermes = (ROOT / "files/home/.config/hermes/base.yaml").read_text(encoding="utf-8")
    opencode_dubnium = (
        ROOT / "files/home/.config/opencode/config.d/dubnium/config.json"
    ).read_text(encoding="utf-8")
    opencode_technetium = (
        ROOT / "files/home/.config/opencode/config.d/technetium/config.json"
    ).read_text(encoding="utf-8")

    assert "default: supervisor" in hermes
    assert "default_model: supervisor" in hermes
    assert '"model": "dubnium/supervisor"' in opencode_dubnium
    assert '"model": "dubnium/supervisor"' in opencode_technetium
