from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

CLIENT_CONFIGS = (
    "modules/home/headroom.nix",
    "files/home/.config/hermes/base.yaml",
    "files/home/.config/planoai/dubnium.yaml",
    "files/home/.config/opencode/config.d/dubnium/config.json",
    "files/home/.config/opencode/config.d/technetium/config.json",
    "home/ryjen/user.example.nix",
    "modules/home/open-webui.nix",
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


def test_open_webui_podman_and_model_transport_are_scoped() -> None:
    source = (ROOT / "modules/home/open-webui.nix").read_text(encoding="utf-8")
    image = (ROOT / "packages/open-webui-image.nix").read_text(encoding="utf-8")

    for required in (
        "--network=none",
        "--cap-drop=ALL",
        "--security-opt=no-new-privileges",
        "--read-only",
        "--pull=never",
        "--volume=\"$runtime/gateway:/run/open-webui/gateway:ro\"",
        "OPENAI_API_BASE_URL=http://127.0.0.1:8080/v1",
        "OPENAI_API_BASE_URLS=http://127.0.0.1:8080/v1",
        "OFFLINE_MODE=True",
        "HF_HUB_OFFLINE=1",
        "RAG_EMBEDDING_MODEL_AUTO_UPDATE=False",
        "RAG_RERANKING_MODEL_AUTO_UPDATE=False",
        "WHISPER_MODEL_AUTO_UPDATE=False",
        "BYPASS_EMBEDDING_AND_RETRIEVAL=True",
        "ENABLE_OLLAMA_API=False",
        "ENABLE_PERSISTENT_CONFIG=False",
        "DEFAULT_MODELS=supervisor",
        "WEBUI_AUTH=True",
        "ENABLE_DIRECT_CONNECTIONS=False",
        "ENABLE_SIGNUP=",
        'ListenStream = "127.0.0.1:',
        "XDG_RUNTIME_DIR",
        "Host.Security.Rootless",
    ):
        assert required in source, required

    for forbidden in (
        "--network=host",
        "--privileged",
        "slirp4netns:allow_host_loopback",
        "pasta:--map-gw",
        "ghcr.io/open-webui/open-webui:main",
        "--volume=/var/run/docker.sock",
        "--volume=/run/podman",
    ):
        assert forbidden not in source, forbidden

    # Host socket-proxy processes must retain the confined transport boundary.
    assert source.count("ProtectHome = true;") == 1
    assert source.count('ProtectHome = "tmpfs";') == 1
    assert 'BindReadOnlyPaths = [ "${runtimeRoot}/ingress" ];' in source
    assert source.count('CapabilityBoundingSet = "";') == 2
    assert source.count("PrivateTmp = true;") == 2
    assert 'RestrictAddressFamilies = [ "AF_UNIX" ];' in source
    assert '        "AF_INET"' in source

    # Rootless limits require cgroup v2 and systemd delegation.
    assert "--cgroup-manager=systemd" in source
    assert "--cgroup-manager=cgroupfs" not in source
    assert "{{.Host.CgroupsVersion}}" in source
    assert "{{.Host.CgroupManager}}" in source
    assert "Delegate = true;" in source

    # An ordered health probe must complete before socket-activated ingress.
    assert 'ExecStartPost = "${readiness}";' in source
    assert '--unix-socket "$runtime/ingress/socket"' in source
    assert "http://localhost/health" in source
    assert "dockerTools.buildLayeredImage" in image
    assert "tag = open-webui.version;" in image
    assert "/bin/head -c 24 /dev/urandom" in source
    assert "/bin/head -c 32 /dev/urandom" not in source
    assert "cd /var/lib/open-webui" in image
    assert "if [[ ! -f .webui_secret_key" in image
    assert "WEBUI_SECRET_KEY_FILE" not in image

    # Open WebUI owns container port 8081; 8080 is the sole Supervisor proxy.
    assert "TCP-LISTEN:8080,bind=127.0.0.1" in image
    assert "open-webui serve --host 127.0.0.1 --port 8081" in image
    assert "TCP:127.0.0.1:8081" in image
    assert "TCP-LISTEN:8081,bind=127.0.0.1" not in image
    assert "open-webui serve --host 127.0.0.1 --port 8080" not in image
