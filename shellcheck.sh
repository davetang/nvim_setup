#!/usr/bin/env bash
#
# shellcheck.sh - install the ShellCheck linter locally under $HOME (no root).
#
# bash-language-server automatically uses ShellCheck for diagnostics, so just
# having it on PATH makes the Bash LSP actually flag problems. Downloads the
# official static binary from GitHub releases into $HOME/bin.
# https://www.shellcheck.net
#
# Usage:
#   ./shellcheck.sh
#   SHELLCHECK_VERSION=0.10.0 ./shellcheck.sh
#   FORCE=1 ./shellcheck.sh
#   DRY_RUN=1 ./shellcheck.sh

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

readonly VERSION="${SHELLCHECK_VERSION:-0.11.0}"
readonly BIN_DIR="${BIN_DIR:-${HOME}/bin}"
readonly INSTALL_DIR="${BIN_DIR}/shellcheck-${VERSION}"
readonly SYMLINK="${BIN_DIR}/shellcheck"

detect_asset() {
   local kernel arch os cpu
   kernel="$(uname -s)"
   arch="$(uname -m)"
   case "${kernel}" in
      Linux)  os="linux" ;;
      Darwin) os="darwin" ;;
      *)      die "Unsupported operating system: ${kernel}" ;;
   esac
   case "${arch}" in
      x86_64 | amd64)  cpu="x86_64" ;;
      aarch64 | arm64) cpu="aarch64" ;;
      *)               die "Unsupported architecture: ${arch}" ;;
   esac
   printf 'shellcheck-v%s.%s.%s.tar.gz' "${VERSION}" "${os}" "${cpu}"
}

link_current() {
   ln -sf "${INSTALL_DIR}/shellcheck" "${SYMLINK}"
   msg "Linked ${SYMLINK} -> ${INSTALL_DIR}/shellcheck"
   warn_if_not_on_path "${BIN_DIR}"
}

main() {
   require tar

   local asset url
   asset="$(detect_asset)"
   url="https://github.com/koalaman/shellcheck/releases/download/v${VERSION}/${asset}"

   msg "ShellCheck : v${VERSION}"
   msg "Platform   : $(uname -s) $(uname -m) -> ${asset}"
   msg "Source     : ${url}"
   msg "Target     : ${INSTALL_DIR}"

   if [[ -n "${DRY_RUN:-}" ]]; then
      msg "DRY_RUN set; nothing was downloaded or installed."
      return 0
   fi

   if [[ -d "${INSTALL_DIR}" && -z "${FORCE:-}" ]]; then
      msg "${INSTALL_DIR} already exists; skipping download (set FORCE=1 to reinstall)."
      link_current
      return 0
   fi

   mkdir -p "${BIN_DIR}"
   tmp="$(mktemp -d)"

   msg "Downloading ${asset} ..."
   download "${url}" "${tmp}/${asset}"

   # The tarball's top-level directory is shellcheck-v<version>/;
   # --strip-components=1 drops it so the binary lands in INSTALL_DIR.
   rm -rf "${INSTALL_DIR}"
   mkdir -p "${INSTALL_DIR}"
   tar -xzf "${tmp}/${asset}" -C "${INSTALL_DIR}" --strip-components=1

   link_current
   msg "Installed: $("${INSTALL_DIR}/shellcheck" --version 2>/dev/null | grep -m1 'version:' || true)"
   msg "Done."
}

main "$@"
