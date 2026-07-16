#!/usr/bin/env bash
#
# nvim.sh - install Neovim locally under $HOME (no root required).
#
# Downloads the official static release tarball for the detected operating
# system and CPU architecture from GitHub, installs it to
# $HOME/bin/nvim-<version>, and points a stable $HOME/bin/nvim symlink at it.
# Designed to run unchanged on any of my workstations (Linux/macOS,
# x86_64/arm64).
#
# Usage:
#   ./nvim.sh                       # install the pinned version
#   NVIM_VERSION=0.11.3 ./nvim.sh   # install a specific version
#   FORCE=1 ./nvim.sh               # reinstall even if already present
#   DRY_RUN=1 ./nvim.sh             # show what would happen; download nothing

set -euo pipefail

# Shared helpers (msg/die/require/download/cleanup/...), kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# --- configuration ----------------------------------------------------------

# Version to install. Override with the NVIM_VERSION environment variable.
readonly VERSION="${NVIM_VERSION:-0.12.4}"

# Where versioned installs live and where the stable symlink is created.
readonly BIN_DIR="${BIN_DIR:-${HOME}/bin}"
readonly INSTALL_DIR="${BIN_DIR}/nvim-${VERSION}"
readonly SYMLINK="${BIN_DIR}/nvim"

# --- helpers ----------------------------------------------------------------

# Map `uname` output to the Neovim release asset name for this machine.
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
      x86_64 | amd64)  cpu="x86_64" ;;
      aarch64 | arm64) cpu="arm64" ;;
      *)               die "Unsupported architecture: ${arch}" ;;
   esac

   printf 'nvim-%s-%s.tar.gz' "${os}" "${cpu}"
}

# Point ${BIN_DIR}/nvim at the freshly installed version.
link_current() {
   ln -sf "${INSTALL_DIR}/bin/nvim" "${SYMLINK}"
   msg "Linked ${SYMLINK} -> ${INSTALL_DIR}/bin/nvim"
   warn_if_not_on_path "${BIN_DIR}"
}

# --- main -------------------------------------------------------------------

main() {
   require tar

   local asset base_url tarball_url
   asset="$(detect_asset)"
   base_url="https://github.com/neovim/neovim/releases/download/v${VERSION}"
   tarball_url="${base_url}/${asset}"

   msg "Neovim   : v${VERSION}"
   msg "Platform : $(uname -s) $(uname -m) -> ${asset}"
   msg "Source   : ${tarball_url}"
   msg "Target   : ${INSTALL_DIR}"

   if [[ -n "${DRY_RUN:-}" ]]; then
      msg "DRY_RUN set; nothing was downloaded or installed."
      return 0
   fi

   # Already installed? Just refresh the symlink, unless FORCE is set.
   if [[ -d "${INSTALL_DIR}" && -z "${FORCE:-}" ]]; then
      msg "${INSTALL_DIR} already exists; skipping download (set FORCE=1 to reinstall)."
      link_current
      return 0
   fi

   mkdir -p "${BIN_DIR}"

   tmp="$(mktemp -d)"

   msg "Downloading ${asset} ..."
   download "${tarball_url}" "${tmp}/${asset}"

   # Neovim's tarball has a single top-level directory (e.g.
   # nvim-linux-x86_64/); --strip-components=1 drops it so the contents land
   # directly in INSTALL_DIR as bin/, lib/, share/.
   msg "Extracting into ${INSTALL_DIR} ..."
   rm -rf "${INSTALL_DIR}"
   mkdir -p "${INSTALL_DIR}"
   tar -xzf "${tmp}/${asset}" -C "${INSTALL_DIR}" --strip-components=1

   link_current

   local version_line
   if version_line="$("${INSTALL_DIR}/bin/nvim" --version 2>/dev/null | head -n 1)"; then
      msg "Installed: ${version_line}"
   else
      msg "Installed to ${INSTALL_DIR} (run '${SYMLINK} --version' to verify)"
   fi
   msg "Done."
}

main "$@"
