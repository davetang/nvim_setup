#!/usr/bin/env bash
#
# node.sh - install Node.js locally under $HOME (no root required).
#
# Node.js provides `npm`, which the Bash and Python language servers install
# through. Downloads the official binary tarball for the detected operating
# system and CPU architecture from nodejs.org, installs it to
# $HOME/bin/node-<version>, and points stable $HOME/bin/{node,npm,npx}
# symlinks at it. Designed to run unchanged on any of my workstations
# (Linux/macOS, x86_64/arm64).
#
# Usage:
#   ./node.sh                        # install the pinned LTS version
#   NODE_VERSION=22.11.0 ./node.sh   # install a specific version
#   FORCE=1 ./node.sh                # reinstall even if already present
#   DRY_RUN=1 ./node.sh              # show what would happen; download nothing

set -euo pipefail

# Shared helpers (msg/die/require/download/cleanup/...), kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# --- configuration ----------------------------------------------------------

# Version to install (an LTS release). Override with the NODE_VERSION env var.
readonly VERSION="${NODE_VERSION:-24.18.0}"

# Where the versioned install lives and where the stable symlinks are created.
readonly BIN_DIR="${BIN_DIR:-${HOME}/bin}"
readonly INSTALL_DIR="${BIN_DIR}/node-${VERSION}"

# Commands provided by Node that we expose via ${BIN_DIR}.
readonly TOOLS=(node npm npx)

# --- helpers ----------------------------------------------------------------

# Map `uname` output to the Node.js release asset name for this machine.
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
      x86_64 | amd64)  cpu="x64" ;;
      aarch64 | arm64) cpu="arm64" ;;
      *)               die "Unsupported architecture: ${arch}" ;;
   esac

   printf 'node-v%s-%s-%s.tar.gz' "${VERSION}" "${os}" "${cpu}"
}

# Link node/npm/npx from ${BIN_DIR} to the freshly installed version.
link_current() {
   local tool
   for tool in "${TOOLS[@]}"; do
      ln -sf "${INSTALL_DIR}/bin/${tool}" "${BIN_DIR}/${tool}"
      msg "Linked ${BIN_DIR}/${tool} -> ${INSTALL_DIR}/bin/${tool}"
   done
   warn_if_not_on_path "${BIN_DIR}"
}

# --- main -------------------------------------------------------------------

main() {
   require tar

   local asset base_url tarball_url
   asset="$(detect_asset)"
   base_url="https://nodejs.org/dist/v${VERSION}"
   tarball_url="${base_url}/${asset}"

   msg "Node.js  : v${VERSION}"
   msg "Platform : $(uname -s) $(uname -m) -> ${asset}"
   msg "Source   : ${tarball_url}"
   msg "Target   : ${INSTALL_DIR}"

   if [[ -n "${DRY_RUN:-}" ]]; then
      msg "DRY_RUN set; nothing was downloaded or installed."
      return 0
   fi

   # Already installed? Just refresh the symlinks, unless FORCE is set.
   if [[ -d "${INSTALL_DIR}" && -z "${FORCE:-}" ]]; then
      msg "${INSTALL_DIR} already exists; skipping download (set FORCE=1 to reinstall)."
      link_current
      return 0
   fi

   mkdir -p "${BIN_DIR}"

   tmp="$(mktemp -d)"

   msg "Downloading ${asset} ..."
   download "${tarball_url}" "${tmp}/${asset}"

   # Node's tarball has a single top-level directory (e.g.
   # node-v24.18.0-linux-x64/); --strip-components=1 drops it so the contents
   # land directly in INSTALL_DIR as bin/, lib/, include/, share/.
   msg "Extracting into ${INSTALL_DIR} ..."
   rm -rf "${INSTALL_DIR}"
   mkdir -p "${INSTALL_DIR}"
   tar -xzf "${tmp}/${asset}" -C "${INSTALL_DIR}" --strip-components=1

   link_current

   local node_bin="${INSTALL_DIR}/bin/node"
   if [[ -x "${node_bin}" ]]; then
      local node_v npm_v
      node_v="$("${node_bin}" --version 2>/dev/null || echo '?')"
      # npm's shebang is `env node`, so put this Node on PATH to run it.
      npm_v="$(PATH="${INSTALL_DIR}/bin:${PATH}" "${INSTALL_DIR}/bin/npm" --version 2>/dev/null || echo '?')"
      msg "Installed: node ${node_v}, npm ${npm_v}"
   else
      msg "Installed to ${INSTALL_DIR} (run '${BIN_DIR}/node --version' to verify)"
   fi
   msg "Done."
}

main "$@"
