#!/usr/bin/env bash
#
# node.sh - install Node.js locally under $HOME (no root required).
#
# Node.js provides `npm`, which the Bash and Python language servers install
# through. Downloads the official binary tarball for the detected OS/CPU from
# nodejs.org into $HOME/bin/node-<version> and points stable
# $HOME/bin/{node,npm,npx} symlinks at it. Runs unchanged on Linux/macOS,
# x86_64/arm64. The download/install/link mechanics live in
# install_versioned_tool (lib.sh).
#
# Usage:
#   ./node.sh                        # install the pinned LTS version
#   NODE_VERSION=22.11.0 ./node.sh   # install a specific version
#   FORCE=1 ./node.sh                # reinstall even if already present
#   DRY_RUN=1 ./node.sh              # show what would happen; download nothing

set -euo pipefail

# Shared helpers (install_versioned_tool/msg/die/...), kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

readonly VERSION="${NODE_VERSION:-24.18.0}"
readonly BIN_DIR="${BIN_DIR:-${HOME}/bin}"

# Map this machine to the Node.js release asset name.
detect_asset() {
   local os cpu
   case "$(uname -s)" in
      Linux)  os="linux" ;;
      Darwin) os="darwin" ;;
      *)      die "Unsupported operating system: $(uname -s)" ;;
   esac
   case "$(uname -m)" in
      x86_64 | amd64)  cpu="x64" ;;
      aarch64 | arm64) cpu="arm64" ;;
      *)               die "Unsupported architecture: $(uname -m)" ;;
   esac
   printf 'node-v%s-%s-%s.tar.gz' "${VERSION}" "${os}" "${cpu}"
}

# Report both node and npm. npm's shebang is `env node`, so put this Node on
# PATH to run it.
verify_node() {
   local install_dir="$1" nv npmv
   nv="$("${install_dir}/bin/node" --version 2>/dev/null || echo '?')"
   npmv="$(PATH="${install_dir}/bin:${PATH}" "${install_dir}/bin/npm" --version 2>/dev/null || echo '?')"
   msg "Installed: node ${nv}, npm ${npmv}"
}

asset="$(detect_asset)"
install_versioned_tool "Node.js" "${VERSION}" \
   "https://nodejs.org/dist/v${VERSION}/${asset}" \
   "${BIN_DIR}/node-${VERSION}" \
   stage_tarball_strip verify_node \
   "node=bin/node" "npm=bin/npm" "npx=bin/npx"
