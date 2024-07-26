#!/usr/bin/env -S bash -ex -o pipefail

process_branch_name() {
  local BRANCH_NAME=$1
  local PR_BASE_REF=$2  # Add this parameter for pull request base branch

  # Check if it's a pull request
  if [[ -n "$PR_BASE_REF" ]]; then
    # Use the base branch of the pull request
    BRANCH_NAME=$PR_BASE_REF
  fi

  case "$BRANCH_NAME" in
    main)
      echo "0.0.0-dev"
      ;;
    *-nuxeo | *-test)
      echo "${BRANCH_NAME}"
      ;;
    *)
      echo "Unsupported branch name: $BRANCH_NAME" >&2
      return 1
      ;;
  esac
}

# Always try to get the current Git branch first
if BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD 2>/dev/null); then
  if [[ "$BRANCH_NAME" != "HEAD" ]]; then
    process_branch_name "$BRANCH_NAME"
    exit 0
  fi
fi

# Fall back to GITHUB_REF if we couldn't get the branch from Git
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
  echo "Unable to determine version: no Git branch and no GITHUB_REF" >&2
  exit 1
fi
