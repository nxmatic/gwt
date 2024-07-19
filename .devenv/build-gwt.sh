#!/usr/bin/env -S bash -e -o pipefail

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

if [ -z "$GIT_REV" ]; then
  echo "Error: GIT_REV is not set" >&2
  exit 1
fi

echo "Building GWT ${GWT_VERSION}:${GIT_REV} development distribution package version"

exec nix build --impure --out-link "${root}/.devenv/dist/result" "${root}/.devenv/dist#gwt"
