#!/usr/bin/env -S bash -e -o pipefail

set -a
GWT_VERSION=$( [[ -d .git ]] && echo "$(nix-gwt-version)" || echo "${NIX_GWT_VERSION}" )
GWT_TOOLS="${NIX_GWT_TOOLS}"
GIT_REV=$( [[ -d .git ]] && echo "$(nix-git-rev)" || echo "${NIX_GIT_REV}" )
set +a

cat <<EOF
GWT version: $GWT_VERSION. Git revision: $GIT_REV
Using GWT tools from: $GWT_TOOLS
To build the GWT distribution package, run 'nix-build-gwt' and to deploy the maven artifacts 'nix-push-gwt'.
EOF
