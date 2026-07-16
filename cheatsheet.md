# Cheatsheet

Quick reference for the LSP and plugin shortcuts in this Neovim setup.
Open it anytime with `:Cheatsheet`.

**Leaders:** `<leader>` = **Space**, `<localleader>` = **\\** (backslash).

## LSP (code intelligence)

| Key | Action |
|-----|--------|
| `K` | **Hover documentation** for the symbol under the cursor (press again to enter the float) |
| `gd` | Go to definition |
| `gi` | Go to implementation |
| `gr` | Find references |
| `<leader>rn` | Rename the symbol everywhere |
| `<leader>f` | Format the buffer |
| `<leader>d` | Show the diagnostic under the cursor in a float |
| `]d` / `[d` | Next / previous diagnostic |

Servers: **pyright** + **ruff** (Python — types + lint/format), **bash-language-server** (sh/bash, uses **shellcheck** + **shfmt**), **make-language-server** (Makefiles).

## Completion (native LSP + buffer words)

The menu pops up automatically as you type — from the language server in code,
and from buffer words in any filetype (Markdown, plain text, …). Nothing is
inserted until you pick an item.

| Key | Action |
|-----|--------|
| `<Tab>` / `<S-Tab>` | Select next / previous item |
| `<CR>` | Confirm the selected item (plain newline if none selected) |
| `<C-e>` | Cancel the popup |

## Fuzzy finding (Telescope)

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep (search file contents) |
| `<leader>fb` | Open buffers |
| `<leader>fh` | Help tags |

## File explorer

| Key / Command | Action |
|-----|--------|
| `<leader>fe` | netrw file explorer (`:Explore`) |
| `:NvimTreeToggle` | Open / close the file tree |
| `:NvimTreeFocus` | Focus the tree |
| `:NvimTreeFindFile` | Reveal the current file in the tree |
| `:NvimTreeCollapse` | Collapse the tree |

## Git

**Fugitive** (`tpope/vim-fugitive`) — the main Git interface. Start with **`:G`**.

| Command | Action |
|-----|--------|
| **`:G`** (or `:Git`) | **Open the Git status window** — the hub for staging & committing |
| `:G commit` | Commit the staged changes |
| `:G push` / `:G pull` | Push / pull |
| `:G blame` | Inline blame for the current file |
| `:G log` | Commit log |
| `:Gdiffsplit` | Diff the current file against the index |
| `:Gwrite` / `:Gread` | Stage the file / revert it to the index version |

Inside the **`:G` status window**:

| Key | Action |
|-----|--------|
| `s` / `u` | Stage / unstage the file (or hunk) under the cursor |
| `-` | Toggle staged/unstaged |
| `=` | Toggle the inline diff for the item under the cursor |
| `cc` / `ca` | Create a commit / amend the last one |
| `X` | Discard the change under the cursor |
| `<CR>` | Open the file under the cursor |
| `g?` | Show all mappings for this window |
| `gq` | Close the status window |

**gitgutter** (`airblade/vim-gitgutter`) — change signs in the gutter:

| Key | Action |
|-----|--------|
| `]c` / `[c` | Next / previous changed hunk |
| `<leader>hp` | Preview hunk |
| `<leader>hs` / `<leader>hu` | Stage / undo hunk |

## Markdown

| Key / Command | Action |
|-----|--------|
| `<leader>mp` | Toggle live preview (`:MarkdownPreviewToggle`) |
| `:MarkdownPreview` / `:MarkdownPreviewStop` | Start / stop the preview |
| `:Toc` | Table of contents (vim-markdown) |
| `zR` / `zM` | Open / close all header folds |
| `]]` / `[[` | Next / previous header |

Preview runs on a fixed port (8090) for headless/SSH use — forward it with `ssh -L 8090:localhost:8090`.

## Editing helpers

| Command | Action |
|-----|--------|
| `:EasyAlign` | Interactive alignment on a delimiter (see `:h easy-align`) |
| `:Tabularize /<pattern>` | Align lines on a pattern |
| `:FixWhitespace` | Remove trailing whitespace |
| `:TableModeToggle` (`<leader>tm`) | Toggle Markdown/reST table editing |
| `:colorscheme solarized` | Switch to the solarized colorscheme |
| `<leader>?` | Show buffer-local keymaps (which-key) |

## R (R.nvim)

Uses the local leader (`\\`). A few common ones — see `:help R.nvim` for the full list:

| Key | Action |
|-----|--------|
| `\rf` | Start R in a terminal split |
| `\l` | Send the current line to R |
| `\pp` | Send the current paragraph |
| `\aa` | Send / source the whole file |
| `\rq` | Quit R |

## Plugins & health

| Command | Action |
|-----|--------|
| `:Lazy` | Plugin manager UI (`I` install, `U` update, `S` sync, `C` clean) |
| `:Lazy sync` | Apply changes after editing `spec1.lua` |
| `:TSUpdate` / `:TSInstall <lang>` | Update / install a treesitter parser |
| `:checkhealth` | Diagnose everything (`:checkhealth vim.lsp`, `nvim-treesitter`, `lazy`) |
| `:lua =vim.lsp.get_clients({ bufnr = 0 })` | List LSP clients attached to the current buffer |

## Custom commands

| Command | Action |
|-----|--------|
| `:Practice` | Open `practice.md` (things to practise) |
| `:Cheatsheet` | Open this file |
