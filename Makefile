# Makefile - set up my Neovim environment on a new workstation.
#
# The whole thing is:  make setup && make install
#   setup    links this bundle's Neovim config into ~/.config/nvim
#   install  downloads Neovim, Node, tree-sitter, the linters/formatters and
#            the language servers into $HOME (no root)
#
# This directory is self-contained: copy or move it anywhere and both halves
# still work, because every path is resolved relative to this Makefile (not the
# directory you run `make` from) and everything installs under $HOME.
#
# Targets:
#   make setup        Symlink the Neovim config into ~/.config/nvim
#   make install      Install everything
#   make nvim         Install Neovim into ~/bin/nvim-<version>
#   make node         Install Node.js into ~/bin/node-<version>
#   make tree-sitter  Install the tree-sitter CLI into ~/bin
#   make cargo        Install Rust/cargo (for TREE_SITTER_METHOD=cargo on old glibc)
#   make shellcheck   Install ShellCheck (Bash linting, used by bashls)
#   make shfmt        Install shfmt (Bash formatting, used by bashls)
#   make ruff         Install Ruff (Python lint + format, run as an LSP)
#   make lsp          Install all language servers into ~/lib
#   make bashls       Install the Bash language server
#   make pyright      Install the Python (Pyright) language server
#   make makels       Install the Make/Autotools language server
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

.PHONY: help setup install nvim node tree-sitter cargo shellcheck shfmt ruff lsp bashls pyright makels check

help:
	@echo 'Usage: make <target>'
	@echo
	@echo 'Targets:'
	@echo '  setup        Symlink the Neovim config into ~/.config/nvim'
	@echo '  install      Install everything'
	@echo '  nvim         Install Neovim into ~/bin'
	@echo '  node         Install Node.js into ~/bin'
	@echo '  tree-sitter  Install the tree-sitter CLI into ~/bin'
	@echo '  cargo        Install Rust/cargo (for TREE_SITTER_METHOD=cargo)'
	@echo '  shellcheck   Install ShellCheck (Bash linting, used by bashls)'
	@echo '  shfmt        Install shfmt (Bash formatting, used by bashls)'
	@echo '  ruff         Install Ruff (Python lint + format, run as an LSP)'
	@echo '  lsp          Install all language servers into ~/lib'
	@echo '  bashls       Install the Bash language server'
	@echo '  pyright      Install the Python (Pyright) language server'
	@echo '  makels       Install the Make/Autotools language server'
	@echo '  check        Report the setup state (read-only)'
	@echo '  help         Show this help'

# Symlink the Neovim config from this bundle into ~/.config/nvim.
setup:
	$(ROOT)link_config.sh

# Install everything, in order (Node must precede the language servers).
install: nvim node tree-sitter shellcheck shfmt ruff lsp

# Download and install Neovim locally (auto-detects OS/architecture).
nvim:
	$(ROOT)nvim.sh

# Download and install Node.js locally (needed by the language servers).
node:
	$(ROOT)node.sh

# tree-sitter CLI - nvim-treesitter's main branch builds parsers with it. Set
# TREE_SITTER_METHOD=cargo to build from source on machines with an old glibc.
tree-sitter:
	$(ROOT)tree_sitter.sh

# Rust/cargo - only needed to build tree-sitter from source
# (TREE_SITTER_METHOD=cargo) where the prebuilt binary's glibc is too new.
# Not part of `make install`.
cargo:
	$(ROOT)cargo.sh

# ShellCheck - Bash linter that bash-language-server picks up automatically.
shellcheck:
	$(ROOT)shellcheck.sh

# shfmt - Bash formatter that bash-language-server uses for formatting.
shfmt:
	$(ROOT)shfmt.sh

# Ruff - Python linter/formatter, wired up as a language server in init.lua.
ruff:
	$(ROOT)ruff.sh

# All language servers.
lsp: bashls pyright makels

# Individual language servers.
bashls:
	$(ROOT)bash_language_server.sh

pyright:
	$(ROOT)pyright.sh

# Make/Autotools language server (pip-based; provides make-language-server).
# Needs a venv-capable python3.
makels:
	$(ROOT)autotools_language_server.sh

# Report the state of the setup (read-only): what PATH resolves to, where the
# config symlinks point, and any legacy files. Handy when migrating.
check:
	$(ROOT)check.sh
