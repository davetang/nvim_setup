## Miscellaneous

Files for practicing the Neovim setup.

* [aerc.md](aerc.md) - short guide to installing the aerc terminal email client
  with `apt` and composing mail in Neovim.

### scan_large_files.py

A practice script for editing, reading with CodeCompanion, and documenting
yourself. It recursively scans a directory for files at or above a size
threshold and prints each file's size, modified time, and path. Standard library
only; deliberately shipped with **no comments or docstrings** so there's
something left to document.

Run it:

```
./scan_large_files.py ~/somedir -s 10M -S newest -H -n 20
```

Options:

| Flag | Meaning |
| ---- | ------- |
| `path` | directory to scan (default `.`) |
| `-s`, `--min-size` | only report files this size or larger; accepts `500K`, `10M`, `2G`, or bare bytes (default `1M`) |
| `-S`, `--sort` | order by `size`, `oldest`, `newest`, `name`, or `path` (default `size`) |
| `-n`, `--top` | show only the first N results after sorting |
| `-H`, `--human` | human-readable sizes (e.g. `2.0M`) |
| `-a`, `--hidden` | include hidden files and directories |
| `-r`, `--reverse` | reverse the chosen sort order |
| `-L`, `--follow-symlinks` | follow symbolic links |
| `-d`, `--max-depth` | do not descend more than this many levels below the start dir |
| `-x`, `--exclude` | glob of names to skip; repeatable, e.g. `-x '*.log'` |
| `-c`, `--total` | print an `N files, TOTAL` summary to stderr |

**Spots worth investigating** (with CodeCompanion or by editing):

* `parse_size` - how the unit suffix is peeled off and turned into bytes.
* `build_parser` - the `default="1M"` subtlety: argparse runs a *string* default
  through `type=parse_size`, so the default arrives as an int (1048576), not the
  literal string `"1M"`.
* `walk` - the depth arithmetic and the in-place `dirs[:] = [...]` pruning (why
  mutating in place matters for `os.walk`).
* `sort_results` - the `reverse=not reverse` trick that makes `size`/`newest`
  default to descending while `oldest` defaults to ascending.
* `--max-depth` semantics: `-d 0` is top-level only, `-d 1` also includes one
  level of subdirectories - which differs from `find -maxdepth`, so it's a good
  thing to pin down and document (or change to match `find`).

**CodeCompanion practice:** open a chat with `<leader>cc` and ask, e.g.,
"explain what `parse_size` does line by line"; or visually select a function and
`<leader>ca` to drop it into the chat before asking. `<leader>ci` runs the inline
assistant if you want it to draft docstrings you then edit.

### scan_large_files.annotated.py

The fully-annotated "answer key" - the same code with a module docstring,
docstrings on every function, inline comments on the tricky bits, and argparse
help text. Its behaviour is byte-for-byte identical to `scan_large_files.py`, so
any diff between the two is purely documentation.

Document your own copy first, then compare against the key with the diff
workflow from `practice.md`:

```
nvim -d scan_large_files.py scan_large_files.annotated.py
```

or, already inside nvim on your copy, `:vert diffsplit scan_large_files.annotated.py`
and walk the differences with `]c` / `[c`. Don't peek at the key until you've
written your own docs, or it defeats the practice.
