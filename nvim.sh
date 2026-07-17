#!/usr/bin/env bash
#
# nvim.sh - install Neovim locally under $HOME (no root required).
#
# Downloads the official static release tarball for the detected OS/CPU from
# GitHub into $HOME/bin/nvim-<version> and points a stable $HOME/bin/nvim symlink
# at it. Runs unchanged on Linux/macOS, x86_64/arm64. The download/install/link
# mechanics live in install_versioned_tool (lib.sh).
#
# Usage:
#   ./nvim.sh                       # install the pinned version
#   NVIM_VERSION=0.11.3 ./nvim.sh   # install a specific version
#   FORCE=1 ./nvim.sh               # reinstall even if already present
#   DRY_RUN=1 ./nvim.sh             # show what would happen; download nothing

set -euo pipefail

# Shared helpers (install_versioned_tool/msg/die/...), kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

readonly VERSION="${NVIM_VERSION:-0.12.4}"
readonly BIN_DIR="${BIN_DIR:-${HOME}/bin}"

# Map this machine to the Neovim release asset name.
detect_asset() {
   local os cpu
   case "$(uname -s)" in
      Linux)  os="linux" ;;
      Darwin) os="macos" ;;
      *)      die "Unsupported operating system: $(uname -s)" ;;
   esac
   case "$(uname -m)" in
      x86_64 | amd64)  cpu="x86_64" ;;
      aarch64 | arm64) cpu="arm64" ;;
      *)               die "Unsupported architecture: $(uname -m)" ;;
   esac
   printf 'nvim-%s-%s.tar.gz' "${os}" "${cpu}"
}

asset="$(detect_asset)"
install_versioned_tool "Neovim" "${VERSION}" \
   "https://github.com/neovim/neovim/releases/download/v${VERSION}/${asset}" \
   "${BIN_DIR}/nvim-${VERSION}" \
   stage_tarball_strip "" \
   "nvim=bin/nvim"
