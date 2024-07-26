{
  description = "GWT devenv environment providing JDK 17 and Apache Ant";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gwt-packages.url = "path:./dist";
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
        shellHookScript = pkgs.writeTextFile {
          name = "nix-shell-hook.rc";
          text = builtins.readFile ./shell-hook.sh;
        };

        # Github Token
        defaultGithubToken = "";
        githubToken = builtins.getEnv "GITHUB_TOKEN";
        effectiveGithubToken = if githubToken != "" then githubToken else defaultGithubToken;

        # GH Token
        ghToken = builtins.getEnv "GH_TOKEN";
        effectiveGhToken = if ghToken != "" then ghToken else effectiveGithubToken;

        # Cachix authentication token
        defaultCachixAuthToken = "";
        cachixAuthToken = builtins.getEnv "CACHIX_AUTH_TOKEN";
        effectiveCachixAuthToken = if cachixAuthToken != "" then cachixAuthToken else defaultCachixAuthToken;


        # GWT version
        defaultGwtVersion = "0.0.0-dev";
        gwtVersion = builtins.getEnv "GWT_VERSION";
        effectiveGwtVersion = if gwtVersion != "" then gwtVersion else defaultGwtVersion;
        
        # Git rev
        defaultGitRev = "0000000";
        gitRev = builtins.getEnv "GIT_REV";
        effectiveGitRev = if gitRev != "" then gitRev else defaultGitRev;
        
        # packages
        gwtTools = pkgs.callPackage ./dist/tools.nix {
          gwtVersion = effectiveGwtVersion;
        };
        gwt = pkgs.callPackage ./dist/gwt.nix {
          inherit gwtTools;
          gwtVersion = effectiveGwtVersion;
          gitRev = effectiveGitRev;
          jdk17 = pkgs.jdk17;
        };
        
        # shells
        mkDevShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            cachix
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
            shellHookScript
          ];

          shellHook = ''
            cat <<! | cut -c 3-
              Effective GitHub Token: ${effectiveGithubToken}
              Effective GH Token: ${effectiveGhToken}
              Effective Cachix Auth Token: ${effectiveCachixAuthToken}
              Effective GWT Version: ${effectiveGwtVersion}
              Effective GWT Tools: ${gwtTools}
              Effective Git Rev: ${effectiveGitRev}
            !
            NIX_GITHUB_TOKEN="${effectiveGithubToken}"
            NIX_GH_TOKEN="${effectiveGhToken}"
            NIX_CACHIX_AUTH_TOKEN="${effectiveCachixAuthToken}"
            NIX_GWT_VERSION="${effectiveGwtVersion}"
            NIX_GWT_TOOLS="${gwtTools}"
            NIX_GIT_REV="${effectiveGitRev}"

            source ${shellHookScript}
          '';
        };
      in
      {
        apps.build-gwt = flake-utils.lib.mkApp { drv = buildGwtPackage; };
        
        devShells = {
          default = mkDevShell;
        };
        
        packages = {
          inherit gwt gwtTools;
        };
      }
    );
}
