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
        defaultGitRev = "0000000";
        gwtVersion = builtins.getEnv "GWT_VERSION";
        gitRev = builtins.getEnv "GIT_REV";

        mkGwtTools = { gwtVersion ? defaultGwtVersion }:
          pkgs.callPackage ./tools.nix { inherit gwtVersion; };

        mkGwt = { gwtVersion ? defaultGwtVersion, gitRev ? defaultGitRev }:
          pkgs.callPackage ./gwt.nix {
            inherit gwtVersion gitRev;
            gwtTools = mkGwtTools { inherit gwtVersion; };
          };
      in
      {
        packages = {
          gwtTools = mkGwtTools {
            gwtVersion = if gwtVersion != "" then gwtVersion else defaultGwtVersion;
          };
          gwt = mkGwt {
            gwtVersion = if gwtVersion != "" then gwtVersion else defaultGwtVersion;
            gitRev = if gitRev != "" then gitRev else defaultGitRev;
          };
        };

        defaultPackage = self.packages.${system}.gwt;
      }
    );
}
