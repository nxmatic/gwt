{
  description = "GWT devenv environment providing JDK 17 and Apache Ant";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gwt-packages.url = "path:./gwt-packages";
  };

  outputs = { self, nixpkgs, flake-utils, gwt-packages }: 
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        computeGwtVersion = pkgs.writeScriptBin "gwt-version" (builtins.readFile ./gwt-version.sh);
        buildGwtPackage = pkgs.writeScriptBin "nix-build-gwt" ''
          #!/usr/bin/env -S bash -eu -o pipefail

          # Execute the build-gwt.sh script
          exec env NIX_SYSTEM="${system}" ${./build-gwt.sh} "$@"
        '';
        defaultGwtVersion = "0.0.0-dev";
        finalGwtVersion = if builtins.getEnv "GWT_VERSION" != "" then builtins.getEnv "GWT_VERSION" else defaultGwtVersion;

        gwtTools = pkgs.callPackage ./gwt-packages/gwtTools.nix {
          inherit finalGwtVersion;
        };

        gwt = pkgs.callPackage ./gwt-packages/gwt.nix {
          inherit finalGwtVersion gwtTools;
          jdk17 = pkgs.jdk17;
        };

        mkDevShell = { gwtVersion ? null }:
          let
            effectiveGwtVersion = if gwtVersion != null then gwtVersion else finalGwtVersion;
          in pkgs.mkShell {
            buildInputs = with pkgs; [
              jdk17
              ant
              maven
              yq-go
              git
              computeGwtVersion
              gwtTools
              buildGwtPackage
            ];

            shellHook = ''
              export GWT_VERSION="$([[ -d .git ]] && echo "$(gwt-version)" || echo "${effectiveGwtVersion}")"
              export GWT_TOOLS="${gwtTools}"

              echo "Using GWT tools from: $GWT_TOOLS"
              echo "GWT version: $GWT_VERSION"
              echo "To build the GWT package, run 'nix-build-gwt' in this directory."
            '';
          };
      in
      {
        apps.build-gwt = flake-utils.lib.mkApp { drv = buildGwtPackage; };

        devShells = {
          default = mkDevShell {};
          withVersion = mkDevShell { gwtVersion = builtins.getEnv "GWT_VERSION"; };
        };

        packages = {
          inherit gwt gwtTools;
        };
      }
    );
}
