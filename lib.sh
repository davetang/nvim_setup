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

# --- C compiler -------------------------------------------------------------

# Print the path to a C compiler (cc, gcc, or clang) if one is on PATH and
# return 0; print nothing and return 1 otherwise. nvim-treesitter builds its
# parsers with it, and the from-source installers (screen) need it too.
have_cc() {
   local c p
   for c in cc gcc clang; do
      if p="$(command -v "${c}" 2>/dev/null)"; then
         printf '%s\n' "${p}"
         return 0
      fi
   done
   return 1
}

# Abort unless a C compiler is available. An optional reason is appended to the
# error to explain why the caller needs one.
require_cc() {
   have_cc >/dev/null && return 0
   die "no C compiler found (need cc, gcc, or clang)${1:+ - $1}"
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

# --- prebuilt-tool installer ------------------------------------------------

# Print an "Installed:" line from <exe> --version (first line); best-effort, so
# it never fails a run. Falls back to the path if --version prints nothing.
report_installed() {
   local exe="$1" line
   line="$("${exe}" --version 2>/dev/null | head -n1 || true)"
   msg "Installed: ${line:-${exe}}"
}

# Stage callback: extract a .tar.gz whose single top-level directory should be
# stripped, so its contents land directly in the install dir. Shared by the
# installers whose release is a tarball wrapping one directory.
stage_tarball_strip() {
   require tar
   tar -xzf "$1" -C "$2" --strip-components=1
}

# Download a pinned release into a versioned dir under ~/bin and symlink the
# executables it provides into ~/bin - the shared skeleton behind nvim.sh,
# node.sh, shellcheck.sh, shfmt.sh and ruff.sh, which differ only in the asset
# name, how the download is unpacked, and what they report.
#
#   install_versioned_tool <label> <version> <url> <install_dir> \
#                          <stage_fn> <verify_fn> <linkspec>...
#     label        human name for the log banner (e.g. "Neovim")
#     version      version being installed
#     url          download URL; the asset name is its basename
#     install_dir  versioned dir to populate (e.g. ~/bin/nvim-0.12.4)
#     stage_fn     callback: stage_fn <downloaded-file> <install_dir> - unpacks
#                  the download into install_dir (e.g. stage_tarball_strip)
#     verify_fn    callback: verify_fn <install_dir> prints an "Installed:" line;
#                  pass "" to report the first linked binary's --version
#     linkspec...  "<name>=<relpath>": symlink ~/bin/<name> -> install_dir/relpath
#
# Honours FORCE (reinstall when the versioned dir already exists) and DRY_RUN
# (print the plan, download nothing).
install_versioned_tool() {
   local label="$1" version="$2" url="$3" install_dir="$4" stage_fn="$5" verify_fn="$6"
   shift 6
   local -a linkspecs=("$@")
   local bin_dir="${BIN_DIR:-${HOME}/bin}"
   local asset="${url##*/}"

   msg "${label} : v${version}"
   msg "Platform : $(uname -s) $(uname -m) -> ${asset}"
   msg "Source   : ${url}"
   msg "Target   : ${install_dir}"

   if [[ -n "${DRY_RUN:-}" ]]; then
      msg "DRY_RUN set; nothing was downloaded or installed."
      return 0
   fi

   mkdir -p "${bin_dir}"

   if [[ -d "${install_dir}" && -z "${FORCE:-}" ]]; then
      msg "${install_dir} already exists; skipping download (set FORCE=1 to reinstall)."
   else
      # `tmp` is the global the EXIT trap cleans up (see the scratch-dir section).
      tmp="$(mktemp -d)"
      msg "Downloading ${asset} ..."
      download "${url}" "${tmp}/${asset}"
      rm -rf "${install_dir}"
      mkdir -p "${install_dir}"
      "${stage_fn}" "${tmp}/${asset}" "${install_dir}"
   fi

   local spec name rel
   for spec in "${linkspecs[@]}"; do
      name="${spec%%=*}"
      rel="${spec#*=}"
      ln -sf "${install_dir}/${rel}" "${bin_dir}/${name}"
      msg "Linked ${bin_dir}/${name} -> ${install_dir}/${rel}"
   done
   warn_if_not_on_path "${bin_dir}"

   if [[ -n "${verify_fn}" ]]; then
      "${verify_fn}" "${install_dir}"
   else
      report_installed "${install_dir}/${linkspecs[0]#*=}"
   fi
   msg "Done."
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
