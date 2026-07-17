#!/usr/bin/env bash
#
# screen.sh - build GNU Screen 5.x locally under $HOME (no root required).
#
# Neovim's true 24-bit colours (termguicolors) only survive a terminal
# multiplexer that understands them. GNU Screen gained true-colour support in
# the 5.0 series (the `truecolor on` command); 4.x - still shipped by many
# distros and long-term releases - silently down-samples 24-bit sequences to
# 256 colours. This builds a recent Screen from source into
# $HOME/bin/screen-<version> and points a stable $HOME/bin/screen symlink at it,
# so you can turn on `truecolor on` in ~/.screenrc and use termguicolors in
# Neovim.
#
# Unlike the other installers this compiles from source, so besides a
# downloader it needs a C compiler, make, and a curses/termcap library
# (ncurses) *with headers* - the same sort of toolchain nvim-treesitter already
# needs to build parsers. On a no-root box the system ncurses usually lacks its
# -dev headers; install one into an active conda env with
# `conda install -c conda-forge ncurses` (auto-detected via CONDA_PREFIX), or
# point NCURSES_PREFIX at any local ncurses. It is deliberately NOT part of
# `make install`: it is only useful if you run Screen and want 24-bit colour,
# and not every machine has a compiler.
#
# Usage:
#   ./screen.sh                             # build the pinned version
#   SCREEN_VERSION=5.0.1 ./screen.sh        # build a specific version
#   NCURSES_PREFIX=~/.local ./screen.sh     # build against a local ncurses
#   FORCE=1 ./screen.sh                     # rebuild even if already present
#   DRY_RUN=1 ./screen.sh                   # show what would happen; build nothing

set -euo pipefail

# Shared helpers (msg/die/require/download/cleanup/...), kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# --- configuration ----------------------------------------------------------

# Version to build. Override with the SCREEN_VERSION environment variable.
readonly VERSION="${SCREEN_VERSION:-5.0.2}"

# Where versioned installs live and where the stable symlink is created.
readonly BIN_DIR="${BIN_DIR:-${HOME}/bin}"
readonly INSTALL_DIR="${BIN_DIR}/screen-${VERSION}"
readonly SYMLINK="${BIN_DIR}/screen"

readonly SOURCE_URL="https://ftp.gnu.org/gnu/screen/screen-${VERSION}.tar.gz"

# --- helpers ----------------------------------------------------------------

# Screen builds from source, so make sure a C compiler is available (the other
# installers only download prebuilt binaries and don't need one).
require_cc() {
   if command -v cc >/dev/null 2>&1 || command -v gcc >/dev/null 2>&1 \
      || command -v clang >/dev/null 2>&1; then
      return 0
   fi
   die "no C compiler found (need cc, gcc, or clang) - Screen is built from source"
}

# Locate an ncurses/termcap install that ships dev headers, for building against
# on machines whose system curses has no -dev package (common without root).
# Prefers an explicit NCURSES_PREFIX, else an active conda env. Prints the
# prefix if it actually has headers; prints nothing otherwise.
ncurses_prefix() {
   local p="${NCURSES_PREFIX:-${CONDA_PREFIX:-}}"
   [[ -n "${p}" ]] || return 0
   if [[ -e "${p}/include/ncurses.h" || -e "${p}/include/curses.h" ]]; then
      printf '%s' "${p}"
   fi
}

# Point ${BIN_DIR}/screen at the freshly built version. `make install` creates
# a bin/screen symlink beside the versioned bin/screen-<version> binary, so this
# links to that stable name inside the versioned directory.
link_current() {
   ln -sf "${INSTALL_DIR}/bin/screen" "${SYMLINK}"
   msg "Linked ${SYMLINK} -> ${INSTALL_DIR}/bin/screen"
   warn_if_not_on_path "${BIN_DIR}"
}

# The two manual steps that actually switch on 24-bit colour - the build alone
# does not, since Screen cannot autodetect truecolor support.
print_next_steps() {
   msg ""
   msg "Almost there - to actually get 24-bit colour:"
   msg "  1. Add 'truecolor on' to ~/.screenrc"
   msg "  2. Start a NEW screen session (reattaching won't re-read ~/.screenrc)"
   msg "  3. In Neovim set termguicolors = true (see the README colour note)"
}

# --- main -------------------------------------------------------------------

main() {
   require tar
   require make
   require_cc

   msg "GNU Screen : v${VERSION} (built from source)"
   msg "Source     : ${SOURCE_URL}"
   msg "Target     : ${INSTALL_DIR}"

   if [[ -n "${DRY_RUN:-}" ]]; then
      msg "DRY_RUN set; nothing was downloaded or built."
      return 0
   fi

   # Already built? Just refresh the symlink, unless FORCE is set.
   if [[ -d "${INSTALL_DIR}" && -z "${FORCE:-}" ]]; then
      msg "${INSTALL_DIR} already exists; skipping build (set FORCE=1 to rebuild)."
      link_current
      print_next_steps
      return 0
   fi

   mkdir -p "${BIN_DIR}"
   tmp="$(mktemp -d)"

   local tarball="${tmp}/screen-${VERSION}.tar.gz"
   msg "Downloading screen-${VERSION}.tar.gz ..."
   download "${SOURCE_URL}" "${tarball}"

   msg "Extracting ..."
   tar -xzf "${tarball}" -C "${tmp}"
   local src_dir="${tmp}/screen-${VERSION}"
   [[ -d "${src_dir}" ]] || die "expected source directory ${src_dir} after extracting"

   rm -rf "${INSTALL_DIR}"

   # Build in the source tree. Output goes to log files (a source build is
   # noisy); on failure we print the tail so the reason is visible before the
   # scratch dir is cleaned up on exit.
   cd "${src_dir}"

   # Screen needs a curses/termcap library *with headers*. On a no-root box the
   # system one usually lacks them, so if a conda env (or an explicit
   # NCURSES_PREFIX) provides ncurses, build against that - and bake in an rpath
   # so the resulting binary finds the library at runtime without that env being
   # active.
   local cpp="${CPPFLAGS:-}" ld="${LDFLAGS:-}" ncp
   ncp="$(ncurses_prefix)"
   if [[ -n "${ncp}" ]]; then
      msg "Using ncurses from ${ncp}"
      cpp="-I${ncp}/include ${cpp}"
      ld="-L${ncp}/lib -Wl,-rpath,${ncp}/lib ${ld}"
   fi

   # --disable-pam: PAM is enabled by default and its check fatally requires
   # <security/pam_appl.h>, which no-root boxes rarely have. Screen only uses
   # PAM to lock the screen with your login password - not needed here.
   msg "Configuring (prefix ${INSTALL_DIR}) ..."
   CPPFLAGS="${cpp}" LDFLAGS="${ld}" \
      ./configure --prefix="${INSTALL_DIR}" --disable-pam >configure.log 2>&1 \
      || { tail -n 20 configure.log >&2
           die "configure failed - see the output above for the reason. A common no-root cause is a missing curses/termcap header ('conda install -c conda-forge ncurses' into your active env, or set NCURSES_PREFIX)."; }

   local jobs
   jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
   msg "Compiling (make -j${jobs}) ..."
   make -j"${jobs}" >make.log 2>&1 \
      || { tail -n 20 make.log >&2; die "make failed (see output above)"; }

   # `make install` also attempts to setuid-root the binary and refresh
   # /usr/lib/terminfo; both are guarded with a leading '-' in Screen's
   # Makefile, so they are skipped harmlessly without root. Everything that
   # matters (the binary, its bin/screen symlink, man pages, encodings) lands
   # under INSTALL_DIR. A non-setuid screen is fine - it just won't update the
   # system utmp record.
   msg "Installing into ${INSTALL_DIR} ..."
   make install >install.log 2>&1 \
      || { tail -n 20 install.log >&2; die "make install failed (see output above)"; }

   [[ -x "${INSTALL_DIR}/bin/screen" ]] \
      || die "expected ${INSTALL_DIR}/bin/screen after install, but it is missing"

   link_current

   local version_line
   if version_line="$("${INSTALL_DIR}/bin/screen" --version 2>/dev/null | head -n 1)"; then
      msg "Installed: ${version_line}"
   else
      msg "Installed to ${INSTALL_DIR}"
   fi

   print_next_steps
   msg "Done."
}

main "$@"
