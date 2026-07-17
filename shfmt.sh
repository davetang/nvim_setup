#!/usr/bin/env bash
#
# shfmt.sh - install the shfmt shell formatter locally under $HOME (no root).
#
# bash-language-server uses shfmt for formatting, so having it on PATH makes
# `<leader>f` work on shell scripts. The release asset is a single static
# binary (no archive). The download/install/link mechanics live in
# install_versioned_tool (lib.sh). https://github.com/mvdan/sh
#
# Usage:
#   ./shfmt.sh
#   SHFMT_VERSION=3.10.0 ./shfmt.sh
#   FORCE=1 ./shfmt.sh
#   DRY_RUN=1 ./shfmt.sh

set -euo pipefail

# Shared helpers (install_versioned_tool/msg/die/...), kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

readonly VERSION="${SHFMT_VERSION:-3.13.1}"
readonly BIN_DIR="${BIN_DIR:-${HOME}/bin}"

# Map this machine to the shfmt release asset name.
detect_asset() {
   local os cpu
   case "$(uname -s)" in
      Linux)  os="linux" ;;
      Darwin) os="darwin" ;;
      *)      die "Unsupported operating system: $(uname -s)" ;;
   esac
   case "$(uname -m)" in
      x86_64 | amd64)  cpu="amd64" ;;
      aarch64 | arm64) cpu="arm64" ;;
      *)               die "Unsupported architecture: $(uname -m)" ;;
   esac
   printf 'shfmt_v%s_%s_%s' "${VERSION}" "${os}" "${cpu}"
}

# The release asset is a bare binary, not an archive: just place and chmod it.
stage_shfmt() {
   mv "$1" "$2/shfmt"
   chmod +x "$2/shfmt"
}

asset="$(detect_asset)"
install_versioned_tool "shfmt" "${VERSION}" \
   "https://github.com/mvdan/sh/releases/download/v${VERSION}/${asset}" \
   "${BIN_DIR}/shfmt-${VERSION}" \
   stage_shfmt "" \
   "shfmt=shfmt"
