{
  description = "GWT and GWT Tools packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        defaultGwtVersion = "0.0.0-dev";

        mkGwtTools = { finalGwtVersion ? defaultGwtVersion }:
          pkgs.callPackage ./gwtTools.nix { inherit finalGwtVersion; };

        mkGwt = { finalGwtVersion ? defaultGwtVersion }:
          pkgs.callPackage ./gwt.nix {
            gwtTools = mkGwtTools { inherit finalGwtVersion; };
            inherit finalGwtVersion;
          };
      in
      {
        packages = {
          gwtTools = mkGwtTools { finalGwtVersion = defaultGwtVersion; };
          gwt = mkGwt { finalGwtVersion = defaultGwtVersion; };
        };

        defaultPackage = self.packages.${system}.gwt;
      }
    );
}