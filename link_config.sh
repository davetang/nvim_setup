#!/usr/bin/env bash
#
# link_config.sh - symlink this bundle's Neovim config into ~/.config/nvim.
#
# The config sources (init.lua, lazy.lua, spec1.lua, practice.md) live beside
# this script, so the whole setup directory is self-contained. Idempotent, and
# any real file it would overwrite is backed up first (never clobbered).
#
# Usage:
#   ./link_config.sh

set -euo pipefail

# Shared helpers and config sources both live beside this script.
readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${HERE}/lib.sh"

readonly NVIM_CONFIG="${HOME}/.config/nvim"
readonly BIN_DIR="${BIN_DIR:-${HOME}/bin}"

# Neovim refuses to start if both init.vim and init.lua exist. Retire any
# legacy init.vim so our init.lua is the sole entry point.
legacy="${NVIM_CONFIG}/init.vim"
if [[ -L "${legacy}" ]]; then
   rm -f "${legacy}"
   msg "Removed legacy init.vim symlink"
elif [[ -e "${legacy}" ]]; then
   backup="${legacy}.bak-$(date +%Y%m%d%H%M%S)"
   mv "${legacy}" "${backup}"
   msg "Retired legacy init.vim -> ${backup}"
fi

safe_symlink "${HERE}/init.lua"      "${NVIM_CONFIG}/init.lua"
safe_symlink "${HERE}/lazy.lua"      "${NVIM_CONFIG}/lua/config/lazy.lua"
safe_symlink "${HERE}/spec1.lua"     "${NVIM_CONFIG}/lua/plugins/spec1.lua"
safe_symlink "${HERE}/practice.md"   "${NVIM_CONFIG}/practice.md"
safe_symlink "${HERE}/cheatsheet.md" "${NVIM_CONFIG}/cheatsheet.md"

if [[ -e "${HOME}/.vimrc" ]]; then
   msg "Note: ~/.vimrc exists but is not used by this Neovim (Lua) setup; left untouched."
fi

msg ""
msg "Neovim config linked into ${NVIM_CONFIG}."
warn_if_not_on_path "${BIN_DIR}"
