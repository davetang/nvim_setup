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

## Clipboard (OSC 52, over SSH)

| Key | Action |
|-----|--------|
| `"+y{motion}`, `"+yy`, `"+y` (visual) | Copy to the clipboard of the machine you're sitting at, also inside GNU screen |
| `"+p` | Paste Neovim's own last yank (it can't read your local clipboard) |
| Terminal's paste key, in insert mode | Paste from your local clipboard |

Needs a terminal that accepts OSC 52 (kitty does; MobaXterm doesn't).

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

Servers: **pyright** + **ruff** (Python — types + lint/format), **bash-language-server** (sh/bash, uses **shellcheck** + **shfmt**), **PerlNavigator** (Perl), **make-language-server** (Makefiles), and for R, R.nvim's own server plus **Air** (format) + **Jarl** (lint, on save).

## Diagnostics (errors, warnings, lint)

The language servers report problems as you work: pyright and ruff in Python,
**ShellCheck** (through bash-language-server) in shell scripts, Jarl in R, and
so on. Each one shows **inline** at the end of its line, as a letter in the sign
column, and as a count at the right of the status line (`E:1 W:3 I:4`).

| Key / Command | Action |
|-----|--------|
| `]d` / `[d` | Next / previous diagnostic (`3]d` skips ahead three) |
| `]D` / `[D` | Last / first diagnostic in the buffer |
| `<leader>d` or `<C-w>d` | Show the full message under the cursor in a float |
| `gra` | **Code actions** for the line under the cursor: fixes, or silence the rule |
| `:lua vim.diagnostic.setloclist()` | All of this buffer's diagnostics in the location list; `:lopen` shows it, `<CR>` jumps |
| `:lua vim.diagnostic.setqflist()` | The same for every open buffer, in the quickfix list (`:copen`) |
| `:Telescope diagnostics bufnr=0` | Pick one with a preview (drop `bufnr=0` for every open buffer) |
| `:lua vim.diagnostic.enable(false)` | Turn diagnostics off (`true` turns them back on) |

`gra` shares its start with the `gr` (references) mapping above, so type it
quickly: after a bare `gr`, Neovim waits a second for more keys before showing
references.

**ShellCheck.** The float ends with the rule's code, e.g. `[SC2155]`, and every
rule has a page with examples and the fix at
`https://www.shellcheck.net/wiki/SC2155`. `gra` offers **Disable ShellCheck rule
… for this command**, which adds a `# shellcheck disable=SC2155` comment above
the line, or **… for the entire file**, which puts it under the `#!` line. Some
rules also offer an automatic fix.

**Ask the LLM** (CodeCompanion, below). In the chat (`<leader>cc`), `#{diagnostics}`
sends the file's diagnostics with each flagged line, and `#{buffer}` adds the
whole file: `#{buffer} #{diagnostics} explain these and how to fix them`.

## Completion (native LSP + buffer words + file paths)

The menu pops up automatically as you type — from the language server in code,
and from buffer words in any filetype (Markdown, plain text, …). Typing a path
into a directory that exists (`/data/s`, `~/proj/`, `./R/`) lists that
directory's files instead, in every filetype; relative paths are taken from
Neovim's current directory (`:pwd`). Nothing is inserted until you pick an
item; accepting a directory lists what is inside it.

| Key | Action |
|-----|--------|
| `<Tab>` / `<S-Tab>` | Select next / previous item |
| `<CR>` | Confirm the selected item (plain newline if none selected) |
| `<C-e>` | Cancel the popup |
| `<C-x><C-f>` | Complete a file path by hand |

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
pulled on the server, and you can switch models live in the chat with `ga` or use:

```
:CodeCompanionChat adapter=openai model=gpt-4.1
```

| Key / Command | Action |
|-----|--------|
| `<leader>cc` | Toggle the chat window — ask anything |
| `<leader>ca` (visual) | Add the `V` selection to the current chat (or start one); repeat to collect more, then type your question and send with `<CR>` |
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

Uses the local leader (`\`). A few common ones — `:RMapsDesc` lists them all:

| Key | Action |
|-----|--------|
| `\rf` | Start R in a terminal split |
| `\rq` | Quit R |
| `\l` | Send the current line to R |
| `\d` | Send the current line and move down |
| `\ss` | Send the selection (visual mode) |
| `\pp` | Send the current paragraph |
| `\aa` | Send / source the whole file |
| `\cc` / `\cd` | Send the current chunk / and move to the next (Rmd, Quarto) |
| `\kr` | Render the Rmd / Quarto document |
| `\ro` | Toggle the Object Browser |
| `\rh` | R help for the object under the cursor |
| `\rv` | View the data frame under the cursor |
| `\rs` / `\rp` | `summary()` / `print()` the object under the cursor |
| `<M-->` | (insert mode) Type ` <- ` |
| `<M-r>` | (insert mode, Rmd / Quarto) Insert a code chunk |
| `<leader>f` | Format the file (Air) |
| `:RFormat` | Format with styler (the selection, or the whole file; needs R running) |
| `:w` | Save — also what makes Jarl lint the file |
| `:checkhealth r` | Check R.nvim's dependencies |

Plots: R has no display on a remote box, so run `httpgd::hgd()`, forward the
port it prints (`ssh -L`), and open the URL locally.

## Python console (iron.nvim)

The R.nvim keys above work in Python files too, sending code to a console on
the right. It runs **IPython** when the project's environment has it (`uv add
--dev ipython`, then start nvim with `uv run nvim` or from an activated venv),
otherwise plain `python3`. Sending code starts the console if it isn't running.

| Key | Action |
|-----|--------|
| `\rf` | Start the Python console |
| `\rq` | Quit it |
| `\l` | Send the current line |
| `\d` | Send the current line and move to the next non-blank one |
| `\ss` | Send the selection (visual mode) |
| `\pp` | Send the current paragraph (stops at blank lines, so not for functions with blank lines in them: select those, or use a cell) |
| `\aa` | Send the whole file |
| `\cc` / `\cd` | Send the current `# %%` cell / and move to the next |
| `\rh` | `help()` on the object under the cursor (`help(math.sqrt)` with the cursor on `sqrt`) |
| `\rp` | `print()` the object under the cursor |

`<C-w>l` moves into the console (then `i` to type in it, `<C-\><C-n>` to get
back to normal mode); `:IronRestart` restarts it.

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
