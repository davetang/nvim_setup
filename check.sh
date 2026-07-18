#!/usr/bin/env bash
#
# check.sh - report the state of the setup WITHOUT changing anything.
#
# Handy when migrating from an older manual install: it shows what your PATH
# actually resolves to for each tool (so you can spot an old install winning),
# where the ~/.config/nvim symlinks point, whether the language servers are in
# place, and whether any legacy files are lying around. Purely read-only.

set -uo pipefail

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BIN_DIR="${BIN_DIR:-${HOME}/bin}"
readonly LIB_DIR="${LIB_DIR:-${HOME}/lib}"
readonly NVIM_CONFIG="${HOME}/.config/nvim"

ok()   { printf '  [ ok ] %s\n' "$*"; }
warn() { printf '  [warn] %s\n' "$*"; }
info() { printf '  [ -- ] %s\n' "$*"; }
hdr()  { printf '\n%s\n' "$*"; }

echo "Neovim setup check (bundle: ${HERE})"

# --- PATH -------------------------------------------------------------------
hdr "PATH"
case ":${PATH}:" in
   *":${BIN_DIR}:"*) ok "${BIN_DIR} is on PATH" ;;
   *) warn "${BIN_DIR} is not on PATH  ->  export PATH=\"${BIN_DIR}:\$PATH\"" ;;
esac

# --- tools: does PATH resolve to this bundle's ~/bin? -----------------------
hdr "Tools (what PATH resolves to)"
for tool in nvim node npm npx tree-sitter shellcheck shfmt ruff fzf; do
   resolved="$(command -v "${tool}" 2>/dev/null || true)"
   ours="${BIN_DIR}/${tool}"
   if [[ -z "${resolved}" ]]; then
      info "${tool}: not found"
   elif [[ "${resolved}" == "${ours}" ]]; then
      ok "${tool} -> ${resolved}"
   else
      warn "${tool} -> ${resolved}  (not ${ours}; another install is ahead on PATH)"
   fi
done

# --- toolchain: conda + Python underpin tree-sitter and the Make LSP --------
hdr "Toolchain (conda + Python)"
if command -v conda >/dev/null 2>&1; then
   ok "conda -> $(command -v conda)"
   if [[ -n "${CONDA_PREFIX:-}" ]]; then
      ok "active conda env: ${CONDA_PREFIX}"
   else
      warn "no active conda env (CONDA_PREFIX unset)  ->  conda activate base  (needed to install tree-sitter)"
   fi
else
   warn "conda not found  (Miniforge is required; tree-sitter is installed from conda-forge)"
fi
if command -v python3 >/dev/null 2>&1; then
   pyver="$(python3 -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])' 2>/dev/null || true)"
   if python3 -c 'import sys; sys.exit(0 if sys.version_info[:2] >= (3, 11) else 1)' 2>/dev/null; then
      ok "python3 ${pyver:-?} -> $(command -v python3)"
   else
      warn "python3 ${pyver:-unknown} is < 3.11 (the Make LSP needs 3.11+)  ->  $(command -v python3)"
   fi
else
   info "python3 not found  (needed for the Make language server)"
fi

# --- config symlinks: do they point into this bundle? ----------------------
hdr "Config (~/.config/nvim symlinks should point into this bundle)"
check_link() {
   local file="$1" dst="$2"
   local src="${HERE}/${file}"
   if [[ -L "${dst}" ]]; then
      local target; target="$(readlink "${dst}")"
      if [[ "${target}" == "${src}" ]]; then
         ok "${file} -> this bundle"
      else
         warn "${file} -> ${target}  (not this bundle; run: make setup)"
      fi
   elif [[ -e "${dst}" ]]; then
      warn "${file} is a real file, not a symlink: ${dst}  (make setup backs it up)"
   else
      info "${file} not linked  (run: make setup)"
   fi
}
check_link init.lua      "${NVIM_CONFIG}/init.lua"
check_link lazy.lua      "${NVIM_CONFIG}/lua/config/lazy.lua"
check_link spec1.lua     "${NVIM_CONFIG}/lua/plugins/spec1.lua"
check_link practice.md   "${NVIM_CONFIG}/practice.md"
check_link cheatsheet.md "${NVIM_CONFIG}/cheatsheet.md"

# --- language servers -------------------------------------------------------
hdr "Language servers"
[[ -x "${LIB_DIR}/bin/bash-language-server" ]] && ok "bash-language-server present" || info "bash-language-server missing  (run: make bashls)"
[[ -x "${LIB_DIR}/bin/pyright-langserver" ]]   && ok "pyright present"              || info "pyright missing  (run: make pyright)"
[[ -e "${BIN_DIR}/make-language-server" ]]     && ok "make-language-server present" || info "make-language-server missing  (run: make makels)"

# --- legacy files -----------------------------------------------------------
hdr "Legacy files"
if [[ -e "${NVIM_CONFIG}/init.vim" ]]; then
   warn "${NVIM_CONFIG}/init.vim exists  (make setup retires it)"
else
   ok "no legacy init.vim"
fi
if [[ -e "${HOME}/.vimrc" ]]; then
   info "${HOME}/.vimrc exists  (Vim config; not used by this Neovim setup)"
fi

echo
exit 0
