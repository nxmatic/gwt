{ lib, stdenv, unzip, patch, rsync, jdk17, ant, git, which, coreutils, gnused, gnugrep, gwtVersion, gitRev, gwtTools }:

stdenv.mkDerivation {
  pname = "gwt";
  version = gwtVersion;

  src = lib.cleanSourceWith {
    filter = name: type: let baseName = baseNameOf (toString name); in
                         !(lib.hasPrefix "." baseName) || baseName == ".devenv";
    src = ../../.;  # Use the parent directory as the source
  };

  sourceRoot = ".";

  nativeBuildInputs = [ unzip git which coreutils gnused gnugrep patch rsync ];
  buildInputs = [ jdk17 ant ];

  unpackPhase = ''
    runHook preUnpack

    rsync -av --chmod=u+rw $src/. .

    runHook postUnpack
  '';

  patchPhase = ''
    runHook prePatch

    patch -p1 < ${ ./common.ant.xml.patch }

    runHook postPatch
  '';

  buildPhase = ''
    runHook preBuild

    export GWT_TOOLS="${lib.escapeShellArg gwtTools}"
    export GWT_VERSION="${gwtVersion}"
    export GIT_REV="${gitRev}"

    echo "Building GWT $${GWT_VERSION}:$${GIT_REV} using GWT_TOOLS=$${GWT_TOOLS}"

    env JAVA_HOME="${jdk17}" ant -f build.xml \
        -lib ${gwtTools}/lib -Dgwt.tools=${gwtTools} dist-dev

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
      rsync -av --progress build/dist/ $out/

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "http://www.gwtproject.org/";
    description = "Google Web Toolkit";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
