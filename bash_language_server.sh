#!/usr/bin/env bash
#
# bash_language_server.sh - install the Bash language server into ~/lib.
#
# https://github.com/bash-lsp/bash-language-server
# Installed via npm (no root); Neovim's init.lua runs
# ~/lib/bin/bash-language-server. Requires Node - run node.sh first.
#
# Usage:
#   ./bash_language_server.sh
#   LIB_DIR=/somewhere ./bash_language_server.sh   # override install prefix

set -euo pipefail

# Shared helpers, kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

install_npm_server bash-language-server bash-language-server
