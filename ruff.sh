#!/usr/bin/env bash
#
# ruff.sh - install the Ruff Python linter + formatter locally (no root).
#
# pyright only type-checks; Ruff adds fast linting and formatting. init.lua
# runs it as a language server (`ruff server`) alongside pyright. Downloads the
# official binary from GitHub releases into $HOME/bin - the Linux build is
# statically linked (musl), so it runs on any Linux regardless of glibc.
# https://docs.astral.sh/ruff/
#
# Usage:
#   ./ruff.sh
#   RUFF_VERSION=0.15.0 ./ruff.sh
#   FORCE=1 ./ruff.sh
#   DRY_RUN=1 ./ruff.sh

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

readonly VERSION="${RUFF_VERSION:-0.15.21}"
readonly BIN_DIR="${BIN_DIR:-${HOME}/bin}"
readonly INSTALL_DIR="${BIN_DIR}/ruff-${VERSION}"
readonly SYMLINK="${BIN_DIR}/ruff"

detect_asset() {
   local kernel arch target cpu
   kernel="$(uname -s)"
   arch="$(uname -m)"
   case "${arch}" in
      x86_64 | amd64)  cpu="x86_64" ;;
      aarch64 | arm64) cpu="aarch64" ;;
      *)               die "Unsupported architecture: ${arch}" ;;
   esac
   case "${kernel}" in
      Linux)  target="unknown-linux-musl" ;;
      Darwin) target="apple-darwin" ;;
      *)      die "Unsupported operating system: ${kernel}" ;;
   esac
   printf 'ruff-%s-%s.tar.gz' "${cpu}" "${target}"
}

link_current() {
   ln -sf "${INSTALL_DIR}/ruff" "${SYMLINK}"
   msg "Linked ${SYMLINK} -> ${INSTALL_DIR}/ruff"
   warn_if_not_on_path "${BIN_DIR}"
}

main() {
   require tar

   local asset url
   asset="$(detect_asset)"
   # Ruff release tags have no leading 'v'.
   url="https://github.com/astral-sh/ruff/releases/download/${VERSION}/${asset}"

   msg "Ruff     : v${VERSION}"
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
   download "${url}" "${tmp}/${asset}"

   # The tarball may or may not have a top-level directory, so extract then
   # locate the ruff binary rather than assuming a layout.
   tar -xzf "${tmp}/${asset}" -C "${tmp}"
   local extracted
   extracted="$(find "${tmp}" -type f -name ruff | head -n 1)"
   [[ -n "${extracted}" ]] || die "could not find the ruff binary in the archive"

   rm -rf "${INSTALL_DIR}"
   mkdir -p "${INSTALL_DIR}"
   mv "${extracted}" "${INSTALL_DIR}/ruff"
   chmod +x "${INSTALL_DIR}/ruff"

   link_current
   msg "Installed: $("${INSTALL_DIR}/ruff" --version 2>/dev/null || true)"
   msg "Done."
}

main "$@"
