# Cheatsheet

Quick reference for the LSP and plugin shortcuts in this Neovim setup.
Open it anytime with `:Cheatsheet`.

**Leaders:** `<leader>` = **Space**, `<localleader>` = **\\** (backslash).

## General

* When in `:terminal` use `Ctrl + \ + n` to go back to normal mode.
* When using vsplit:
    * Cycle between the splits: `Ctrl-w w`
    * Move to the left split: `Ctrl-w h`
    * Move to the right split: `Ctrl-w l`
* Use `gcc` to toggle commenting; this will be specific to the file type
    * Works with visual selection and `gc`
* `g` can be thought of as **go**; `gg` go to the top of the file or `gd` go to where a variable is defined
    * `gp` can also paste; see `:help g`

## Visual selection

* A selection is just a **range** the next command acts on.
* Select with `v` (charwise), `V` (linewise), or `<C-v>` (block).
* **Text objects** select by structure:
    * `i` = inner (contents only), `a` = around (include the delimiters):

| Key                     | Selects                                                                |
|-------------------------|------------------------------------------------------------------------|
| `vi(` `vi{` `vi[` `vi<` | inside brackets `va(` etc. keeps the brackets (`b` = `()`, `B` = `{}`) |
| `vi"` `vi'` `` vi` ``   | inside quotes                                                          |
| `vit`                   | inside an HTML/XML tag                                                 |

The same objects pair with any operator: `ci"` change inside quotes, `di(` delete inside parens, `yi{` yank inside braces.

Once something is selected:

| Key             | Action                                                                             |
|-----------------|------------------------------------------------------------------------------------|
| `d` / `c` / `y` | Delete / change / yank                                                             |
| `p`             | Paste over it: replaces the selection (yank one word, select another, `p` to swap) |
| `u` / `U` / `~` | Lower- / upper-case / toggle case                                                  |
| `>` / `<` / `=` | Indent right / left / re-indent                                                    |
| `r{char}`       | Replace **every** character with `{char}`                                          |
| `J`             | Join the lines (`gJ` = no space)                                                   |
| `gq`            | Reflow / wrap to `textwidth`                                                       |
| `g<C-a>`        | Turn selected lines into an incrementing `1, 2, 3…` sequence                       |
| `o`             | Jump to the other end, to extend the selection from there                          |
| `zf`            | Fold the selection away                                                            |

**Run a command on just the selection**:

| Key | Action                                                                       |
|-----|------------------------------------------------------------------------------|
| `:` | Opens `:'<,'>` — e.g. `:'<,'>s/foo/bar/g`, `:'<,'>sort u`, `:'<,'>normal A;` |
 | `!` | Filter the lines through a shell command: `!sort -u`, `!column -t`, `!jq .` |

**Visual block** (`<C-v>`) edits many lines at once: `I{text}<Esc>` inserts before every line, `A{text}<Esc>` appends after (use `$` first to append at each line's end).

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

Diagnostics show **inline** (virtual text) at the end of each flagged line; `<leader>d` opens the full message in a float, and `]d` / `[d` jump between them.

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
| `<leader>mr` | Toggle **in-buffer** render (render-markdown.nvim; auto-on for markdown) |
| `<leader>mp` | Toggle live browser preview (`:MarkdownPreviewToggle`) |
| `:MarkdownPreview` / `:MarkdownPreviewStop` | Start / stop the preview |
| `:Toc` | Table of contents (vim-markdown) |
| `zR` / `zM` | Open / close all header folds |
| `]]` / `[[` | Next / previous header |

Two ways to view Markdown: **render-markdown.nvim** draws it right in the buffer
(no browser — the raw markup returns on the line you're editing), while
**markdown-preview** opens a full browser render (mermaid, KaTeX). The preview
runs on a fixed port (8090) for headless/SSH use — forward it with
`ssh -L 8090:localhost:8090`.

## Ask about code (CodeCompanion + Ollama)

Chat with a local **Ollama** model without leaving Neovim. The adapter connects
to **`$OLLAMA_HOST`** (falling back to `http://localhost:11434`), so export that
to point at your Ollama server before launching nvim. The default model is
**`qwen2.5-coder:7b`** (override with **`$OLLAMA_MODEL`**); it must already be
pulled on the server, and you can switch models live in the chat with `ga`.

| Key / Command | Action |
|-----|--------|
| `<leader>cc` | Toggle the chat window — ask anything |
| `<leader>ca` (visual) | Send the highlighted code into a chat, then ask about it |
| `<leader>ci` | Inline assistant — type an instruction to write/edit code in place (visual = on the selection) |
| `:CodeCompanionChat` | Open a chat buffer directly |
| `:CodeCompanionActions` | Pick from the built-in prompt library |
| `:CodeCompanion <prompt>` | Inline assistant as a command (what `<leader>ci` runs) |

Inside the chat buffer:

| Key | Action |
|-----|--------|
| `?` | **Show all chat keymaps** |
| `<CR>` / `<C-s>` | Send the message |
| `gr` | Regenerate the last response |
| `ga` | Change the adapter / model |
| `q` | Stop the current request |
| `<C-c>` | Close the chat |

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
