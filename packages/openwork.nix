{
  appimage-run,
  fetchurl,
  lib,
  runtimeShell,
  stdenvNoCC,
}:
let
  pname = "openwork";
  version = "0.17.40";
  src = fetchurl {
    url = "https://github.com/different-ai/openwork/releases/download/v${version}/openwork-linux-x86_64-${version}.AppImage";
    hash = "sha256-5XTyhwBvStZ+1ari2RI4T0wd/8tn/cYUFHZqInFfwFQ=";
  };
in
stdenvNoCC.mkDerivation {
  inherit pname version src;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/libexec/openwork/openwork.AppImage"
    mkdir -p "$out/bin"
    cat > "$out/bin/openwork" <<EOF
#!${runtimeShell}
exec ${appimage-run}/bin/appimage-run "$out/libexec/openwork/openwork.AppImage" "\$@"
EOF
    chmod +x "$out/bin/openwork"

    runHook postInstall
  '';

  meta = {
    description = "Open-source desktop app for sharing AI workflows";
    homepage = "https://github.com/different-ai/openwork";
    license = lib.licenses.mit;
    mainProgram = "openwork";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
