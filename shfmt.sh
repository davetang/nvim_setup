#!/usr/bin/env bash
#
# shfmt.sh - install the shfmt shell formatter locally under $HOME (no root).
#
# bash-language-server uses shfmt for formatting, so having it on PATH makes
# `<leader>f` work on shell scripts. The release asset is a single static
# binary (no archive). https://github.com/mvdan/sh
#
# Usage:
#   ./shfmt.sh
#   SHFMT_VERSION=3.10.0 ./shfmt.sh
#   FORCE=1 ./shfmt.sh
#   DRY_RUN=1 ./shfmt.sh

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

readonly VERSION="${SHFMT_VERSION:-3.13.1}"
readonly BIN_DIR="${BIN_DIR:-${HOME}/bin}"
readonly INSTALL_DIR="${BIN_DIR}/shfmt-${VERSION}"
readonly SYMLINK="${BIN_DIR}/shfmt"

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
      x86_64 | amd64)  cpu="amd64" ;;
      aarch64 | arm64) cpu="arm64" ;;
      *)               die "Unsupported architecture: ${arch}" ;;
   esac
   printf 'shfmt_v%s_%s_%s' "${VERSION}" "${os}" "${cpu}"
}

link_current() {
   ln -sf "${INSTALL_DIR}/shfmt" "${SYMLINK}"
   msg "Linked ${SYMLINK} -> ${INSTALL_DIR}/shfmt"
   warn_if_not_on_path "${BIN_DIR}"
}

main() {
   local asset url
   asset="$(detect_asset)"
   url="https://github.com/mvdan/sh/releases/download/v${VERSION}/${asset}"

   msg "shfmt    : v${VERSION}"
   msg "Platform : $(uname -s) $(uname -m) -> ${asset}"
   msg "Source   : ${url}"
   msg "Target   : ${INSTALL_DIR}"

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
   download "${url}" "${tmp}/shfmt"

   # The asset is a bare binary, not an archive.
   rm -rf "${INSTALL_DIR}"
   mkdir -p "${INSTALL_DIR}"
   mv "${tmp}/shfmt" "${INSTALL_DIR}/shfmt"
   chmod +x "${INSTALL_DIR}/shfmt"

   link_current
   msg "Installed: shfmt $("${INSTALL_DIR}/shfmt" --version 2>/dev/null || true)"
   msg "Done."
}

main "$@"
