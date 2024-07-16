{ lib, stdenv, unzip, jdk17, ant, git, which, coreutils, gnused, gnugrep, computeGwtVersion, gwtTools }:

stdenv.mkDerivation  {
  pname = "gwt";
  version = "dynamic";

  src = lib.cleanSource ../.;  # Use the parent directory as the source

  sourceRoot = ".";

  nativeBuildInputs = [ unzip git which coreutils gnused gnugrep ];
  buildInputs = [ jdk17 ant ];

  unpackPhase = ''
    runHook preUnpack
    cp -r $src/* .
    chmod -R u+w .
    runHook postUnpack
  '';

  preBuildPhase = ''
    runHook preBuild
    export GWT_VERSION=$(${computeGwtVersion})
    export GWT_TOOLS=${gwtTools}
    export JAVA_HOME="${jdk17}"

    cat <<EOF | cut -c 3- 
      Using GWT tools from: $GWT_TOOLS"
      GWT $GWT_VERSION is available in nix at '$out', you may rebuild it using 'ant dist' in 'build/dist'.
    EOF
  '';

  buildPhase = ''
    export GWT_TOOLS=${lib.escapeShellArg gwtTools}
  
    echo "Building GWT $version using GWT_TOOLS=$GWT_TOOLS"
    env JAVA_HOME="${jdk17}" ant dist
  '';

  installPhase = ''

    mkdir -p $out
    cp -r build/dist/* $out/
  '';

  meta = with lib; {
    homepage = "http://www.gwtproject.org/";
    description = "Google Web Toolkit";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
