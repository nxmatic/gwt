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

if [ -z "$GWT_DIST_FILE" ] || [ ! -r "$GWT_DIST_FILE" ]; then
  # Find the freshest GWT distribution ZIP file
  zips=("${root}/.devenv/dist/result"/gwt-*.zip)
  zip="${zips[-1]}"  # Get the last (alphabetically last, which is typically the newest) file

  if [ -z "$zip" ]; then
    echo "Error: GWT distribution ZIP file not found, run 'nix-build-gwt'." >&2
    exit 1
  fi
  export GWT_DIST_FILE=$zip
fi

echo "Using GWT distribution file: $GWT_DIST_FILE"

# Run the push-gwtproject.sh script in non-interactive mode
exec "${root}/maven/push-gwtproject.sh" "${@}" < /dev/null
