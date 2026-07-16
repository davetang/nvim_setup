#!/usr/bin/env bash
#
# lib.sh - shared helpers for the setup scripts. Sourced (not executed) by
# nvim.sh, node.sh and the language-server installers so the common
# boilerplate lives in one place instead of drifting between scripts. This
# file lives in and moves with the setup directory, so sourcing it keeps the
# whole setup self-contained.
#
# Sourcing this file also installs EXIT/INT/TERM traps that remove ${tmp} - a
# scratch directory a caller may create with `tmp="$(mktemp -d)"`.

# --- logging ----------------------------------------------------------------

# Log to stderr so stdout stays clean for anything that wants to capture it.
msg() { printf '%s\n' "$*" >&2; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

# --- prerequisites ----------------------------------------------------------

# Abort unless a required command is available.
require() {
   command -v "$1" >/dev/null 2>&1 || die "'$1' is required but was not found in PATH"
}

# Download a URL to a local file using whichever fetcher is installed.
download() {
   local url="$1" out="$2"
   if command -v curl >/dev/null 2>&1; then
      curl --fail --location --silent --show-error --output "${out}" "${url}"
   elif command -v wget >/dev/null 2>&1; then
      wget --quiet --output-document="${out}" "${url}"
   else
      die "Neither curl nor wget is available to download files"
   fi
}

# --- scratch dir cleanup ----------------------------------------------------

# Scratch directory a caller may set with `tmp="$(mktemp -d)"`. Removed on any
# exit by the traps below. Empty by default so cleanup is a no-op if unused.
tmp=""

# Remove the scratch directory on exit. Always succeeds so it never turns an
# otherwise clean run into a failure.
cleanup() {
   if [[ -n "${tmp}" ]]; then
      rm -rf "${tmp}"
   fi
}

# Clean up however the script exits - success, error, or interruption. The
# signal traps exit explicitly so the EXIT trap still fires.
trap cleanup EXIT
trap 'exit 130' INT TERM

# --- PATH helper ------------------------------------------------------------

# Warn if <dir> is not on PATH, telling the user how to add it.
warn_if_not_on_path() {
   local dir="$1"
   case ":${PATH}:" in
      *":${dir}:"*) : ;;
      *) msg "Note: ${dir} is not on your PATH. Add this to your shell rc:"
         msg "      export PATH=\"${dir}:\$PATH\"" ;;
   esac
}

# --- npm-based language servers ---------------------------------------------

# Install an npm package (a language server) into ${LIB_DIR:-~/lib} with no
# root, then verify. Node lives under ${BIN_DIR:-~/bin}, which we put on PATH
# here so npm - and npm's `env node` shebang - are found even when the user has
# not yet added ~/bin to their PATH.
#
#   install_npm_server <package> <lsp-binary> [<version-binary>]
#     package         npm package to install
#     lsp-binary      executable Neovim invokes; must exist afterwards
#     version-binary  executable to run `--version` on for the report
#                     (default: lsp-binary)
install_npm_server() {
   local package="$1" lsp_binary="$2" version_binary="${3:-$2}"
   local bin_dir="${BIN_DIR:-${HOME}/bin}"
   local lib_dir="${LIB_DIR:-${HOME}/lib}"

   export PATH="${bin_dir}:${PATH}"
   require npm

   msg "Installing ${package} into ${lib_dir} ..."
   mkdir -p "${lib_dir}"
   npm install --global --prefix="${lib_dir}" --no-fund --no-audit "${package}"

   local exe="${lib_dir}/bin/${lsp_binary}"
   [[ -x "${exe}" ]] || die "expected ${exe} after installing ${package}, but it is missing"

   local ver
   if ver="$("${lib_dir}/bin/${version_binary}" --version 2>/dev/null)"; then
      ver="${ver%%$'\n'*}"
   else
      ver="?"
   fi
   msg "Installed: ${lsp_binary} (${ver}) -> ${exe}"
   msg "Done."
}

# Install a pip package (a language server) into a dedicated virtualenv under
# ${LIB_DIR:-~/lib} with no root, then symlink its executables into
# ${BIN_DIR:-~/bin}. Console scripts get an absolute-path shebang into the
# venv, so they run without needing anything on PATH. Requires a venv-capable
# python3 (conda's works; a bare Debian/Ubuntu python3 needs python3-venv).
#
#   install_pip_server <package> <venv-name> <binary>...
#     package     pip package to install
#     venv-name   directory name for the venv under ${LIB_DIR}
#     binary...   executable(s) the package provides to expose in ${BIN_DIR}
install_pip_server() {
   local package="$1" venv_name="$2"
   shift 2
   local bin_dir="${BIN_DIR:-${HOME}/bin}"
   local lib_dir="${LIB_DIR:-${HOME}/lib}"
   local venv="${lib_dir}/${venv_name}"

   require python3
   python3 -c 'import ensurepip' 2>/dev/null \
      || die "this python3 has no venv support (ensurepip missing) - use conda's python or install python3-venv"

   mkdir -p "${bin_dir}"

   if [[ -d "${venv}" && -z "${FORCE:-}" ]]; then
      msg "${venv} already exists; skipping install (set FORCE=1 to reinstall)."
   else
      msg "Creating virtualenv at ${venv} ..."
      rm -rf "${venv}"
      python3 -m venv "${venv}"
      msg "Installing ${package} ..."
      "${venv}/bin/pip" install --quiet "${package}"
   fi

   local binary exe
   for binary in "$@"; do
      exe="${venv}/bin/${binary}"
      [[ -x "${exe}" ]] || die "expected ${exe} after installing ${package}, but it is missing"
      ln -sf "${exe}" "${bin_dir}/${binary}"
      msg "Linked ${bin_dir}/${binary} -> ${exe}"
   done
   warn_if_not_on_path "${bin_dir}"
   msg "Done."
}

# --- config symlinks --------------------------------------------------------

# Create a symlink dst -> src, creating parent directories as needed. If dst is
# an existing real file/dir (not a symlink), it is backed up to
# dst.bak-<timestamp> first so a file the user created is never clobbered.
safe_symlink() {
   local src="$1" dst="$2"
   [[ -e "${src}" ]] || die "source ${src} does not exist"
   mkdir -p "$(dirname "${dst}")"
   if [[ -e "${dst}" && ! -L "${dst}" ]]; then
      local backup="${dst}.bak-$(date +%Y%m%d%H%M%S)"
      mv "${dst}" "${backup}"
      msg "Backed up existing ${dst} -> ${backup}"
   fi
   ln -sf "${src}" "${dst}"
   msg "Linked ${dst} -> ${src}"
}
