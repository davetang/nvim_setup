#!/usr/bin/env bash
#
# pyright.sh - install the Pyright Python language server into ~/lib.
#
# https://github.com/microsoft/pyright
# Installed via npm (no root); Neovim's init.lua runs
# ~/lib/bin/pyright-langserver. Requires Node - run node.sh first.
#
# Usage:
#   ./pyright.sh
#   LIB_DIR=/somewhere ./pyright.sh   # override install prefix

set -euo pipefail

# Shared helpers, kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# The package is `pyright`; init.lua invokes `pyright-langserver`, and the
# `pyright` CLI is what supports --version for the report.
install_npm_server pyright pyright-langserver pyright
