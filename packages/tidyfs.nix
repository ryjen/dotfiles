{
  fetchurl,
  lib,
  stdenvNoCC,
}:
let
  pname = "tidyfs";
  version = "0.6.1";
  target = "x86_64-unknown-linux-gnu";
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/ryjen/tidyfs/releases/download/v${version}/tidyfs-${version}-${target}.tar.gz";
    hash = "sha256-BhFv1k2BxSSEwGZI8oOB9MpAjfWjogBOZN+XE5FMcdI=";
  };

  installPhase = ''
    runHook preInstall

    install -Dm755 tidyfs "$out/bin/tidyfs"
    install -Dm644 README.md LICENSE-MIT LICENSE-APACHE -t "$out/share/doc/tidyfs"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    test "$("$out/bin/tidyfs" --version)" = "tidyfs ${version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Conservative disk usage scanner and cleanup planner for developer machines";
    homepage = "https://github.com/ryjen/tidyfs";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "tidyfs";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
