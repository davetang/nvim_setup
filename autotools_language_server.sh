#!/usr/bin/env bash
#
# autotools_language_server.sh - install the Make/Autotools language server.
#
# https://autotools-language-server.readthedocs.io
# The `autotools-language-server` pip package provides make-language-server
# (Makefile / Makefile.am), which init.lua wires up. Installed via pip into a
# dedicated venv under ~/lib, with the binary linked into ~/bin. Requires a
# venv-capable python3 (conda's works).
#
# Note: init.lua also references config-language-server (for configure.ac),
# which this package does not provide - install that separately if you need it.
#
# Usage:
#   ./autotools_language_server.sh
#   FORCE=1 ./autotools_language_server.sh    # recreate the venv
#   LIB_DIR=/somewhere ./autotools_language_server.sh

set -euo pipefail

# Shared helpers, kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

install_pip_server autotools-language-server autotools-language-server make-language-server
