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
# Two pins, both because of the same upstream rewrite wave in July 2026:
#
#   autotools-language-server==0.0.23  - 0.1.0 (2026-07-19) rewrote the package
#     for configure.ac only, dropping tree-sitter-make along with the
#     make-language-server and autoconf-language-server console scripts.
#   lsp-tree-sitter==0.1.1  - 0.2.0 (2026-07-19) reorganised the module layout,
#     replacing diagnose/finders/complete/format/schema with linter/completer/
#     server. 0.0.23 imports lsp_tree_sitter.{diagnose,finders,misc,utils} but
#     only asks for >=0.1.0, so pip resolves 0.2.x and the server dies at
#     startup with ModuleNotFoundError. 0.1.1 is the last of the old layout.
#
# Both must move together; unpin only if Makefile support returns upstream.
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

install_pip_server \
   "autotools-language-server==0.0.23 lsp-tree-sitter==0.1.1" \
   autotools-language-server \
   make_language_server.server \
   make-language-server
