#!/usr/bin/env bash
#
# deps.sh - preflight dependency check. Verify every prerequisite the README
# lists is present BEFORE any install step downloads or builds anything, so a
# missing dependency stops the run up front instead of failing halfway through
# (or, worse, producing a setup that only breaks when you launch nvim). This is
# read-only: it changes nothing.
#
# `make install` depends on this target, so `make install` will not start at
# all unless every required dependency below is satisfied. All missing
# dependencies are reported together (not one at a time) so you can fix them in
# a single pass.
#
# Checks are grouped; pass group names as arguments to check only those,
# otherwise every group runs:
#   core        make, tar, and a downloader (curl or wget)
#   compiler    a C compiler (cc/gcc/clang) - nvim-treesitter builds parsers with it
#   python      python3 >= 3.11, venv-capable - the Make language server needs it
#   treesitter  glibc >= 2.39 when installing the *prebuilt* tree-sitter (the
#               default method) on Linux, which otherwise installs but cannot run
#   network     best-effort reachability of github.com (ADVISORY - warns only,
#               never blocks, since proxies/firewalls make it unreliable)
#
# The Python floor is 3.11 because autotools-language-server's dependency
# lsp_tree_sitter imports typing.Self, which did not exist before Python 3.11;
# on an older python3 the Make language server crashes on startup.
#
# Usage:
#   ./deps.sh                            # check everything
#   ./deps.sh python                     # check only the Python requirement
#   TREE_SITTER_METHOD=conda ./deps.sh   # skips the prebuilt-glibc check
#   DRY_RUN=1 ./deps.sh                  # report problems but exit 0 (don't block)

set -uo pipefail

# Shared helpers (msg/die/require/download/cleanup/...), kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- configuration ----------------------------------------------------------

# Minimum Python (see header) and glibc (prebuilt tree-sitter binary) versions.
readonly MIN_PY_MAJOR=3
readonly MIN_PY_MINOR=11
readonly MIN_GLIBC="2.39"

# --- reporting --------------------------------------------------------------

# Progress lines go to stderr (like lib.sh's msg), so stdout stays clean.
ok()   { printf '  [ ok ] %s\n' "$*" >&2; }
bad()  { printf '  [MISS] %s\n' "$*" >&2; }
note() { printf '  [warn] %s\n' "$*" >&2; }
hdr()  { printf '\n%s\n' "$*" >&2; }

# Collected failures: one "problem - how to fix" line each. Kept so we can list
# every unmet dependency at the end instead of dying on the first.
fails=()
record_fail() { fails+=("$1"); }

# --- version helpers --------------------------------------------------------

# True (0) if version $1 >= version $2. Only ever called on Linux (for the
# glibc check), so GNU sort -V is available.
version_ge() {
   local lower
   lower="$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)"
   [[ "${lower}" == "$2" ]]
}

# Print the system glibc version (e.g. 2.39), or nothing if it can't be
# determined (musl, unusual libc, ...).
glibc_version() {
   local v
   v="$(getconf GNU_LIBC_VERSION 2>/dev/null | awk '{print $2}')"
   [[ -z "${v}" ]] && v="$(ldd --version 2>/dev/null | head -n1 | awk '{print $NF}')"
   [[ "${v}" =~ ^[0-9]+\.[0-9]+ ]] && printf '%s' "${BASH_REMATCH[0]}"
}

# --- checks -----------------------------------------------------------------

# Require a command on PATH, recording a failure (with a fix hint) if absent.
need_cmd() {
   local cmd="$1" hint="$2"
   if command -v "${cmd}" >/dev/null 2>&1; then
      ok "${cmd} -> $(command -v "${cmd}")"
   else
      bad "${cmd} not found"
      record_fail "${cmd} is required (${hint})"
   fi
}

check_core() {
   hdr "Core tools"
   need_cmd make "install and run this Makefile"
   need_cmd tar  "the Neovim and Node.js archives are tarballs"
   if command -v curl >/dev/null 2>&1; then
      ok "downloader: curl -> $(command -v curl)"
   elif command -v wget >/dev/null 2>&1; then
      ok "downloader: wget -> $(command -v wget)"
   else
      bad "no downloader (curl or wget)"
      record_fail "curl or wget is required to download the release archives"
   fi
}

check_compiler() {
   hdr "C compiler"
   local c
   for c in cc gcc clang; do
      if command -v "${c}" >/dev/null 2>&1; then
         ok "C compiler: ${c} -> $(command -v "${c}")"
         return
      fi
   done
   bad "no C compiler (cc/gcc/clang)"
   record_fail "a C compiler (cc, gcc, or clang) is required - nvim-treesitter builds its parsers with it"
}

check_python() {
   hdr "Python (Make language server)"
   if ! command -v python3 >/dev/null 2>&1; then
      bad "python3 not found"
      record_fail "python3 >= ${MIN_PY_MAJOR}.${MIN_PY_MINOR} is required for the Make language server (makels)"
      return
   fi

   local py ver
   py="$(command -v python3)"
   ver="$(python3 -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])' 2>/dev/null)"

   # Version >= MIN_PY_MAJOR.MIN_PY_MINOR ? (compared inside python to avoid
   # brittle string parsing.)
   if python3 - "${MIN_PY_MAJOR}" "${MIN_PY_MINOR}" <<'PY' 2>/dev/null; then
import sys
need = (int(sys.argv[1]), int(sys.argv[2]))
sys.exit(0 if sys.version_info[:2] >= need else 1)
PY
      ok "python3 ${ver:-?} -> ${py}"
   else
      bad "python3 ${ver:-unknown} is too old (need >= ${MIN_PY_MAJOR}.${MIN_PY_MINOR}) -> ${py}"
      record_fail "python3 >= ${MIN_PY_MAJOR}.${MIN_PY_MINOR} is required (found ${ver:-unknown} at ${py}); the make-language-server dependency lsp_tree_sitter imports typing.Self, added in ${MIN_PY_MAJOR}.${MIN_PY_MINOR}. With conda: conda create -n py311 python=3.11 && conda activate py311"
   fi

   # venv-capable? install_pip_server creates a virtualenv with this python3.
   if python3 -c 'import ensurepip' >/dev/null 2>&1; then
      ok "python3 venv support (ensurepip) present"
   else
      bad "python3 cannot create virtualenvs (ensurepip missing)"
      record_fail "python3 needs venv support - install python3-venv (Debian/Ubuntu) or use conda's python3"
   fi
}

check_treesitter() {
   local method="${TREE_SITTER_METHOD:-prebuilt}"
   hdr "tree-sitter (method: ${method})"

   # Only the prebuilt binary is glibc-sensitive; the conda and cargo methods
   # check their own prerequisites in tree_sitter.sh, so don't duplicate them.
   if [[ "${method}" != "prebuilt" ]]; then
      note "method '${method}' selected; the prebuilt-glibc check does not apply"
      return
   fi
   if [[ "$(uname -s)" != "Linux" ]]; then
      ok "$(uname -s): the prebuilt-glibc check applies to Linux only"
      return
   fi

   local glibc
   glibc="$(glibc_version)"
   if [[ -z "${glibc}" ]]; then
      note "could not determine glibc version; if tree-sitter fails to run, reinstall with TREE_SITTER_METHOD=conda or =cargo"
      return
   fi
   if version_ge "${glibc}" "${MIN_GLIBC}"; then
      ok "glibc ${glibc} (>= ${MIN_GLIBC})"
   else
      bad "glibc ${glibc} is older than ${MIN_GLIBC}; the prebuilt tree-sitter won't run"
      record_fail "the prebuilt tree-sitter needs glibc >= ${MIN_GLIBC} (found ${glibc}); install with TREE_SITTER_METHOD=conda (needs Miniforge) or, without conda, 'make cargo' then TREE_SITTER_METHOD=cargo"
   fi
}

# Advisory only: a failed probe never records a failure, because proxies and
# firewalls make connectivity checks unreliable and we must not block on them.
check_network() {
   hdr "Network (advisory)"
   local url="https://github.com"
   local reachable=1
   if command -v curl >/dev/null 2>&1; then
      curl --silent --head --max-time 5 --output /dev/null "${url}" 2>/dev/null && reachable=0
   elif command -v wget >/dev/null 2>&1; then
      wget --quiet --spider --timeout=5 "${url}" 2>/dev/null && reachable=0
   fi
   if [[ "${reachable}" -eq 0 ]]; then
      ok "github.com reachable"
   else
      note "could not reach github.com within 5s - the installers need network access (GitHub, npm, PyPI). Advisory only; not blocking."
   fi
}

# --- main -------------------------------------------------------------------

main() {
   local groups=("$@")
   if [[ ${#groups[@]} -eq 0 ]]; then
      groups=(core compiler python treesitter network)
   fi

   msg "Checking dependencies (bundle: ${HERE}) ..."

   local g
   for g in "${groups[@]}"; do
      case "${g}" in
         core)       check_core ;;
         compiler)   check_compiler ;;
         python)     check_python ;;
         treesitter) check_treesitter ;;
         network)    check_network ;;
         *)          die "unknown dependency group '${g}' (use: core compiler python treesitter network)" ;;
      esac
   done

   printf '\n' >&2
   if [[ ${#fails[@]} -eq 0 ]]; then
      msg "All required dependencies satisfied."
      exit 0
   fi

   if [[ ${#fails[@]} -eq 1 ]]; then
      msg "1 required dependency is missing:"
   else
      msg "${#fails[@]} required dependencies are missing:"
   fi
   local f
   for f in "${fails[@]}"; do
      msg "  - ${f}"
   done

   if [[ -n "${DRY_RUN:-}" ]]; then
      msg ""
      msg "DRY_RUN set: not blocking, but the above must be fixed before a real install."
      exit 0
   fi

   msg ""
   die "dependency check failed; not starting. Fix the above and re-run."
}

main "$@"
