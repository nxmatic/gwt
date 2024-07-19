#!/usr/bin/env -S bash -e -o pipefail

git describe --exact-match --tags HEAD >/dev/null 2>&1 &&
  git rev-parse --short HEAD 2>/dev/null || echo "0000000"
