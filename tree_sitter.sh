#!/usr/bin/env bash
#
# tree_sitter.sh - install the tree-sitter CLI locally under $HOME (no root).
#
# nvim-treesitter's main branch builds parsers with the tree-sitter CLI
# (>= 0.26.1). Two install methods:
#
#   prebuilt (default) - download the official static binary from GitHub.
#     Fast, but the Linux binary needs a recent glibc (2.39+, Ubuntu 24.04).
#   conda              - install the conda-forge tree-sitter-cli package
#     (TREE_SITTER_METHOD=conda). Prebuilt, runs on old glibc, no compiling -
#     the easy fix on Miniforge/conda machines. Needs an active conda env;
#     installs into it and links the binary into ~/bin.
#   cargo              - build from source with cargo (TREE_SITTER_METHOD=cargo).
#     A last resort for old glibc without conda: needs cargo (`make cargo`), a C
#     compiler, and libclang, which can be fiddly.
#
# A C compiler must also be on PATH for the parser builds nvim-treesitter does.
#
# Usage:
#   ./tree_sitter.sh                            # prebuilt (pinned version)
#   TREE_SITTER_METHOD=cargo ./tree_sitter.sh   # build from source with cargo
#   TREE_SITTER_VERSION=0.26.1 ./tree_sitter.sh
#   FORCE=1 ./tree_sitter.sh
#   DRY_RUN=1 ./tree_sitter.sh

set -euo pipefail

# Shared helpers, kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# --- configuration ----------------------------------------------------------

readonly VERSION="${TREE_SITTER_VERSION:-0.26.11}"
readonly METHOD="${TREE_SITTER_METHOD:-prebuilt}"

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

# Report the version, or warn (and point at the cargo method) if the binary was
# installed but cannot actually run here - usually an older glibc.
verify_runs() {
   local exe="$1"
   local version_line
   if version_line="$("${exe}" --version 2>/dev/null | head -n 1)"; then
      msg "Installed: ${version_line}"
   else
      msg "WARNING: tree-sitter was installed but does not run on this machine"
      msg "  (usually an older glibc than the prebuilt binary needs). Build it"
      msg "  from source instead:"
      msg "      make cargo && TREE_SITTER_METHOD=cargo make tree-sitter"
   fi
}

# --- prebuilt method --------------------------------------------------------

install_prebuilt() {
   require tar

   local asset url
   asset="$(detect_asset)"
   url="https://github.com/tree-sitter/tree-sitter/releases/download/v${VERSION}/${asset}"

   msg "tree-sitter : v${VERSION} (prebuilt binary)"
   msg "Platform    : $(uname -s) $(uname -m) -> ${asset}"
   msg "Source      : ${url}"
   msg "Target      : ${INSTALL_DIR}/tree-sitter"

   if [[ -n "${DRY_RUN:-}" ]]; then
      msg "DRY_RUN set; nothing was downloaded or installed."
      return 0
   fi

   if [[ -d "${INSTALL_DIR}" && -z "${FORCE:-}" ]]; then
      msg "${INSTALL_DIR} already exists; skipping download (set FORCE=1 to reinstall)."
      ln -sf "${INSTALL_DIR}/tree-sitter" "${SYMLINK}"
      msg "Linked ${SYMLINK} -> ${INSTALL_DIR}/tree-sitter"
      warn_if_not_on_path "${BIN_DIR}"
      verify_runs "${INSTALL_DIR}/tree-sitter"
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

   ln -sf "${INSTALL_DIR}/tree-sitter" "${SYMLINK}"
   msg "Linked ${SYMLINK} -> ${INSTALL_DIR}/tree-sitter"
   warn_if_not_on_path "${BIN_DIR}"

   verify_runs "${INSTALL_DIR}/tree-sitter"
   msg "Done."
}

# --- cargo method -----------------------------------------------------------

install_cargo() {
   local cargo_bin="${CARGO_HOME:-${HOME}/.cargo}/bin/tree-sitter"

   msg "tree-sitter : v${VERSION} (cargo build from source)"
   msg "Target      : ${cargo_bin}  (linked into ${BIN_DIR})"

   if [[ -n "${DRY_RUN:-}" ]]; then
      msg "DRY_RUN set; nothing was built or installed."
      return 0
   fi

   require cargo
   msg "Building tree-sitter-cli with cargo (compiles from source; takes a few minutes) ..."
   cargo install tree-sitter-cli --version "${VERSION}" --locked ${FORCE:+--force}

   [[ -x "${cargo_bin}" ]] || die "cargo did not produce ${cargo_bin}"

   mkdir -p "${BIN_DIR}"
   ln -sf "${cargo_bin}" "${SYMLINK}"
   msg "Linked ${SYMLINK} -> ${cargo_bin}"
   warn_if_not_on_path "${BIN_DIR}"

   verify_runs "${cargo_bin}"
   msg "Done."
}

# --- conda method -----------------------------------------------------------

install_conda() {
   msg "tree-sitter : v${VERSION} (conda-forge package)"
   msg "Method      : conda install -c conda-forge tree-sitter-cli, linked into ${BIN_DIR}"

   if [[ -n "${DRY_RUN:-}" ]]; then
      msg "DRY_RUN set; nothing was installed."
      return 0
   fi

   require conda
   [[ -n "${CONDA_PREFIX:-}" ]] || die "no active conda environment (CONDA_PREFIX is unset) - activate one first"
   local conda_bin="${CONDA_PREFIX}/bin/tree-sitter"

   msg "Installing tree-sitter-cli=${VERSION} from conda-forge into ${CONDA_PREFIX} ..."
   conda install -y -c conda-forge "tree-sitter-cli=${VERSION}"

   [[ -x "${conda_bin}" ]] || die "expected ${conda_bin} after installing, but it is missing"

   mkdir -p "${BIN_DIR}"
   ln -sf "${conda_bin}" "${SYMLINK}"
   msg "Linked ${SYMLINK} -> ${conda_bin}"
   warn_if_not_on_path "${BIN_DIR}"

   verify_runs "${conda_bin}"
   msg "Done."
}

# --- main -------------------------------------------------------------------

main() {
   case "${METHOD}" in
      prebuilt) install_prebuilt ;;
      conda)    install_conda ;;
      cargo)    install_cargo ;;
      *)        die "unknown TREE_SITTER_METHOD '${METHOD}' (use: prebuilt | conda | cargo)" ;;
   esac
}

main "$@"
