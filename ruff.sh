#!/usr/bin/env bash
#
# ruff.sh - install the Ruff Python linter + formatter locally (no root).
#
# pyright only type-checks; Ruff adds fast linting and formatting. init.lua
# runs it as a language server (`ruff server`) alongside pyright. Downloads the
# official binary from GitHub releases into $HOME/bin - the Linux build is
# statically linked (musl), so it runs on any Linux regardless of glibc. The
# download/install/link mechanics live in install_versioned_tool (lib.sh).
# https://docs.astral.sh/ruff/
#
# Usage:
#   ./ruff.sh
#   RUFF_VERSION=0.15.0 ./ruff.sh
#   FORCE=1 ./ruff.sh
#   DRY_RUN=1 ./ruff.sh

set -euo pipefail

# Shared helpers (install_versioned_tool/msg/die/...), kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

readonly VERSION="${RUFF_VERSION:-0.15.21}"
readonly BIN_DIR="${BIN_DIR:-${HOME}/bin}"

# Map this machine to the Ruff release asset name.
detect_asset() {
   local cpu target
   case "$(uname -m)" in
      x86_64 | amd64)  cpu="x86_64" ;;
      aarch64 | arm64) cpu="aarch64" ;;
      *)               die "Unsupported architecture: $(uname -m)" ;;
   esac
   case "$(uname -s)" in
      Linux)  target="unknown-linux-musl" ;;
      Darwin) target="apple-darwin" ;;
      *)      die "Unsupported operating system: $(uname -s)" ;;
   esac
   printf 'ruff-%s-%s.tar.gz' "${cpu}" "${target}"
}

# The tarball may or may not have a top-level directory, so extract (beside the
# download, in the scratch dir) then locate the ruff binary rather than assuming
# a layout.
stage_ruff() {
   require tar
   local scratch found
   scratch="$(dirname "$1")"
   tar -xzf "$1" -C "${scratch}"
   found="$(find "${scratch}" -type f -name ruff)"
   found="${found%%$'\n'*}"
   [[ -n "${found}" ]] || die "could not find the ruff binary in the archive"
   mv "${found}" "$2/ruff"
   chmod +x "$2/ruff"
}

asset="$(detect_asset)"
# Ruff release tags have no leading 'v'.
install_versioned_tool "Ruff" "${VERSION}" \
   "https://github.com/astral-sh/ruff/releases/download/${VERSION}/${asset}" \
   "${BIN_DIR}/ruff-${VERSION}" \
   stage_ruff "" \
   "ruff=ruff"
