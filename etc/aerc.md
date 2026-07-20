# aerc + Neovim

[aerc](https://aerc-mail.org/) is a modern terminal email client that composes
mail in your `$EDITOR`, which makes it pair naturally with Neovim.

## Install (apt)

On Debian 12+ / recent Ubuntu (universe):

```sh
sudo apt install aerc        # add w3m for HTML mail: sudo apt install aerc w3m
```

If your release predates aerc's packaging, enable `bookworm-backports` or fall
back to the conda-forge build (`conda install -c conda-forge aerc`).

## First run

Just launch it:

```sh
aerc
```

The first time, aerc runs an add-account wizard and writes three files to
`~/.config/aerc/`:

* `accounts.conf` - your IMAP/SMTP accounts
* `aerc.conf` - general settings
* `binds.conf` - keybindings

For Gmail / Google Workspace, use an **app password** (with 2FA enabled) or
OAuth2 rather than your normal password.

## Compose in Neovim

aerc uses `$EDITOR`, so if that is already `nvim` you are done. To pin it
regardless, add to `~/.config/aerc/aerc.conf`:

```ini
[compose]
editor=nvim
```

When you compose or reply, aerc opens the draft in a temp file named like
`ae1234.txt`, which Neovim recognises out of the box as the `mail` filetype -
so you get header and quoted-text highlighting for free. For nicer prose
editing, add a compose autocmd to your `init.lua`:

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "mail",
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.textwidth = 72
  end,
})
```

Write and quit (`:wq`) to hand the message back to aerc, then send it from the
review screen.

## A few default keys

| Key | Action |
| --- | ------ |
| `j` / `k` | next / previous message |
| `<Enter>` | open the selected message |
| `c` | compose a new message |
| `rr` / `Rr` | reply all / reply to sender |
| `a` | archive |
| `D` | delete |
| `<C-n>` / `<C-p>` | next / previous tab (folder or account) |
| `:` | command mode, e.g. `:cf <folder>` to change folder |
| `q` | quit |

The full set lives in `~/.config/aerc/binds.conf`. For more, see `man aerc`,
`man aerc-config`, `man aerc-binds`, and the walkthrough in `man aerc-tutorial`.
