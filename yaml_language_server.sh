#!/usr/bin/env bash
#
# yaml_language_server.sh - install the YAML language server into ~/lib.
#
# https://github.com/redhat-developer/yaml-language-server
# Installed via npm (no root). Requires Node - run node.sh first.
#
# init.lua does not start this server itself: R.nvim does, to complete keys in
# Quarto front matter and in _quarto.yml (with Quarto's own schema). R.nvim
# looks the server up on PATH, not by path the way init.lua starts the other
# servers, so this also links it into ~/bin. Without it, R.nvim simply skips
# that YAML completion.
#
# Usage:
#   ./yaml_language_server.sh
#   LIB_DIR=/somewhere ./yaml_language_server.sh   # override install prefix

set -euo pipefail

# Shared helpers, kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

install_npm_server yaml-language-server yaml-language-server

bin_dir="${BIN_DIR:-${HOME}/bin}"
exe="${LIB_DIR:-${HOME}/lib}/bin/yaml-language-server"
mkdir -p "${bin_dir}"
ln -sf "${exe}" "${bin_dir}/yaml-language-server"
msg "Linked ${bin_dir}/yaml-language-server -> ${exe}"
warn_if_not_on_path "${bin_dir}"
