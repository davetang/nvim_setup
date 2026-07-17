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

**On an older Linux** (glibc < 2.39, e.g. many HPC/cluster nodes) the prebuilt
tree-sitter won't run — install it from conda-forge instead (needs an active
Miniforge/conda env), otherwise identical:

```sh
make setup && TREE_SITTER_METHOD=conda make install
```

- `make setup` — symlinks the config (`init.lua`, `lazy.lua`, `spec1.lua`,
  `practice.md`, `cheatsheet.md`) into `~/.config/nvim`.
- `make install` — downloads Neovim, Node.js, tree-sitter, the linters/
  formatters (ShellCheck, shfmt, Ruff) and the language servers into `$HOME`.

The installers only *warn* about `PATH`; adding `~/bin` to it is the one manual
step. On first launch, `nvim` installs its plugins via lazy.nvim (needs network
and a C compiler for the Treesitter parsers) — if highlighting errors, run
`:TSUpdate` and restart once the parsers finish building.

## Requirements

- `make`, `tar`, and `curl` or `wget`
- a C compiler (`cc`/`gcc`/`clang`) — nvim-treesitter builds parsers with it
- Internet access (GitHub, nodejs.org, npm, PyPI)
- For the Make language server (`makels`): a venv-capable `python3` — conda's
  works; a bare Debian/Ubuntu `python3` needs the `python3-venv` package
- Node.js and the tree-sitter CLI are installed by the bundle, so they are
  *not* prerequisites
- The prebuilt Neovim and tree-sitter binaries are dynamically linked;
  tree-sitter needs **glibc 2.39+** (Ubuntu 24.04 / recent Linux). On an older
  system, pick a different tree-sitter method with `TREE_SITTER_METHOD` — set it
  for the *whole* install (it propagates to the `tree-sitter` step) and use it
  **every time**, since plain `make install` re-downloads the prebuilt binary:
  - **conda** (easiest, needs Miniforge/conda): `TREE_SITTER_METHOD=conda make
    install` installs conda-forge's `tree-sitter-cli` (built for old glibc) and
    links it into `~/bin`.
  - **cargo** (no conda): `make cargo` once, then `TREE_SITTER_METHOD=cargo make
    install`. Builds from source — needs a C compiler *and* libclang.

  To repair an existing install without redoing everything, run just
  `TREE_SITTER_METHOD=<conda|cargo> make tree-sitter`.

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
| `make cargo` | Install Rust/cargo (only for `TREE_SITTER_METHOD=cargo`) |
| `make screen` | Build GNU Screen 5.x from source for true 24-bit colour (opt-in; needs a compiler + ncurses) |
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
| `NVIM_VERSION`, `NODE_VERSION`, `TREE_SITTER_VERSION`, `SHELLCHECK_VERSION`, `SHFMT_VERSION`, `RUFF_VERSION`, `SCREEN_VERSION` | Pin a specific version instead of the default |
| `FORCE=1` | Reinstall even if the versioned directory already exists |
| `DRY_RUN=1` | Print what would happen without downloading (the binary installers) |
| `TREE_SITTER_METHOD` | tree-sitter install method: `prebuilt` (default), `conda`, or `cargo` (for old glibc) |
| `NCURSES_PREFIX` | `make screen`: an ncurses install to build against (else an active conda env, else the system) |
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
  **first** on `PATH` so the new tools win over the old ones. On the first nvim
  launch after migrating, run **`:Lazy sync`** and restart so plugins update to
  the new specs — in particular nvim-treesitter switches from `master` to its
  `main` branch (needed by Neovim 0.12+).

## Editor behaviour

Notable things the config (`init.lua`) sets up — see the full keymap list with
`:Cheatsheet` inside nvim.

- **Colours.** Solarized dark via
  [solarized.nvim](https://github.com/maxmx03/solarized.nvim), in true 24-bit
  colour (`termguicolors` on by default). This needs the *whole* chain to carry
  24-bit: a truecolor terminal, and, if you use a multiplexer, one that passes
  it through. GNU `screen` only does since **5.0** (`truecolor on` in
  `~/.screenrc`, in a *fresh* session); 4.x silently down-samples to 256 — if
  your `screen` is older, **`make screen`** builds 5.x locally under `~/bin`.
  (tmux carries truecolor with the usual `Tc`/`RGB` terminfo override.)
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
- **Diagnostics.** Errors and warnings show inline (virtual text) at the end of
  the flagged line, so you can read them without moving onto each one; `<leader>d`
  opens the full message in a float and `]d` / `[d` jump between them. When a line
  has diagnostics from more than one server (e.g. pyright and ruff), the source
  name is appended.
- **Markdown.** Two ways to view it. **In-buffer:**
  [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim)
  draws headings, fenced code, tables, and checkboxes right in the buffer as you
  edit (the raw markup returns on the line you're on); it's automatic on markdown
  files and `<leader>mr` toggles it. **In a browser:** `<leader>mp`
  (`:MarkdownPreviewToggle`) starts a live preview server on port **8090** and
  *prints its URL* rather than opening a browser — deliberately headless, since
  nvim runs on a remote box. Forward the port from your machine
  (`ssh -L 8090:localhost:8090 …`) and open the URL locally; it auto-updates as
  you type and renders mermaid, KaTeX, emoji, and task lists. (First use needs
  the plugin's Node build to have succeeded — check `:Lazy` if the preview does
  nothing.)
- **Clipboard.** OSC 52 — `"+y` copies to your *local* clipboard over SSH.
- **Undo.** Persistent across sessions (`undofile`).
- **Ask about code (Ollama).** `<leader>cc` opens a chat with a local LLM via
  [codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim); in
  visual mode `<leader>ca` sends the highlighted code into the chat so you can
  ask about it, and `<leader>ci` runs the inline assistant to write/edit code in
  place (on the selection in visual mode). It talks to an **Ollama** server at
  `$OLLAMA_HOST` (default `http://localhost:11434`), using the model in
  **`$OLLAMA_MODEL`** (default `qwen2.5-coder:7b`), which must be pulled on the
  server; switch models live in the chat with `ga`. Ollama itself is **not**
  installed by this bundle — have it running/reachable, then set `OLLAMA_HOST` as
  a **full URL** (`http://host:port`, *with* the scheme — a bare `host:port`
  won't work) and `export` it from your shell rc so nvim inherits it at launch
  (restart nvim after changing it). See `:Cheatsheet` for the in-chat keys.

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
