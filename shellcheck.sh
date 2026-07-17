#!/usr/bin/env bash
#
# shellcheck.sh - install the ShellCheck linter locally under $HOME (no root).
#
# bash-language-server automatically uses ShellCheck for diagnostics, so just
# having it on PATH makes the Bash LSP actually flag problems. Downloads the
# official static binary from GitHub releases into $HOME/bin. The
# download/install/link mechanics live in install_versioned_tool (lib.sh).
# https://www.shellcheck.net
#
# Usage:
#   ./shellcheck.sh
#   SHELLCHECK_VERSION=0.10.0 ./shellcheck.sh
#   FORCE=1 ./shellcheck.sh
#   DRY_RUN=1 ./shellcheck.sh

set -euo pipefail

# Shared helpers (install_versioned_tool/msg/die/...), kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

readonly VERSION="${SHELLCHECK_VERSION:-0.11.0}"
readonly BIN_DIR="${BIN_DIR:-${HOME}/bin}"

# Map this machine to the ShellCheck release asset name.
detect_asset() {
   local os cpu
   case "$(uname -s)" in
      Linux)  os="linux" ;;
      Darwin) os="darwin" ;;
      *)      die "Unsupported operating system: $(uname -s)" ;;
   esac
   case "$(uname -m)" in
      x86_64 | amd64)  cpu="x86_64" ;;
      aarch64 | arm64) cpu="aarch64" ;;
      *)               die "Unsupported architecture: $(uname -m)" ;;
   esac
   printf 'shellcheck-v%s.%s.%s.tar.gz' "${VERSION}" "${os}" "${cpu}"
}

# shellcheck --version puts the version on a 'version:' line, not the first.
verify_shellcheck() {
   msg "Installed: $("$1/shellcheck" --version 2>/dev/null | grep -m1 'version:' || true)"
}

asset="$(detect_asset)"
install_versioned_tool "ShellCheck" "${VERSION}" \
   "https://github.com/koalaman/shellcheck/releases/download/v${VERSION}/${asset}" \
   "${BIN_DIR}/shellcheck-${VERSION}" \
   stage_tarball_strip verify_shellcheck \
   "shellcheck=shellcheck"
