#!/usr/bin/env bash
#
# fzf.sh - install the fzf command-line fuzzy finder locally under $HOME (no
# root).
#
# fzf is a general-purpose fuzzy finder for the shell (fuzzy Ctrl-R history,
# file pickers, piping any list through it to narrow it down). Nothing in the
# Neovim config depends on it - it's a standalone convenience - so, like
# `make screen`, it is opt-in and not part of `make install`. Downloads the
# official static binary from GitHub releases into $HOME/bin; the release asset
# is a tarball wrapping a single `fzf` binary. The download/install/link
# mechanics live in install_versioned_tool (lib.sh).
# https://github.com/junegunn/fzf
#
# The binary alone gives you the `fzf` command. For the shell keybindings
# (Ctrl-T, Ctrl-R, Alt-C) and completion, also add to your shell rc:
#   source <(fzf --bash)      # or --zsh / --fish
#
# Usage:
#   ./fzf.sh
#   FZF_VERSION=0.74.1 ./fzf.sh
#   FORCE=1 ./fzf.sh
#   DRY_RUN=1 ./fzf.sh

set -euo pipefail

# Shared helpers (install_versioned_tool/msg/die/...), kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

readonly VERSION="${FZF_VERSION:-0.74.1}"
readonly BIN_DIR="${BIN_DIR:-${HOME}/bin}"

# Map this machine to the fzf release asset name.
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
   printf 'fzf-%s-%s_%s.tar.gz' "${VERSION}" "${os}" "${cpu}"
}

# The release tarball holds a single `fzf` binary at its root (no wrapping
# directory to strip), so extract it straight into the install dir.
stage_fzf() {
   require tar
   tar -xzf "$1" -C "$2"
}

asset="$(detect_asset)"
install_versioned_tool "fzf" "${VERSION}" \
   "https://github.com/junegunn/fzf/releases/download/v${VERSION}/${asset}" \
   "${BIN_DIR}/fzf-${VERSION}" \
   stage_fzf "" \
   "fzf=fzf"
