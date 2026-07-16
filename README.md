# Neovim setup

A self-contained, no-root setup for my Neovim environment. Everything installs
under `$HOME`, so it works on workstations where I don't have admin rights, and
the whole directory can be copied or moved anywhere — every path is resolved
relative to the `Makefile`, and nothing outside this directory is needed.

## Quick start

```sh
make setup && make install
export PATH="$HOME/bin:$PATH"     # add to your shell rc so it persists
nvim
```

- `make setup` — symlinks the config (`init.lua`, `lazy.lua`, `spec1.lua`,
  `practice.md`, `cheatsheet.md`) into `~/.config/nvim`.
- `make install` — downloads Neovim, Node.js, tree-sitter, the linters/
  formatters (ShellCheck, shfmt, Ruff) and the language servers into `$HOME`.

The installers only *warn* about `PATH`; adding `~/bin` to it is the one manual
step. On first launch, `nvim` will install its plugins via lazy.nvim (needs
network, a C compiler for Treesitter parsers, and the Node just installed).

## Requirements

- `make`, `tar`, and `curl` or `wget`
- a C compiler (`cc`/`gcc`/`clang`) — nvim-treesitter builds parsers with it
- Internet access (GitHub, nodejs.org, npm, PyPI)
- For the Make language server (`makels`): a venv-capable `python3` — conda's
  works; a bare Debian/Ubuntu `python3` needs the `python3-venv` package
- Node.js and the tree-sitter CLI are installed by the bundle, so they are
  *not* prerequisites
- The prebuilt Neovim and tree-sitter binaries are dynamically linked;
  tree-sitter needs **glibc 2.39+** (Ubuntu 24.04 / recent Linux). On older
  systems install tree-sitter another way, e.g. `cargo install tree-sitter-cli`.

## What gets installed, and where

| Component | Location | Exposed in `~/bin` |
|-----------|----------|--------------------|
| Neovim | `~/bin/nvim-<version>/` | `nvim` |
| Node.js | `~/bin/node-<version>/` | `node`, `npm`, `npx` |
| tree-sitter CLI | `~/bin/tree-sitter-<version>/` | `tree-sitter` |
| ShellCheck | `~/bin/shellcheck-<version>/` | `shellcheck` |
| shfmt | `~/bin/shfmt-<version>/` | `shfmt` |
| Ruff | `~/bin/ruff-<version>/` | `ruff` |
| bash-language-server | `~/lib/` (npm) | via `~/lib/bin/` |
| pyright | `~/lib/` (npm) | via `~/lib/bin/` |
| make-language-server | `~/lib/autotools-language-server/` (venv) | `make-language-server` |
| Neovim config | symlinks in `~/.config/nvim/` → this bundle | — |

## Make targets

| Target | Does |
|--------|------|
| `make setup` | Symlink the Neovim config into `~/.config/nvim` |
| `make install` | Everything (Neovim, Node, tree-sitter, tools, servers) |
| `make nvim` | Install Neovim into `~/bin` |
| `make node` | Install Node.js into `~/bin` |
| `make tree-sitter` | Install the tree-sitter CLI into `~/bin` |
| `make shellcheck` / `make shfmt` | ShellCheck / shfmt for Bash (used by bashls) |
| `make ruff` | Ruff for Python (lint + format, runs as an LSP) |
| `make lsp` | All language servers (`bashls` + `pyright` + `makels`) |
| `make bashls` | Bash language server |
| `make pyright` | Python (Pyright) language server |
| `make makels` | Make/Autotools language server |
| `make check` | Report the setup state (read-only) — PATH, config symlinks, legacy files |
| `make help` | List targets |

Running targets individually? Install `node` before `lsp` (the Bash and Python
servers need `npm`). `make install` already orders them correctly.

## Options

Set as environment variables, e.g. `NVIM_VERSION=0.11.3 make nvim`:

| Variable | Effect |
|----------|--------|
| `NVIM_VERSION`, `NODE_VERSION`, `TREE_SITTER_VERSION`, `SHELLCHECK_VERSION`, `SHFMT_VERSION`, `RUFF_VERSION` | Pin a specific version instead of the default |
| `FORCE=1` | Reinstall even if the versioned directory already exists |
| `DRY_RUN=1` | Print what would happen without downloading (the binary installers) |
| `BIN_DIR` / `LIB_DIR` | Override the install prefixes (default `~/bin` / `~/lib`) |

## Notes

- **Idempotent.** Re-running is safe: existing installs are skipped (use
  `FORCE=1` to reinstall) and symlinks are just refreshed.
- **The config lives here.** `make setup` points `~/.config/nvim` at the files
  in this directory, so editing your config means editing them. Any real file
  it would overwrite is backed up to `*.bak-<timestamp>` first, and a
  conflicting legacy `init.vim` is retired the same way.
- **Migrating from an older manual setup?** Run **`make check`** first — it
  reports (read-only) what your `PATH` resolves to for each tool, where your
  `~/.config/nvim` symlinks point, and any legacy files, so you can spot an old
  install shadowing the new one. `make setup` then relinks the config safely
  (replacing old symlinks, backing up real files); just make sure `~/bin` is
  **first** on `PATH` so the new tools win over the old ones.

## Editor behaviour

Notable things the config (`init.lua`) sets up — see the full keymap list with
`:Cheatsheet` inside nvim.

- **Colours.** Solarized dark, in **256-colour mode** (`termguicolors` is
  *off*). 24-bit truecolor doesn't survive GNU `screen`, whereas 256-colour
  renders through any terminal/multiplexer. To use true 24-bit colour instead:
  set `vim.opt.termguicolors = true`, drop `vim.g.solarized_termcolors`, and
  enable truecolor in your multiplexer (for screen: `term screen-256color` +
  `truecolor on` in `~/.screenrc`).
- **Completion.** Native LSP completion (autotriggered) plus buffer-word
  completion in every filetype — the menu pops up as you type. `<Tab>`/`<S-Tab>`
  select, `<CR>` confirms. (coc.nvim was replaced by the built-in completion.)
- **Language servers.** pyright + Ruff for Python (types + lint/format), bashls
  for shell (which picks up ShellCheck and shfmt from `~/bin`), and
  make-language-server for Makefiles. Each roots at the nearest `.git`,
  **falling back to the file's own directory**, so cross-file features work even
  outside a repo — e.g. `gd` on a Bash function jumps to its definition in a
  sibling file (bashls also sets `includeAllWorkspaceSymbols` so it looks across
  the whole workspace, not only `source`d files).
- **Markdown preview.** `<leader>mp` (`:MarkdownPreviewToggle`) starts a live
  preview server on port **8090** and *prints its URL* rather than opening a
  browser — deliberately headless, since nvim runs on a remote box. Forward the
  port from your machine (`ssh -L 8090:localhost:8090 …`) and open the URL in
  your local browser; it auto-updates as you type and renders mermaid, KaTeX,
  emoji, and task lists. (First use needs the plugin's Node build to have
  succeeded — check `:Lazy` if the preview does nothing.)
- **Clipboard.** OSC 52 — `"+y` copies to your *local* clipboard over SSH.
- **Undo.** Persistent across sessions (`undofile`).

## Testing in Docker

Build the Ubuntu image from
[learning_docker](https://github.com/davetang/learning_docker), then run this
bundle inside it:

```sh
# <image> is the Ubuntu image you built from learning_docker
docker run --rm -it -v "$PWD":/work -w /work <image> bash
make install && make setup
export PATH="$HOME/bin:$PATH"
nvim
```
