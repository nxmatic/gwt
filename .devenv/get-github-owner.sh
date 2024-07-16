#!/usr/bin/env bash -e -o pipefail

url=$(git config --get remote.origin.url)
if [[ $url =~ github\.com[:/]([^/]+) ]]; then
    echo "${BASH_REMATCH[1]}" ||
else
  echo "Unable to extract GitHub owner from URL: $url" >&2
  exit 1
fi

