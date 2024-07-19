{ lib, stdenv, unzip, rsync, jdk17, ant, git, which, coreutils, gnused, gnugrep, finalGwtVersion, gwtTools }:

stdenv.mkDerivation {
  pname = "gwt";
  version = finalGwtVersion;

  src = lib.cleanSource ../../.;  # Use the parent directory as the source

  sourceRoot = ".";

  nativeBuildInputs = [ unzip git which coreutils gnused gnugrep rsync ];
  buildInputs = [ jdk17 ant ];

  unpackPhase = ''
    runHook preUnpack
    cp -r $src/* .
    chmod -R u+w .
    runHook postUnpack
  '';

  buildPhase = ''
    runHook preBuild

    export GWT_TOOLS=${lib.escapeShellArg gwtTools}
    export GWT_VERSION="${finalGwtVersion}"

    echo "Building GWT $GWT_VERSION using GWT_TOOLS=$GWT_TOOLS"
    env JAVA_HOME="${jdk17}" ant dist-dev

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
      rsync -av --progress build/ $out/

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "http://www.gwtproject.org/";
    description = "Google Web Toolkit";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
