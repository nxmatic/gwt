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
        # scripts
        computeGwtVersion = pkgs.writeScriptBin "nix-gwt-version" (builtins.readFile ./gwt-version.sh);
        computeGitRev = pkgs.writeScriptBin "nix-git-rev" (builtins.readFile ./git-rev.sh);
        buildGwtPackage = pkgs.writeScriptBin "nix-build-gwt" (builtins.readFile ./build-gwt.sh);
        pushGwtPackage = pkgs.writeScriptBin "nix-push-gwt" (builtins.readFile ./push-gwt.sh);
        # versions
        defaultGwtVersion = "0.0.0-dev";
        finalGwtVersion = if builtins.getEnv "GWT_VERSION" != "" then builtins.getEnv "GWT_VERSION" else defaultGwtVersion;
        # git rev
        defaultGitRev = "0000000";
        finalGitRev = if builtins.getEnv "GIT_REV" != "" then builtins.getEnv "GIT_REV" else defaultGitRev;
        # packages
        gwtTools = pkgs.callPackage ./dist/tools.nix {
          inherit finalGwtVersion;
        };
        gwt = pkgs.callPackage ./dist/gwt.nix {
          inherit finalGwtVersion finalGitRev;
          jdk17 = pkgs.jdk17;
        };
        # shells
        mkDevShell = { gwtVersion ? null, gitRev ? null }:
          let
            effectiveGwtVersion = if gwtVersion != null then gwtVersion else finalGwtVersion;
            effectiveGitRev = if gitRev != null then gitRev else finalGitRev;
            shellHookContent = builtins.readFile ./shell-hook.sh;
          in pkgs.mkShell {
            buildInputs = with pkgs; [
              jdk17
              ant
              maven
              yq-go
              git
              gh
              unixtools.column
              gwtTools
              computeGwtVersion
              computeGitRev
              buildGwtPackage
              pushGwtPackage
            ];

            shellHook = ''
              export NIX_GWT_VERSION="${effectiveGwtVersion}"
              export NIX_GWT_TOOLS="${gwtTools}"
              export NIX_GIT_REV="${effectiveGitRev}"
              
              ${shellHookContent}
            '';
          };
      in
      {
        apps.build-gwt = flake-utils.lib.mkApp { drv = buildGwtPackage; };

        devShells = {
          default = mkDevShell {};
          withVersion = mkDevShell { gwtVersion = builtins.getEnv "GWT_VERSION"; gitRev = builtins.getEnv "GIT_REV"; };
        };

        packages = {
          inherit gwt gwtTools;
        };
      }
    );
}
