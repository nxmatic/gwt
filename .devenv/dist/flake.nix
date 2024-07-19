{
  description = "GWT and GWT Tools packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    customMacrodefs = { url = "path:custom-macrodefs.xml"; flake = false; };
  };

  outputs = { self, nixpkgs, flake-utils, customMacrodefs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        defaultGwtVersion = "0.0.0-dev";
        defaultGitRev = "0000000";
        gwtVersion = builtins.getEnv "GWT_VERSION";
        gitRev = builtins.getEnv "GIT_REV";

        mkGwtTools = { finalGwtVersion ? defaultGwtVersion }:
          pkgs.callPackage ./tools.nix { inherit finalGwtVersion; };

        mkGwt = { finalGwtVersion ? defaultGwtVersion, finalGitRev ? defaultGitRev }:
          pkgs.callPackage ./gwt.nix {
            gwtTools = mkGwtTools { inherit finalGwtVersion; };
            inherit finalGwtVersion finalGitRev customMacrodefs;
          };
      in
      {
        packages = {
          gwtTools = mkGwtTools { 
            finalGwtVersion = if gwtVersion != "" then gwtVersion else defaultGwtVersion; 
          };
          gwt = mkGwt { 
            finalGwtVersion = if gwtVersion != "" then gwtVersion else defaultGwtVersion; 
            finalGitRev = if gitRev != "" then gitRev else defaultGitRev;
          };
        };

        defaultPackage = self.packages.${system}.gwt;
      }
    );
}
