#!/usr/bin/env bash
#
# tree_sitter.sh - install the tree-sitter CLI from conda-forge (no root).
#
# nvim-treesitter's main branch builds parsers with the tree-sitter CLI
# (>= 0.26.1). This setup installs conda-forge's tree-sitter-cli into the active
# conda environment and links the binary into ~/bin. Conda (Miniforge) is a hard
# requirement of this setup - see the README: the conda-forge build is prebuilt,
# needs no compiler, and, unlike the official GitHub binary, runs on the older
# glibc found on many HPC/cluster nodes, so it is the one method that works
# everywhere.
#
# A C compiler must still be on PATH for the parser builds nvim-treesitter does
# at first launch.
#
# Usage:
#   ./tree_sitter.sh                            # install the pinned version
#   TREE_SITTER_VERSION=0.26.1 ./tree_sitter.sh # install a specific version
#   FORCE=1 ./tree_sitter.sh                    # reinstall even if that version is present
#   DRY_RUN=1 ./tree_sitter.sh                  # show what would happen; install nothing

set -euo pipefail

# Shared helpers, kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# --- configuration ----------------------------------------------------------

readonly VERSION="${TREE_SITTER_VERSION:-0.26.11}"

readonly BIN_DIR="${BIN_DIR:-${HOME}/bin}"
readonly SYMLINK="${BIN_DIR}/tree-sitter"

# --- helpers ----------------------------------------------------------------

# Print the tree-sitter version already installed at <exe> (e.g. 0.26.11), or
# nothing if it is absent or unreadable. Used to skip the conda solve when the
# pinned version is already in place.
installed_version() {
   local exe="$1"
   [[ -x "${exe}" ]] || return 0
   "${exe}" --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true
}

# Report the version, or warn if the binary was installed but cannot run here.
verify_runs() {
   local exe="$1"
   local version_line
   if version_line="$("${exe}" --version 2>/dev/null | head -n 1)"; then
      msg "Installed: ${version_line}"
   else
      msg "WARNING: tree-sitter was installed but does not run on this machine."
   fi
}

# --- main -------------------------------------------------------------------

main() {
   msg "tree-sitter : v${VERSION} (conda-forge package)"
   msg "Method      : conda install -c conda-forge tree-sitter-cli, linked into ${BIN_DIR}"

   if [[ -n "${DRY_RUN:-}" ]]; then
      msg "DRY_RUN set; nothing was installed."
      return 0
   fi

   require conda
   [[ -n "${CONDA_PREFIX:-}" ]] || die "no active conda environment (CONDA_PREFIX is unset) - activate one first (e.g. conda activate base)"
   local conda_bin="${CONDA_PREFIX}/bin/tree-sitter"

   # conda install is a full solve (slow), so skip it when the pinned version is
   # already in the env - just refresh the symlink below. FORCE reinstalls.
   if [[ -z "${FORCE:-}" && "$(installed_version "${conda_bin}")" == "${VERSION}" ]]; then
      msg "tree-sitter-cli ${VERSION} already in ${CONDA_PREFIX}; skipping conda install (set FORCE=1 to reinstall)."
   else
      msg "Installing tree-sitter-cli=${VERSION} from conda-forge into ${CONDA_PREFIX} ..."
      conda install -y -c conda-forge "tree-sitter-cli=${VERSION}"
   fi

   [[ -x "${conda_bin}" ]] || die "expected ${conda_bin} after installing, but it is missing"

   mkdir -p "${BIN_DIR}"
   ln -sf "${conda_bin}" "${SYMLINK}"
   msg "Linked ${SYMLINK} -> ${conda_bin}"
   warn_if_not_on_path "${BIN_DIR}"

   verify_runs "${conda_bin}"
   msg "Done."
}

main "$@"
