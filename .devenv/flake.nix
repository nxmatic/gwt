{
  description = "GWT devenv environment providing JDK 17 and Apache Ant";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: 
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        computeGwtVersion = pkgs.writeScriptBin "compute-gwt-version" (builtins.readFile ./compute-gwt-version.sh);
        gwtTools = builtins.getEnv "GWT_TOOLS";
        
        gwtDeps = {
          inherit computeGwtVersion gwtTools;
        };
      
        gwt = pkgs.callPackage ./gwt.nix gwtDeps;
      in
      {
        packages.default = gwt;
        packages.gwt = gwt;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            jdk17
            ant
            maven
            yq-go
            git
            computeGwtVersion
          ];

          shellHook = ''
            echo "gwtTools = ${gwtTools}"
            export GWT_VERSION=$(compute-gwt-version)
            export GWT_TOOLS=${gwtTools}
            export GWT_OUT_PATH=${gwt.outPath}

            cat <<! | cut -c 3- 
              Using GWT tools from: $GWT_TOOLS"
              GWT $GWT_VERSION is available in nix at '$GWT_OUT_PATH', you may rebuild it using 'ant dist' in 'build/dist'.
            !
          '';
        };
      }
    );
}
