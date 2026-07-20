#!/usr/bin/env bash
#
# perl_navigator.sh - install the PerlNavigator language server into ~/lib.
#
# https://github.com/bscan/PerlNavigator
# Installed via npm (no root); Neovim's init.lua runs
# ~/lib/bin/perlnavigator. Requires Node - run node.sh first.
#
# PerlNavigator shells out to the system `perl -c` for syntax checking, and
# picks up perlcritic (lint) and perltidy (format) automatically if they are on
# PATH - the same way bashls uses ShellCheck and shfmt. Those two are CPAN
# modules (Perl::Critic, Perl::Tidy), optional, and NOT installed by this
# bundle; add them with `cpanm --local-lib` if you want lint/format.
#
# Usage:
#   ./perl_navigator.sh
#   LIB_DIR=/somewhere ./perl_navigator.sh   # override install prefix
#
# The npm package is `perlnavigator-server`; it installs a `perlnavigator`
# executable, which is what init.lua invokes.

set -euo pipefail

# Shared helpers, kept beside this script.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

install_npm_server perlnavigator-server perlnavigator
