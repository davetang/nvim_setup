## Table of Contents

  - [Fugitive](#fugitive)
  - [Telescope](#telescope)
  - [Language Server](#language-server)
  - [Practice](#practice)
    - [Diff mode](#diff-mode)
    - [Buffers](#buffers)
    - [Motions](#motions)
    - [Find and till](#find-and-till)
    - [Argument list](#argument-list)
    - [Quickfix list](#quickfix-list)
    - [Global command (:g)](#global-command-g)
    - [Repeatable change with cgn](#repeatable-change-with-cgn)
    - [Registers](#registers)

## Fugitive

The crown jewel of Fugitive is :Git (or just :G), which calls any arbitrary Git command. If you know how to use Git at the command line, you know how to use :Git.

Within Vim, just use `:G add`, `:G commit -m`, and `:G push`!

## Telescope

* `<leader>ff` - Telescope find files
* `<leader>fg` - Telescope live grep
* `<leader>fb` - Telescope buffers
* `<leader>fh` - Telescope help tags

To delete a buffer but keep window - `:bd` or `:bdelete`

## Language Server

* `<leader>d` - "Show diagnostic in float"
* `<leader>fe` - Open file explorer
* `gd` - Go to Definition
* `K` - Hover Documentation
* `gi` - Go to Implementation
* `<leader>rn` - Rename Symbol
* `gr` - Find References

## Practice

The only way to get good with Vim is by practicing. Here are some new shortcuts that I need to practice.

* Use `:normal` (or `:norm`) to execute normal mode commands as if you typed them directly.
    * `:%norm A;` - add `;` to the end of every line.
    * `:.,$norm I#` - add `#` to the start of the current line until the end.
    * `:1,.norm I#` - add `#` from the start to the current line.
* After matching using `*` you can replace all occurrences of the match by using `:%s//replacement/g`; `%` is the shorthand for `1,$`.
* `J` to join two lines together
* `o` insert a new line after the current one
* `O` insert a new line before the current one
* `^` go to first non-blank character (good for indented code)
* `g_` go to the last non-blank character of line
* Use `>` to increase the indentation; for example select lines to indent and press `>`.

```
          aaaaa
    bbbb    cccccccccc
done          
```

* `*` and `#` go to next and previous occurrence of word under cursor. Use `n`
  and `N` to navigate.
* `fx` go to next occurrence of the letter `x` on **the line**. Then use `;` to find the next or `,` previous occurrence. To do this in reverse or backwards, use `F` instead of `f`.

```
this is the first occurrence of xxxx. Next one is here xxxx.
Another one is here xxxx
xxxx is the last one.
```

* `t,` go to just before the character `,`. Then use `;` and `,` to navigate.

```
this is a sentence, which is for testing, and practicing.
```

* `dt"` (delete till ") to remove everything until `"`. To do this in reverse or backwards, use `T` instead of `t`.
* `di"` deletes inside the quotation marks (works even if cursor is at start of line)
* `ci"` changes inside the quotation marks, then enter insert mode. Also works  with `)`, `}`, and ```.
* `vi"` select inside the quotation marks and `va"` select around the quotation marks.

```
left spacer "This is sentence is between double quotes" right spacer "another"
left spacer (This is sentence is between parenthesises) right spacer (another)
left spacer {This is sentence is between braces} right spacer {another}
left spacer `This is sentence is between braces` right spacer `another`
```

* `guw` make a word lowercase
* `gUw` make a work UPPERCASE

Practice folding.

* `zf` to defind a fold

Start
folding
End

* `zo` to open a fold at the cursor.

Use `r` to make a replacement. This is handy in visual mode, when I want to replace a selection of text with a space.

```
r<space>
```

When using the vim-fugitive plugin `:Gdiffsplit` will show you the previous version in a split window! Use `]c` and `[c` to navigate the changes.

```
:Gdiffsplit
]c        " next change
[c        " previous change
```

`diffsplit` can be used to compare files; open the first file in Vim then:

```
:vert diffsplit otherfile
```

### Diff mode

Neovim (like Vim) has a diff mode (`-d`), which can highlight differences between files side by side.

```console
nvim -d file1 file2
```

This opens both files in split windows with differences highlighted.

If you have already opened Neovim:

1. Open first file:

```vim
:e file1
```

2. Open second file in a vertical split:

```vim
:vert diffsplit file2
```

Useful diff commands:

* `]c` - jump to **next difference**
* `[c` - jump to **previous difference**
* `do` - "diff obtain" (apply change from other file)
* `dp` - "diff put" (apply change to other file)
* `:diffupdate` - re-scan and update highlighting
* `:diffoff!` - turn off diff mode

### Buffers

If you quit, this will exit Vim entirely, instead of just closing a specific buffer; use `:bd`.

| Task                                        | Command                      |
| ------------------------------------------- | ---------------------------- |
| List open buffers                           | `:ls` or `:buffers`          |
| Switch to another buffer                    | `:b <buffer number or name>` |
| Toggle between current and last used buffer | `Ctrl+^`                     |
| Open buffer in vertical split               | `:vsp <filename>`            |
| Open buffer in horizontal split             | `:sp <filename>`             |
| Delete buffer (keep window)                 | `:bd` or `:bdelete`          |

### Motions

When editing Markdown files, these are some very handy motions.

* Use `<CTRL> F` and `<CTRL> B` to scroll forward and backward a whole screen
* Use `H`, `M`, and `L` to move to the top, middle, and bottom of the current visible page.
* `(` / `)` - Jump backward/forward a sentence.
* `{` / `}` - Jump backward/forward a paragraph.
* `[[` / `]]` - Jump to the start of the previous/next function but works for headers in Markdown.

### Find and till

[Find and till tips](https://vim.fandom.com/wiki/Tutorial#Find_and_till).

* Find will jump to a character in the same line:
    * `fx` to find the next `x` in the line and `Fx` to find the previous one.

* Till is similar:
    * `tx` to jump till just before the next `x` in the line, and `Tx` to jump
    till just after the previous one.

* Use `,` and `;` to jump to the previous and next occurrence of the character
  found with `t`, `T`, `f`, or `F`.

In the above, `x` is any character, including Tab (press f then Tab to jump to
the next Tab on the current line).

Magic happens when you combine the motions find and till with operators:

* `ctx` change all text till the next 'x' (x is any character; x is not changed).
* `cfx` same, but include the 'x'.
* `dtx` delete all text till the next 'x'.
* `dfx` same, but include the 'x'.

### Argument list

The argument list is just a list of files you tell Vim you want to work on. You can start Vim with a list of files:

```console
nvim *.yml
```

Then use `:args` in Vim to see the files.

Use `:next` or `:n` to navigate to the next file in the list and `:prev` or `:N` to the previous file. You will have to save each change individually as you move between files.

### Quickfix list

The quickfix list is a special buffer in Vim that stores file positions (filename + line + column) and not just the files, like in an argument list. It was originally designed to hold compiler errors, but you can also fill it with search results.

One task I regularly perform is updating the version of the GitHub action [checkout](https://github.com/actions/checkout). Using the quickfix list is handy because I can quickly create a list of files and locations of where I need to make the changes.

1. Open Nvim
2. Inside Nvim, populate the Quickfix List with `:grep`

```vim
:grep checkout **/*.yml
```

3. Open the list with `:copen` and work through each file!
4. Use `:cnext` or `:cn` to jump to the next match and `:cprev` or `:cp` to jump to the previous match!
5. Make the change in the match and save; keep going until you're done!

### Global command (:g)

`:g/pattern/cmd` runs an Ex command on **every line matching** `pattern`;
`:v/pattern/cmd` (short for `:g!`) runs it on every line that does **not** match.
The default command is `p` (print), so `:g/TODO` on its own just lists the
matching lines.

Common uses:

* `:g/^$/d` - delete every blank line.
* `:g/DEBUG/d` - delete every line containing `DEBUG`.
* `:v/error/d` - keep only the lines containing `error` (delete the rest).
* `:g/pattern/normal A;` - run a normal-mode edit on each match (here, append a
  `;`). This is where `:g` and `:norm` combine.
* `:g/pattern/m$` - move every matching line to the end of the file (`m0` sends
  them to the top, reversing their order); use `t$` to copy instead of move.

Practice: delete the blank lines (`:g/^$/d`), gather the `error` lines at the
bottom (`:g/error/m$`), then keep only them (`:v/error/d`).

```
apple
banana

error: disk full
cherry

error: out of memory
date
```

### Repeatable change with cgn

`cgn` changes the **next match** of the last search pattern and drops you into
insert mode; after the first change, `.` repeats it on the following match. It's
a more surgical, reviewable version of `:%s//new/g` - you `.` the matches you
want and press `n` to skip the ones you don't.

```
*        " search for the word under the cursor (also jumps to the next match)
cgn      " change the next match; type the replacement, then <Esc>
.        " repeat the change on the next match
n        " skip a match you want to leave unchanged
```

`*` jumps forward to the *next* match, so the first `cgn` lands on the second
occurrence; press `N` right after `*` to step back onto the word you started on
if you want to change it too. `gn` on its own is a text object over the next
match, so `dgn` deletes it and `ygn` yanks it (`gN` targets the previous match).

Practice: turn every `count` into `n` - put the cursor on `count`, press `*N`,
then `cgn` `n` `<Esc>`, and `.` through the rest.

```
count = count + 1
print(count)
total = count * 2
reset(count)
```

### Registers

A register is just a **named clipboard slot**. You address one by typing `"`
followed by its single-character name *before* a yank/delete/paste, so `"ayy`
yanks the current line into register `a` and `"ap` pastes it back. In insert or
command-line mode you pull a register in with `<C-r>` + its name (`<C-r>a`). Run
`:reg` (or `:registers`) any time to see every register and its contents; `:reg
a 0 +` shows just those.

The way to remember them is that they fall into a few families:

| Register | What it holds |
| -------- | ------------- |
| `"` (unnamed) | The default. **Every** yank, delete, and change lands here, and a bare `p`/`P` reads it. |
| `"0` (yank) | The last **yank** *only* - deletes never touch it. So after deleting a pile of text, `"0p` still pastes what you last yanked. |
| `"1`-`"9` | A ring of recent **deletes/changes** of a line or more. `"1` is newest; each new big delete pushes `"1`->`"2`->... |
| `"-` (small delete) | Deletes/changes of **less than a line** (e.g. `x`, `diw`). |
| `"a`-`"z` (named) | Yours to fill. `"ay` **overwrites** register `a`; uppercase `"Ay` **appends** to it. |
| `"_` (black hole) | Discards. `"_dd` deletes a line **without** clobbering the unnamed register. |
| `"+` / `"*` (clipboard) | System clipboard / primary selection. `"+y` copies, `"+p` pastes (OSC 52 wires this over SSH here). |
| `"%` `"#` | Current file name / alternate (`<C-^>`) file name. Read-only. |
| `".` `":` `"/` | Last **inserted** text / last **`:` command** / last **search**. Read-only. |
| `"=` (expression) | Evaluates an expression: in insert mode `<C-r>=5*8<CR>` types `40`. |

**Grammar** - the same verbs you already use, with a `"{reg}` prefix:

```
"ayiw     " yank the inner word into register a
"add      " delete this line into register a
"ap       " paste register a after the cursor ("aP before)
<C-r>a    " (insert mode) type register a's contents inline
```

Practice - **the yank register survives deletes**. Yank `KEEP` (`yy` on it),
delete the two junk lines with `dd`, then paste what you yanked with `"0p` (a
plain `p` would paste the last *deleted* line instead):

```
KEEP
junk one
junk two
```

Practice - **collect lines with uppercase append**. Start register `a` fresh on
the first keeper with `"ayy`, then add each later keeper with `"Ayy`; finally
`"ap` dumps them together somewhere else:

```
alpha
skip me
bravo
skip me
charlie
```

Idioms worth burning in:

* `"_dd` - delete into the black hole so the text in `"` / `"0` is preserved
  (delete the line you're replacing *without* overwriting your yank).
* `"1p` then `.` - paste your last big delete; each `.` moves on to `"2`, `"3`,
  ... (use `u.` to page through them one at a time and stop on the right one).
* `cw<C-r>0` - change a word and drop your last yank in over it; because it's one
  change it repeats with `.` (the repeatable "replace with the yanked word" idea).
* `<C-r><C-w>` on the `:` or `/` line - pull the word under the cursor onto the
  command line, e.g. `:%s/<C-r><C-w>/new/g`.
* Registers **are** macros: a macro recorded with `qa` lives in `"a` (so `:reg a`
  shows it, `qaq` clears it), and you can yank edited text back into `"a` to fix
  a macro.
