{
  appimageTools,
  fetchurl,
  lib,
}:
let
  pname = "openwork";
  version = "0.17.40";
  src = fetchurl {
    url = "https://github.com/different-ai/openwork/releases/download/v${version}/openwork-linux-x86_64-${version}.AppImage";
    hash = lib.fakeHash;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  meta = {
    description = "Open-source desktop app for sharing AI workflows";
    homepage = "https://github.com/different-ai/openwork";
    license = lib.licenses.mit;
    mainProgram = "openwork";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
