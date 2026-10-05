#!/usr/bin/env bash
#
# r_setup.sh - install R with rig and get it ready for R.nvim.
#
# https://github.com/r-lib/rig manages the R installations; this script works on
# one of them (rig's default R, or R_VERSION) and:
#   1. installs the current R release (`rig add release`) if rig has no R at
#      all. Only then: once any R is installed this step is skipped, so rerunning
#      never adds a second R when a newer release comes out - upgrading R stays
#      a deliberate `rig add release` of your own
#   2. checks the R is >= 4.1 (R.nvim's floor)
#   3. checks the build tools R.nvim needs: the first time you open an R file
#      it compiles its own R package, nvimcom, with R's make and C compiler
#   4. checks that the `R` on PATH is this R - R.nvim starts whatever `R` it
#      finds there
#   5. checks R's user library exists and is writable, so the packages below -
#      and nvimcom later - have somewhere to go (R.nvim otherwise stops and asks
#      where to put nvimcom). rig sets R up to create it on every start; this
#      creates it for an R that was not set up that way
#   6. installs the R packages R.nvim uses, skipping any already installed:
#        knitr, rmarkdown, quarto  render Rmd, Quarto and Rnoweb documents
#        styler                    :RFormat
#        httpgd (optional)         plots in a browser, for R on a remote box
#   7. reports what else document rendering needs (pandoc, the Quarto CLI) and
#      a ~/.Rprofile that would stop R from loading nvimcom
#
# Packages install from the repositories rig configured for that R (CRAN plus
# Posit Package Manager binaries), so most arrive prebuilt. nvimcom is not
# installed here: R.nvim ships it and rebuilds it whenever it is out of date.
# `rig add` needs no root in user mode (how terminal_setup's `make rig` sets rig
# up); in rig's default admin mode it asks for sudo itself.
#
# Usage:
#   ./r_setup.sh
#   R_VERSION=4.4 ./r_setup.sh   # set up another installed R (a name, version
#                                # or alias from `rig list`)
#   FORCE=1 ./r_setup.sh         # reinstall (update) the packages even if present
#   DRY_RUN=1 ./r_setup.sh       # report what would be installed; install nothing
#                                # (with no R yet, it stops after saying so)
#
# Exits non-zero if R.nvim would not work (no compiler, no `R` on PATH, a
# required package that failed to install); the advisory notes never fail it.

set -euo pipefail

# Shared helpers (msg/die/require/cleanup/...), kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- configuration ----------------------------------------------------------

# Required packages fail the run if they do not install; optional ones only warn.
readonly REQUIRED_PKGS=(knitr rmarkdown quarto styler)
readonly OPTIONAL_PKGS=(httpgd)

# --- reporting --------------------------------------------------------------

# Progress lines go to stderr (like lib.sh's msg), matching deps.sh.
ok()   { printf '  [ ok ] %s\n' "$*" >&2; }
bad()  { printf '  [MISS] %s\n' "$*" >&2; }
note() { printf '  [warn] %s\n' "$*" >&2; }
hdr()  { printf '\n%s\n' "$*" >&2; }

# Problems that leave R.nvim unable to work, listed again at the end.
fails=()
record_fail() { fails+=("$1"); }

# --- rig and R --------------------------------------------------------------

# Print the name, version and R binary of the R to set up, one per line: the R
# that R_VERSION names (matching a name, version or alias) or rig's default.
# Reads `rig list --json` (rig >= 0.5.0) on stdin. Exits 1 if nothing matches.
select_r() {
   python3 -c '
import json, sys
want = sys.argv[1]
for r in json.load(sys.stdin):
    names = [r.get("name"), r.get("version")] + (r.get("aliases") or [])
    if (want in names) if want else r.get("default"):
        print(r["name"], r.get("version") or r["name"], r["binary"], sep="\n")
        sys.exit(0)
sys.exit(1)
' "${R_VERSION:-}"
}

# Join the remaining arguments with commas, to pass a package list to R.
join_commas() { local IFS=,; printf '%s' "$*"; }

# Print the R code that creates the user library and installs the packages.
# It runs under that R's Rscript, which loads rig's site profile and so the
# repositories rig set up.
#   args: <force 0|1> <dry-run 0|1> <required,pkgs> <optional,pkgs>
r_code() {
   cat <<'RCODE'
args <- commandArgs(trailingOnly = TRUE)
force <- args[1] == "1"
dry_run <- args[2] == "1"
required <- strsplit(args[3], ",")[[1]]
optional <- strsplit(args[4], ",")[[1]]
say <- function(...) message("  ", ...)

# R adds R_LIBS_USER to .libPaths() only if the directory exists when R starts.
# Read it the way R.nvim does; "NULL" is R's way of switching it off.
lib <- path.expand(strsplit(Sys.getenv("R_LIBS_USER"), .Platform$path.sep)[[1]][1])
if (is.na(lib) || !nzchar(lib) || lib == "NULL") {
  say("[MISS] R_LIBS_USER is unset, so there is no user library to install into")
  quit(save = "no", status = 3)
}
if (dir.exists(lib)) {
  say("[ ok ] user library: ", lib)
} else if (dry_run) {
  say("[ -- ] would create the user library: ", lib)
} else {
  dir.create(lib, recursive = TRUE)
  say("[ ok ] created the user library: ", lib)
}
if (dir.exists(lib) && file.access(lib, mode = 2) != 0) {
  say("[MISS] the user library is not writable: ", lib)
  quit(save = "no", status = 3)
}
.libPaths(c(lib, .libPaths()))

# A bare R has no CRAN mirror set, and non-interactively install.packages()
# cannot ask for one. rig sets one; fall back to the cloud mirror if not.
repos <- getOption("repos")
if (is.null(repos) || is.na(repos["CRAN"]) || repos["CRAN"] == "@CRAN@") {
  repos["CRAN"] <- "https://cloud.r-project.org"
  options(repos = repos)
}

have <- function(p) suppressWarnings(requireNamespace(p, quietly = TRUE))
wanted <- c(required, optional)
todo <- if (force) wanted else wanted[!vapply(wanted, have, logical(1))]
done <- setdiff(wanted, todo)
if (length(done) > 0) say("[ ok ] already installed: ", paste(done, collapse = ", "))
if (length(todo) == 0) quit(save = "no", status = 0)
if (dry_run) {
  say("[ -- ] would install: ", paste(todo, collapse = ", "))
  quit(save = "no", status = 0)
}

say("Installing ", paste(todo, collapse = ", "), " into ", lib, " ...")
# install.packages() only warns when a package fails, so check afterwards.
install.packages(todo, lib = lib)

failed <- todo[!vapply(todo, have, logical(1))]
for (p in setdiff(todo, failed)) say("[ ok ] ", p, " ", format(packageVersion(p, lib.loc = lib)))
for (p in intersect(failed, optional)) say("[warn] optional package ", p, " did not install (output above)")
missing <- intersect(failed, required)
if (length(missing) > 0) {
  say("[MISS] failed to install: ", paste(missing, collapse = ", "), " (output above)")
  quit(save = "no", status = 1)
}
RCODE
}

# --- main -------------------------------------------------------------------

main() {
   msg "Setting up R for R.nvim (bundle: ${HERE}) ..."

   hdr "rig"
   command -v rig >/dev/null 2>&1 \
      || die "rig not found on PATH - install it: https://github.com/r-lib/rig#installation"
   ok "rig -> $(command -v rig)"
   require python3   # to read rig's JSON

   local json
   json="$(rig list --json 2>/dev/null)" \
      || die "'rig list --json' failed - this script needs rig 0.5.0 or newer"
   # Add R only when rig has none at all. `rig add release` alone is not a safe
   # rerun: once a newer R is out it installs that alongside the one you have.
   if [[ "$(python3 -c 'import json, sys; print(len(json.load(sys.stdin)))' <<<"${json}")" == 0 ]]; then
      if [[ -n "${R_VERSION:-}" ]]; then
         die "rig has no R installed, so R_VERSION=${R_VERSION} matches nothing - add it with: rig add ${R_VERSION}"
      fi
      if [[ -n "${DRY_RUN:-}" ]]; then
         msg "rig has no R installed; a real run would install it with 'rig add release' first."
         msg "DRY_RUN set; nothing was installed."
         exit 0
      fi
      msg "rig has no R installed - running 'rig add release' (a download of a few hundred MB) ..."
      rig add release || die "'rig add release' failed (output above)"
      json="$(rig list --json 2>/dev/null)" || die "'rig list --json' failed after 'rig add release'"
      ok "installed R with 'rig add release'"
   else
      ok "rig already has R installed; not adding another (upgrade with: rig add release)"
   fi

   local sel name version rbin rscript
   if ! sel="$(select_r <<<"${json}")"; then
      if [[ -n "${R_VERSION:-}" ]]; then
         die "R_VERSION=${R_VERSION} does not match an R that rig has installed (see: rig list)"
      fi
      die "rig has no default R - set one with 'rig default <version>', or pick one with R_VERSION=<version> (see: rig list)"
   fi
   { read -r name; read -r version; read -r rbin; } <<<"${sel}"
   rscript="$(dirname "${rbin}")/Rscript"
   [[ -x "${rscript}" ]] || die "expected Rscript beside ${rbin}, but it is missing"

   hdr "R"
   # sort -V puts a non-numeric version (e.g. a devel build's name) last, so
   # only a numbered release older than R.nvim's floor fails here.
   if [[ "$(printf '%s\n' 4.1.0 "${version}" | sort -V | head -n1)" != 4.1.0 ]]; then
      die "R ${version} is too old: R.nvim needs R 4.1.0 or newer (rig add release)"
   fi
   ok "R ${version} -> ${rbin}"

   # nvimcom is compiled with the make and C compiler R itself was configured
   # with, so ask R for its compiler rather than looking for any `cc` (R CMD
   # config itself runs make, so it needs make to answer).
   hdr "Build tools (R.nvim compiles nvimcom with them)"
   local cc
   if command -v make >/dev/null 2>&1; then
      ok "make -> $(command -v make)"
      cc="$("${rbin}" CMD config CC 2>/dev/null || true)"
      cc="${cc%% *}"
      if [[ -n "${cc}" ]] && command -v "${cc}" >/dev/null 2>&1; then
         ok "R's C compiler: ${cc} -> $(command -v "${cc}")"
      else
         bad "R's C compiler (${cc:-unknown}) not found"
         record_fail "R's C compiler '${cc:-unknown}' is not on PATH - R.nvim cannot build nvimcom without it"
      fi
   else
      bad "make not found"
      record_fail "make is not on PATH - R.nvim builds nvimcom with make and a C compiler"
   fi

   hdr "R on PATH (R.nvim starts the R it finds there)"
   local path_r
   if ! path_r="$(command -v R 2>/dev/null)"; then
      bad "R not found on PATH"
      record_fail "no R on PATH - put the directory rig links R into on PATH ('rig system dirs' shows it as the binary dir) so R.nvim can start R"
   elif [[ "$(readlink -f "${path_r}")" == "$(readlink -f "${rbin}")" ]]; then
      ok "R -> ${path_r}"
   else
      note "R on PATH is ${path_r}, not R ${version} - R.nvim will start that R instead. Make R ${version} the default (rig default ${name}) or put it first on PATH"
   fi

   hdr "R packages"
   # `tmp` is the global lib.sh's EXIT trap cleans up.
   tmp="$(mktemp -d)"
   r_code > "${tmp}/r_setup.R"
   if ! "${rscript}" "${tmp}/r_setup.R" \
         "$([[ -n "${FORCE:-}" ]] && echo 1 || echo 0)" \
         "$([[ -n "${DRY_RUN:-}" ]] && echo 1 || echo 0)" \
         "$(join_commas "${REQUIRED_PKGS[@]}")" \
         "$(join_commas "${OPTIONAL_PKGS[@]}")"; then
      record_fail "the R packages step failed (see above)"
   fi

   # Advisory: these only matter for rendering documents (<LocalLeader>kr).
   hdr "Rendering documents (advisory)"
   local rc=0
   "${rscript}" -e 'if (!requireNamespace("rmarkdown", quietly = TRUE)) quit(save = "no", status = 2)
                    quit(save = "no", status = if (rmarkdown::pandoc_available()) 0 else 1)' \
      >/dev/null 2>&1 || rc=$?
   case "${rc}" in
      0) ok "pandoc found by rmarkdown" ;;
      2) note "rmarkdown is not installed, so pandoc was not checked" ;;
      *) note "rmarkdown cannot find pandoc, so Rmd files will not render - terminal_setup's 'make pandoc' installs it into ~/bin" ;;
   esac
   if command -v quarto >/dev/null 2>&1; then
      ok "quarto -> $(command -v quarto)"
   else
      note "Quarto CLI not found - needed to render .qmd files and for R.nvim's completion of '#|' chunk options: https://quarto.org/docs/download/"
   fi

   # R.nvim loads nvimcom by adding it to R_DEFAULT_PACKAGES, which a
   # defaultPackages option in ~/.Rprofile overrides (see :help nvimcom-not-loaded).
   if [[ -f "${HOME}/.Rprofile" ]] && grep -q 'defaultPackages' "${HOME}/.Rprofile" \
         && ! grep -q 'nvimcom' "${HOME}/.Rprofile"; then
      note "${HOME}/.Rprofile sets defaultPackages without nvimcom, so R.nvim cannot load it - add \"nvimcom\" to that list (:help nvimcom-not-loaded)"
   fi

   printf '\n' >&2
   if [[ ${#fails[@]} -gt 0 ]]; then
      msg "R is not ready for R.nvim yet:"
      local f
      for f in "${fails[@]}"; do
         msg "  - ${f}"
      done
      exit 1
   fi
   if [[ -n "${DRY_RUN:-}" ]]; then
      msg "DRY_RUN set; nothing was installed."
   else
      msg "Done. Open an R file in nvim (the first one builds nvimcom) and press \\rf to start R; :checkhealth r checks the rest."
   fi
}

main "$@"
