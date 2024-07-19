#!/usr/bin/env -S bash -ex -o pipefail

root=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$root" ]; then
  echo "Error: Not in a Git repository" >&2
  exit 1
fi

current_dir=$(pwd)
if [[ "$current_dir" != "$root"* ]]; then
  echo "Error: Current directory is not within the Git worktree" >&2
  exit 1
fi

if [ ! -d "${root}/.devenv" ]; then
  echo "Error: .devenv directory not found in Git root" >&2
  exit 1
fi

if [ -z "$GWT_VERSION" ]; then
  echo "Error: GWT_VERSION is not set" >&2
  exit 1
fi

if [ -z "$NIX_SYSTEM" ]; then
  echo "Error: NIX_SYSTEM is not set" >&2
  exit 1
fi

echo "Building GWT version: $GWT_VERSION for system: $NIX_SYSTEM"
exec nix build --out-link "${root}/.devenv/gwt" \
  --override-input gwt-packages "path:${root}/gwt-packages" \
  --override-input gwt-packages/nixpkgs "github:NixOS/nixpkgs/nixos-unstable" \
  --expr "(builtins.getFlake \"${root}/gwt-packages\").packages.${NIX_SYSTEM}.gwt.override { finalGwtVersion = \"$GWT_VERSION\"; }"
