#!/usr/bin/env bash
#
# cargo.sh - install the Rust toolchain (cargo + rustc) locally, no root.
#
# Uses rustup with a minimal profile, into ~/.rustup and ~/.cargo, then links
# cargo/rustc/rustup into $HOME/bin. Needed to build tools from source - e.g.
# the tree-sitter CLI (`TREE_SITTER_METHOD=cargo make tree-sitter`) on machines
# whose glibc is older than the prebuilt tree-sitter binary requires.
#
# Usage:
#   ./cargo.sh
#   FORCE=1 ./cargo.sh   # re-run the rustup installer even if cargo is present

set -euo pipefail

# Shared helpers, kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

readonly BIN_DIR="${BIN_DIR:-${HOME}/bin}"
export RUSTUP_HOME="${RUSTUP_HOME:-${HOME}/.rustup}"
export CARGO_HOME="${CARGO_HOME:-${HOME}/.cargo}"

# Commands to expose via ${BIN_DIR}.
readonly TOOLS=(cargo rustc rustup)

main() {
   if command -v cargo >/dev/null 2>&1 && [[ -z "${FORCE:-}" ]]; then
      msg "cargo already available: $(cargo --version)"
   else
      msg "Installing Rust via rustup (no root, minimal profile) ..."
      if command -v curl >/dev/null 2>&1; then
         curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
            | sh -s -- -y --no-modify-path --profile minimal
      elif command -v wget >/dev/null 2>&1; then
         wget -qO- https://sh.rustup.rs \
            | sh -s -- -y --no-modify-path --profile minimal
      else
         die "need curl or wget to fetch the rustup installer"
      fi
   fi

   # Expose cargo/rustc/rustup via ${BIN_DIR} (which is on PATH), matching this
   # setup's layout - rustup itself installs them under ${CARGO_HOME}/bin.
   mkdir -p "${BIN_DIR}"
   local tool
   for tool in "${TOOLS[@]}"; do
      if [[ -x "${CARGO_HOME}/bin/${tool}" ]]; then
         ln -sf "${CARGO_HOME}/bin/${tool}" "${BIN_DIR}/${tool}"
         msg "Linked ${BIN_DIR}/${tool} -> ${CARGO_HOME}/bin/${tool}"
      fi
   done

   warn_if_not_on_path "${BIN_DIR}"
   msg "Installed: $("${CARGO_HOME}/bin/cargo" --version 2>/dev/null || echo '?')"
   msg "Done."
}

main "$@"
