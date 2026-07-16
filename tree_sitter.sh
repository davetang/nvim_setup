#!/usr/bin/env bash
#
# tree_sitter.sh - install the tree-sitter CLI locally under $HOME (no root).
#
# nvim-treesitter's main branch builds parsers with the tree-sitter CLI
# (>= 0.26.1), and its README says to install it from a package manager, NOT
# npm. So we download the official prebuilt binary from GitHub releases and
# drop it in $HOME/bin, the same way as nvim.sh / node.sh. A C compiler must
# also be on PATH for the parser build itself (that we don't install).
#
# Usage:
#   ./tree_sitter.sh                          # install the pinned version
#   TREE_SITTER_VERSION=0.26.1 ./tree_sitter.sh   # install a specific version
#   FORCE=1 ./tree_sitter.sh                  # reinstall even if present
#   DRY_RUN=1 ./tree_sitter.sh                # show what would happen; no download

set -euo pipefail

# Shared helpers, kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# --- configuration ----------------------------------------------------------

# Version to install. Override with the TREE_SITTER_VERSION environment var.
readonly VERSION="${TREE_SITTER_VERSION:-0.26.11}"

readonly BIN_DIR="${BIN_DIR:-${HOME}/bin}"
readonly INSTALL_DIR="${BIN_DIR}/tree-sitter-${VERSION}"
readonly SYMLINK="${BIN_DIR}/tree-sitter"

# --- helpers ----------------------------------------------------------------

# Map `uname` output to the tree-sitter release asset name for this machine.
detect_asset() {
   local kernel arch os cpu
   kernel="$(uname -s)"
   arch="$(uname -m)"

   case "${kernel}" in
      Linux)  os="linux" ;;
      Darwin) os="macos" ;;
      *)      die "Unsupported operating system: ${kernel}" ;;
   esac

   case "${arch}" in
      x86_64 | amd64)  cpu="x64" ;;
      aarch64 | arm64) cpu="arm64" ;;
      *)               die "Unsupported architecture: ${arch}" ;;
   esac

   printf 'tree-sitter-%s-%s.gz' "${os}" "${cpu}"
}

# Point ${BIN_DIR}/tree-sitter at the freshly installed version.
link_current() {
   ln -sf "${INSTALL_DIR}/tree-sitter" "${SYMLINK}"
   msg "Linked ${SYMLINK} -> ${INSTALL_DIR}/tree-sitter"
   warn_if_not_on_path "${BIN_DIR}"
}

# --- main -------------------------------------------------------------------

main() {
   require gzip

   local asset url
   asset="$(detect_asset)"
   url="https://github.com/tree-sitter/tree-sitter/releases/download/v${VERSION}/${asset}"

   msg "tree-sitter : v${VERSION}"
   msg "Platform    : $(uname -s) $(uname -m) -> ${asset}"
   msg "Source      : ${url}"
   msg "Target      : ${INSTALL_DIR}/tree-sitter"

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

   # The release asset is a single gzipped binary (not a tarball).
   msg "Installing into ${INSTALL_DIR} ..."
   rm -rf "${INSTALL_DIR}"
   mkdir -p "${INSTALL_DIR}"
   gzip -dc "${tmp}/${asset}" > "${INSTALL_DIR}/tree-sitter"
   chmod +x "${INSTALL_DIR}/tree-sitter"

   link_current

   local version_line
   if version_line="$("${INSTALL_DIR}/tree-sitter" --version 2>/dev/null | head -n 1)"; then
      msg "Installed: ${version_line}"
   else
      msg "Installed to ${INSTALL_DIR} (run '${SYMLINK} --version' to verify)"
   fi
   msg "Done."
}

main "$@"
