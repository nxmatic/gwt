#!/usr/bin/env -S bash -e -o pipefail

[[ -n "${RUNNER_DEBUG}" ]] &&
  set -x

process_branch_name() {
  local BRANCH_NAME=$1
  if [[ $BRANCH_NAME =~ ^[0-9]+\.[0-9]+\.[0-9]+-nuxeo$ ]]; then
    echo "${BRANCH_NAME}-beta"
  else
    echo "Unable to determine version from branch name: $BRANCH_NAME" >&2
    return 1
  fi
}

if [ -n "$GITHUB_REF" ]; then
  case $GITHUB_REF in
    refs/tags/*)
      echo "${GITHUB_REF#refs/tags/}"
      ;;
    refs/heads/*)
      process_branch_name "${GITHUB_REF#refs/heads/}"
      ;;
    *)
      echo "Unsupported GITHUB_REF: $GITHUB_REF" >&2
      exit 1
      ;;
  esac
else
  if TAG=$(git describe --exact-match --tags HEAD 2>/dev/null); then
    echo "$TAG"
  else
    BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
    process_branch_name "$BRANCH_NAME"
  fi
fi
