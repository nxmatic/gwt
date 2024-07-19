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
        computeGwtVersion = pkgs.writeScriptBin "compute-gwt-version" (builtins.readFile ./compute-gwt-version.sh);
        defaultGwtVersion = "0.0.0-dev";

        mkDevShell = { gwtVersion ? null }:
          let
            finalGwtVersion = if gwtVersion != null then gwtVersion else defaultGwtVersion;
            gwtTools = gwt-packages.lib.${system}.mkGwtTools { inherit finalGwtVersion; };
            gwt = gwt-packages.lib.${system}.mkGwt { inherit finalGwtVersion; };
          in pkgs.mkShell {
            buildInputs = with pkgs; [
              jdk17
              ant
              maven
              yq-go
              git
              computeGwtVersion
              gwtTools
              gwt
            ];

            shellHook = ''
              export GWT_VERSION="${finalGwtVersion}"
              export GWT_TOOLS="${gwtTools.outPath}"
              export GWT_DIST="${gwt.outPath}"

              if [ -d .git ]; then
                computed_version=$(compute-gwt-version)
                if [ "$computed_version" != "$GWT_VERSION" ]; then
                  echo "Warning: Computed version ($computed_version) differs from build version ($GWT_VERSION)"
                fi
              fi

              ln -sfn "$GWT_DIST" result

              echo "Using GWT tools from: $GWT_TOOLS"
              echo "GWT version: $GWT_VERSION"
              echo "GWT distribution is available at: .devenv/result ( -> $GWT_DIST)"
              echo "You may rebuild GWT using 'ant dist' in the appropriate directory."
            '';
          };
      in
      {
        devShells = {
          default = mkDevShell {};
          withVersion = mkDevShell { gwtVersion = builtins.getEnv "GWT_VERSION"; };
        };
      }
    );
}
