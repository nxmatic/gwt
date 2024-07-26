set -ax
[[ -n "${NIX_GITHUB_TOKEN:-}" ]] &&
  GITHUB_TOKEN="${NIX_GITHUB_TOKEN}"
[[ -n "${NIX_GITHUB_TOKEN:-}" ]] &&
  GH_TOKEN="${NIX_GITHUB_TOKEN}"
[[ -n "${NIX_CACHIX_AUTH_TOKEN:-}" ]] &&
  CACHIX_AUTH_TOKEN="${NIX_CACHIX_AUTH_TOKEN}"
GWT_VERSION=$( [[ -d .git ]] && nix-gwt-version || echo "${NIX_GWT_VERSION:-}" )
GWT_TOOLS="${NIX_GWT_TOOLS:-}"
GIT_REV=$( [[ -d .git ]] && nix-git-rev || echo "${NIX_GIT_REV:-}" )
set +ax

if [ -z "${CACHIX_AUTH_TOKEN:-}" ]; then
  echo "Warning: CACHIX_AUTH_TOKEN is not set. Cachix may not work correctly for private caches."
else
  cachix use gwt-nuxeo
fi

cat <<EOF
GITHUB_TOKEN is ${GITHUB_TOKEN:+set}${GITHUB_TOKEN:-not set}, GH_TOKEN is ${GH_TOKEN:+set}${GH_TOKEN:-not set}

GWT version: $GWT_VERSION. Git revision: $GIT_REV
Using GWT tools from: $GWT_TOOLS
To build the GWT distribution package, run 'nix-build-gwt' and to deploy the maven artifacts 'nix-push-gwt'.
EOF
