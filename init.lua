require("config.lazy")

-- highlight the line currently under cursor
vim.opt.cursorline = true

-- spell checking if you want it
vim.opt.spell = false
vim.opt.spellfile = vim.fn.expand("$HOME/.spellfile.add")

-- set the spelling language
vim.opt.spelllang = { "en_gb" }

-- number of spaces that a <Tab> counts for
vim.opt.tabstop = 2

-- convert tabs to spaces
vim.opt.expandtab = true

-- number of spaces to use for each step of (auto)indent
vim.opt.shiftwidth = 2

-- number of spaces a <Tab> feels like when editing
vim.opt.softtabstop = 2

-- copy indent from current line when starting a new one
vim.opt.autoindent = true

-- smarter autoindenting (for things like C)
vim.opt.smartindent = true

-- show cursor position in status line
vim.opt.ruler = true

-- show line numbers
vim.opt.number = true

-- show relative line numbers
vim.opt.relativenumber = true

-- highlight all search matches
vim.opt.hlsearch = true

-- store more :cmdline history
vim.opt.history = 1000

-- disable the mouse
vim.opt.mouse = ""

-- keep undo history across sessions
vim.opt.undofile = true

-- solarized colorscheme (dark) in 256-colour mode. Truecolor (termguicolors)
-- does not survive through GNU screen here, so we use solarized's 256-colour
-- palette instead - it renders through any terminal/multiplexer. termguicolors
-- and solarized_termcolors must be set before the scheme loads. pcall so a
-- fresh install (before the plugin exists) doesn't error.
vim.opt.termguicolors = false
vim.g.solarized_termcolors = 256
vim.opt.background = 'dark'
pcall(vim.cmd.colorscheme, 'solarized')

-- Yank to the system clipboard over SSH via OSC 52 (use "+y). OSC 52 *paste*
-- needs terminal support and may not work through screen.
local osc52 = require('vim.ui.clipboard.osc52')
vim.g.clipboard = {
  name = 'OSC 52',
  copy = { ['+'] = osc52.copy('+'), ['*'] = osc52.copy('*') },
  paste = { ['+'] = osc52.paste('+'), ['*'] = osc52.paste('*') },
}

-- Syntax highlighting and filetype plugins
vim.cmd('syntax enable')
vim.cmd('filetype plugin indent on')

-- get HOME
local my_home = os.getenv("HOME")  -- or vim.fn.expand("$HOME")

-- Root each language server at the nearest ancestor with a .git dir, falling
-- back to the file's own directory so there is ALWAYS a workspace. bashls in
-- particular needs a workspace to index sibling shell files, so gd can jump to
-- a function defined in another file even when there is no .git (e.g. a loose
-- scripts directory, like this bundle when it isn't inside a repo).
local function lsp_root_dir(bufnr, on_dir)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  on_dir(vim.fs.root(bufnr, { '.git' }) or vim.fs.dirname(fname))
end

-- https://github.com/neovim/nvim-lspconfig/blob/master/lsp/pyright.lua
vim.lsp.config.pyright = {
  cmd = { my_home .. '/lib/bin/pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_dir = lsp_root_dir
}
vim.lsp.enable 'pyright'

-- ruff: fast Python linter + formatter, run as a language server alongside
-- pyright (pyright does types/completion; ruff does linting and formatting,
-- so <leader>f formats via ruff).
vim.lsp.config.ruff = {
  cmd = { my_home .. '/bin/ruff', 'server' },
  filetypes = { 'python' },
  root_dir = lsp_root_dir
}
vim.lsp.enable 'ruff'

vim.lsp.config.bashls = {
  cmd = { my_home .. '/lib/bin/bash-language-server', 'start' },
  filetypes = { 'bash', 'sh' },
  root_dir = lsp_root_dir,
  -- Resolve gd/references to functions defined in *any* shell file in the
  -- workspace, not only files explicitly sourced from the current one
  -- (bashls defaults to sourced-only).
  settings = {
    bashIde = {
      includeAllWorkspaceSymbols = true,
    },
  },
}
vim.lsp.enable 'bashls'

-- Make language server (from the autotools-language-server package).
-- https://autotools-language-server.readthedocs.io/en/latest/index.html
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  pattern = { "Makefile.am", "Makefile" },
  callback = function()
    vim.lsp.start({
      name = "make",
      cmd = { "make-language-server" }
    })
  end,
})

-- Completion menu behaviour: show the menu even for a single match, and don't
-- preselect or insert anything until you pick (keeps autocomplete unobtrusive).
vim.opt.completeopt = { 'menuone', 'noselect' }

-- Native LSP completion (Neovim 0.11+). Enable it per-buffer when a language
-- server that supports completion attaches; autotrigger opens the menu as you
-- type. This replaces coc.nvim.
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.server_capabilities.completionProvider then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end
  end,
})

-- Popup-menu keys: <CR> confirms; <Tab> completes from buffer words (or cycles
-- the menu when it's open); <S-Tab> goes back.
vim.keymap.set('i', '<CR>', function()
  -- confirm only if an item is actually selected; otherwise a normal newline
  if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ 'selected' }).selected ~= -1 then
    return '<C-y>'
  end
  return '<CR>'
end, { expr = true })
vim.keymap.set('i', '<Tab>', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-n>'
  end
  -- Complete from words already in the buffer when there's a word before the
  -- cursor (works even in filetypes with no LSP, like Markdown); else a Tab.
  local line = vim.fn.getline('.')
  local col = vim.fn.col('.') - 1
  if col > 0 and line:sub(col, col):match('%S') then
    return '<C-n>'
  end
  return '<Tab>'
end, { expr = true })
vim.keymap.set('i', '<S-Tab>', function()
  return vim.fn.pumvisible() == 1 and '<C-p>' or '<S-Tab>'
end, { expr = true })

-- Autocomplete: open the buffer-word menu automatically as you type, in any
-- filetype - including ones with no language server (e.g. Markdown). Fires
-- <C-n> when there is a word character before the cursor and no menu is open;
-- completeopt=noselect (above) keeps it from inserting anything on its own.
vim.api.nvim_create_autocmd('TextChangedI', {
  callback = function()
    if vim.bo.buftype ~= '' then return end     -- skip prompt/special buffers
    if vim.fn.pumvisible() == 1 then return end  -- a menu is already open
    local col = vim.fn.col('.') - 1
    if col > 0 and vim.fn.getline('.'):sub(col, col):match('[%w_]') then
      vim.api.nvim_feedkeys(vim.keycode('<C-n>'), 'n', false)
    end
  end,
})

-- Set leader to space
vim.g.mapleader = " "

-- LSP keymap bindings
-- vim.keymap.set({mode}, {lhs}, {rhs}, {opts})
-- mode: "n" = normal, "i" = insert, "v" = visual
-- lhs: the key sequence you press
-- rhs: the command or mapping it triggers
-- opts: (optional) a table of options:
--    desc = "..." -> description (shows up in :map and plugins like which-key)
--    silent = true -> don’t echo command
--    noremap = true -> prevent recursive mapping (default for vim.keymap.set)
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = "Show diagnostic in float" })
vim.keymap.set("n", "<leader>fe", ":Explore<CR>", { desc = "Open file explorer" })
-- Go to definition when you want to jump to where something is defined.
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to Definition' })
vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'Hover Documentation' })
vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { desc = 'Go to Implementation' })
-- rename the symbol under your cursor everywhere it appears.
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename Symbol' })
-- Find references to see where it is used.
vim.keymap.set('n', 'gr', vim.lsp.buf.references, { desc = 'Find References' })
-- format the current buffer
vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format({ async = true }) end, { desc = 'Format' })

-- listing shortcuts here for convenience
-- ]d   " go to next diagnostic (error, warning, hint, info)
-- [d   " go to previous diagnostic

-- nvim-treesitter (main branch, required by Neovim 0.12+). The master-branch
-- `.configs.setup{}` / ensure_installed / highlight API no longer applies; on
-- main you install parsers imperatively and start highlighting per buffer.
-- https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md
-- Guard: install() only exists on the main branch. If nvim-treesitter is
-- missing or still on master (e.g. mid-migration from an old setup), skip it
-- instead of erroring - run `:Lazy sync` to switch to main, then restart.
local ok_ts, ts = pcall(require, 'nvim-treesitter')
if ok_ts and type(ts.install) == 'function' then
  ts.install({
    "r", "rnoweb", "python", "bash", "groovy", "make", "perl", "sql", "yaml",
    "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline",
  })
end

-- Start Treesitter highlighting for any buffer whose filetype has an installed
-- parser. vim.treesitter.start() resolves the language from the filetype, and
-- pcall keeps it quiet for filetypes without a parser (and while parsers are
-- still installing on the first launch - restart once they finish).
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

-- Note: incremental_selection (gnn/grn/grc/grm) was a master-branch module and
-- is not part of the main-branch rewrite, so it has been dropped.

-- https://github.com/nvim-telescope/telescope.nvim?tab=readme-ov-file#usage
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

-- https://github.com/iamcco/markdown-preview.nvim
-- Headless-server friendly: pin the port (forward it via SSH -L), echo the URL
-- on start, and use a no-op browser function so the plugin does not try to
-- launch a browser on the server.
vim.g.mkdp_port = "8090"
vim.g.mkdp_auto_start = 0
vim.g.mkdp_auto_close = 1
vim.g.mkdp_echo_preview_url = 1
vim.cmd([[
  function! MkdpNoopBrowser(url) abort
  endfunction
]])
vim.g.mkdp_browserfunc = "MkdpNoopBrowser"
vim.keymap.set('n', '<leader>mp', '<cmd>MarkdownPreviewToggle<cr>', { desc = 'Markdown preview' })

-- CodeCompanion: ask about code without leaving Neovim, backed by Ollama. The
-- built-in ollama adapter talks to $OLLAMA_HOST (else http://localhost:11434),
-- so make sure Ollama is running/reachable there. <leader>cc toggles a chat
-- window to ask anything; in visual mode <leader>ca sends the highlighted code
-- into a chat so you can ask about it. :CodeCompanionActions lists more prompts.
vim.keymap.set({ 'n', 'v' }, '<leader>cc', '<cmd>CodeCompanionChat Toggle<cr>', { desc = 'CodeCompanion chat (toggle)' })
vim.keymap.set('v', '<leader>ca', '<cmd>CodeCompanionChat Add<cr>', { desc = 'CodeCompanion: add selection to chat' })

-- custom :Practice command
vim.api.nvim_create_user_command(
  'Practice',
  function()
    vim.cmd('vsplit ~/.config/nvim/practice.md')
  end,
  { desc = 'Things to practise' }
)

-- custom :Cheatsheet command
vim.api.nvim_create_user_command(
  'Cheatsheet',
  function()
    vim.cmd('vsplit ~/.config/nvim/cheatsheet.md')
  end,
  { desc = 'LSP and plugin shortcuts' }
)
