{ stdenv, lib, fetchFromGitHub, finalGwtVersion }:

stdenv.mkDerivation rec {
  pname = "gwtTools";
  version = finalGwtVersion;

  src = fetchFromGitHub {
    owner = "gwtProject";
    repo = "tools";
    rev = "87db1e01191902be60cb12745a6267ae86de540a";
    sha256 = "sha256-y+2j0YucfxTPZmzXrdpWv2ui9ISEXzzIoKgj9JTWo5o=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r $src/* $out/

    runHook postInstall
  '';

  meta = {
    description = "Toolchain for building GWT ${finalGwtVersion}";
    homepage = "https://github.com/gwtProject/tools";
    license = lib.licenses.asl20;
  };
}
