# Makefile - set up my Neovim environment on a new workstation.
#
# The whole thing is:  make setup && make install
#   setup    links this bundle's Neovim config into ~/.config/nvim
#   install  downloads Neovim, Node, tree-sitter and the language servers into
#            $HOME (no root)
#
# This directory is self-contained: copy or move it anywhere and both halves
# still work, because every path is resolved relative to this Makefile (not the
# directory you run `make` from) and everything installs under $HOME.
#
# Targets:
#   make setup        Symlink the Neovim config into ~/.config/nvim
#   make deps         Preflight: check every prerequisite is present (read-only)
#   make install      Install everything (runs `deps` first; aborts if any unmet)
#   make nvim         Install Neovim into ~/bin/nvim-<version>
#   make node         Install Node.js into ~/bin/node-<version>
#   make tree-sitter  Install the tree-sitter CLI (conda-forge) into ~/bin
#   make lsp          Install all language servers into ~/lib
#   make bashls       Install the Bash language server
#   make pyright      Install the Python (Pyright) language server
#   make makels       Install the Make/Autotools language server
#   make perlnavigator Install the Perl (PerlNavigator) language server
#   make check        Report the setup state (read-only; spot conflicts)
#   make help         List available targets

SHELL := /bin/bash

# Absolute path to the directory holding this Makefile (with trailing slash),
# so recipes work regardless of the current directory - e.g. even when invoked
# as `make -f /somewhere/Makefile`.
ROOT := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

.DEFAULT_GOAL := help

# Install steps depend on each other (e.g. the language servers need Node), so
# keep the build sequential even if invoked with -j.
.NOTPARALLEL:

.PHONY: help setup deps install nvim node tree-sitter lsp bashls pyright makels perlnavigator check

help:
	@echo 'Usage: make <target>'
	@echo
	@echo 'Targets:'
	@echo '  setup        Symlink the Neovim config into ~/.config/nvim'
	@echo '  deps         Preflight: check every prerequisite is present (read-only)'
	@echo '  install      Install everything (runs deps first; aborts if any unmet)'
	@echo '  nvim         Install Neovim into ~/bin'
	@echo '  node         Install Node.js into ~/bin'
	@echo '  tree-sitter  Install the tree-sitter CLI (conda-forge) into ~/bin'
	@echo '  lsp          Install all language servers into ~/lib'
	@echo '  bashls       Install the Bash language server'
	@echo '  pyright      Install the Python (Pyright) language server'
	@echo '  makels       Install the Make/Autotools language server'
	@echo '  perlnavigator Install the Perl (PerlNavigator) language server'
	@echo '  check        Report the setup state (read-only)'
	@echo '  help         Show this help'

# Symlink the Neovim config from this bundle into ~/.config/nvim.
setup:
	$(ROOT)link_config.sh

# Preflight: verify every prerequisite the README lists (make/tar/curl, a C
# compiler, Python 3.11+ with venv support, and an active conda env for
# tree-sitter) is present. Read-only. `install` depends on it, so a missing
# dependency stops the whole run up front instead of failing partway through.
deps:
	$(ROOT)deps.sh

# Install everything, in order (Node must precede the language servers). `deps`
# runs first: if any prerequisite is missing, install does not start at all.
install: deps nvim node tree-sitter lsp

# Download and install Neovim locally (auto-detects OS/architecture).
nvim:
	$(ROOT)nvim.sh

# Download and install Node.js locally (needed by the language servers).
node:
	$(ROOT)node.sh

# tree-sitter CLI - nvim-treesitter's main branch builds parsers with it.
# Installed from conda-forge into the active conda env, so it runs on old glibc.
tree-sitter:
	$(ROOT)tree_sitter.sh

# All language servers.
lsp: bashls pyright makels perlnavigator

# Individual language servers.
bashls:
	$(ROOT)bash_language_server.sh

pyright:
	$(ROOT)pyright.sh

# Make/Autotools language server (pip-based; provides make-language-server).
# Needs Python 3.11+ with venv support, so preflight that first (running it
# standalone would otherwise reproduce the typing.Self crash on an old python3).
makels:
	$(ROOT)deps.sh python
	$(ROOT)autotools_language_server.sh

# Perl language server (npm-based; provides the `perlnavigator` binary). Uses
# the system `perl -c` for syntax checking; perlcritic/perltidy (CPAN, optional)
# are not installed here.
perlnavigator:
	$(ROOT)perl_navigator.sh

# Report the state of the setup (read-only): what PATH resolves to, where the
# config symlinks point, and any legacy files. Handy when migrating.
check:
	$(ROOT)check.sh
