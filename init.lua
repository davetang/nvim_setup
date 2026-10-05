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

-- open files with every fold open. vim-markdown folds Markdown by heading but
-- leaves 'foldlevel' at 0, which closed every heading on open; the folds are
-- still there for zc / za / zM. (Diff mode is unaffected: it resets the level.)
vim.opt.foldlevelstart = 99

-- Solarized (dark) via maxmx03/solarized.nvim - a modern Lua theme that needs
-- true 24-bit colour. termguicolors is on unconditionally now that every
-- workstation runs a truecolor-capable terminal and GNU screen 5.x (4.x
-- down-samples to 256; see the README colour note - terminal_setup's `make
-- screen` builds 5.x locally). Set before the scheme loads; pcall so a fresh
-- install (before the plugin exists) doesn't error.
vim.opt.termguicolors = true
vim.opt.background = 'dark'
pcall(function()
  require('solarized').setup({})
  vim.cmd.colorscheme('solarized')
end)

-- Yank to the clipboard of the machine you're sitting at over SSH via OSC 52
-- (use "+y): the terminal there receives the text as an escape sequence.
local osc52 = require('vim.ui.clipboard.osc52')
-- Inside GNU screen ($STY), OSC 52 is dropped, so do what sendcb does: send
-- it in 76-character pieces, each wrapped in ESC P ... ESC \, which screen
-- passes to the outer terminal (one long piece would be dropped). sendcb
-- itself can't be run from here: since 0.10, the Nvim process that runs
-- external commands has no /dev/tty. nvim_ui_send writes through the UI
-- process, which owns the terminal.
local function screen_copy(clipboard)
  return function(lines)
    local data = vim.base64.encode(table.concat(lines, '\n'))
    local parts = { '\027P\027]52;' .. clipboard .. ';\027\\' }
    for i = 1, #data, 76 do
      parts[#parts + 1] = '\027P' .. data:sub(i, i + 75) .. '\027\\'
    end
    parts[#parts + 1] = '\027P\007\027\\'
    vim.api.nvim_ui_send(table.concat(parts))
  end
end
-- Terminals refuse or ignore clipboard reads (screen drops them, so "+p used to
-- wait 10 s and give up), so "+p pastes Neovim's own last yank. Paste from
-- your own machine with the terminal's paste key in insert mode.
local function paste()
  return { vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('') }
end
vim.g.clipboard = {
  name = 'OSC 52',
  copy = vim.env.STY and { ['+'] = screen_copy('c'), ['*'] = screen_copy('p') }
    or { ['+'] = osc52.copy('+'), ['*'] = osc52.copy('*') },
  paste = { ['+'] = paste, ['*'] = paste },
}
-- With g:clipboard set above, Nvim's own OSC 52 detection (`:h g:termfeatures`)
-- has nothing to decide, so turn it off. Its fallback query (XTGETTCAP for
-- "Ms") is wrapped in ESC P ... ESC \, which GNU screen takes as "pass this to
-- the outer terminal" - so the terminal printed "+q4D73" at the top of the
-- screen on every start inside screen.
vim.g.termfeatures = vim.tbl_extend('force', vim.g.termfeatures or {}, { osc52 = false })

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

-- R gets three language servers, split the way Python's are. R.nvim starts
-- its own (`r_ls`: completion, hover, go-to-definition, rename) when you open
-- an R file - nothing to configure here, and the LspAttach autocmd below turns
-- on its completion like any other server's. It neither formats nor lints, so:
--   air  - Posit's R formatter (the R counterpart of ruff format), so
--          <leader>f formats R files. https://github.com/posit-dev/air
--   jarl - a fast R linter (the R counterpart of ruff check): diagnostics plus
--          quick-fix code actions. It lints when you save (:w), not as you
--          type or on open. https://github.com/etiennebacher/jarl
-- Both are single binaries installed into ~/bin by terminal_setup.
vim.lsp.config.air = {
  cmd = { my_home .. '/bin/air', 'language-server' },
  filetypes = { 'r' },
  root_dir = lsp_root_dir
}
vim.lsp.enable 'air'

vim.lsp.config.jarl = {
  cmd = { my_home .. '/bin/jarl', 'server' },
  filetypes = { 'r', 'rmd' },
  root_dir = lsp_root_dir
}
vim.lsp.enable 'jarl'

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

-- PerlNavigator: Perl language server (syntax check via `perl -c`, plus
-- completion, hover, and code navigation). Installed via npm as
-- perlnavigator-server, which drops a `perlnavigator` binary. It also picks up
-- perlcritic (lint) and perltidy (format) if they are on PATH - those are
-- optional CPAN modules the bundle does not install; see perl_navigator.sh.
vim.lsp.config.perlnavigator = {
  cmd = { my_home .. '/lib/bin/perlnavigator', '--stdio' },
  filetypes = { 'perl' },
  root_dir = lsp_root_dir,
}
vim.lsp.enable 'perlnavigator'

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
--
-- autotrigger only fires on the server's own triggerCharacters - `.`, `$`,
-- `(` and the like, never letters - so on its own, typing a name such as `pri`
-- opens nothing, and the buffer-word fallback below stands aside wherever a
-- server completes. Add the letters and `_` to each server's list first (it is
-- read when completion is enabled), as :help lsp-autocompletion suggests, so
-- the menu opens as you type names. Digits and punctuation are left out so
-- numbers and operators don't pop a menu; while the menu is open, typing just
-- narrows it.
local identifier_chars = vim.split('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_', '')
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local provider = client and client.server_capabilities.completionProvider
    if provider then
      local triggers = provider.triggerCharacters or {}
      for _, c in ipairs(identifier_chars) do
        if not vim.tbl_contains(triggers, c) then table.insert(triggers, c) end
      end
      provider.triggerCharacters = triggers
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
-- <C-n> when there is a word character before the cursor and no menu is open
-- (or <C-x><C-f> when you are typing a file path, in every filetype);
-- completeopt=noselect (above) keeps it from inserting anything on its own.
vim.api.nvim_create_autocmd('TextChangedI', {
  callback = function()
    if vim.bo.buftype ~= '' then return end     -- skip prompt/special buffers
    if vim.fn.pumvisible() == 1 then return end  -- a menu is already open
    local mode = vim.fn.complete_info({ 'mode' }).mode
    -- File paths: when the text before the cursor is a path into a directory
    -- that exists (/data/s, ~/proj/, ./R/, $HOME/), list that directory with
    -- <C-x><C-f>, as coc.nvim's file source used to. This comes before the LSP
    -- check below so it works in Python and shell files too: the LSP
    -- autotrigger holds back while a menu is open. It also runs while another
    -- completion is active, because a language server's reply can land after
    -- the file menu opens and replace it; this brings the file menu back on
    -- the next keystroke. Relative paths resolve against the current
    -- directory, as <C-x><C-f> does; URLs are skipped.
    local before = vim.fn.getline('.'):sub(1, vim.fn.col('.') - 1)
    local path = before:match('[%w%._%-~$/]*/[%w%._%-]*$')
    if path and mode ~= 'files' and not path:find('//', 1, true)
        and vim.fn.isdirectory(vim.fn.expand(path:match('^(.*/)'))) == 1 then
      vim.api.nvim_feedkeys(vim.keycode('<C-x><C-f>'), 'n', false)
      return
    end
    -- Typing a character that matches nothing closes the menu but leaves the
    -- completion running. Firing <C-n> (or <C-x><C-f>) then finds nothing,
    -- which fires TextChangedI again, and so on in a loop that never lets the
    -- screen redraw - what you type stays hidden until <Esc>. So stand aside
    -- until that completion ends (a space or other non-word character ends
    -- it). For paths, that is the mode ~= 'files' test above.
    if mode ~= '' then return end
    -- If an attached LSP already provides completion (e.g. Python, bash), let
    -- its autotrigger own the menu. Firing keyword <C-n> here too makes two
    -- sources fight over the single builtin menu, which resets the completion
    -- leader and swallows what you're typing. Markdown has no LSP client, so
    -- this loop finds nothing and the <C-n> below still runs there as before.
    for _, c in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
      if c.server_capabilities.completionProvider then return end
    end
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
-- Diagnostics: show the message inline (virtual text) at the end of the line,
-- so you can read an error/warning without moving onto it and opening the
-- float. `source = 'if_many'` appends which server flagged it when a line has
-- diagnostics from more than one (e.g. pyright vs ruff). severity_sort puts
-- errors above warnings; update_in_insert off keeps it from flickering as you
-- type. <leader>d still opens the full float; ]d / [d jump between them.
vim.diagnostic.config({
  virtual_text = { source = 'if_many' },
  severity_sort = true,
  update_in_insert = false,
})
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
  -- R.nvim also wants csv (to view data frames and matrices) and latex (with
  -- rnoweb, for Rnoweb documents); yaml and markdown cover Rmd and Quarto.
  ts.install({
    "r", "rnoweb", "python", "bash", "groovy", "make", "perl", "sql", "yaml",
    "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline",
    "csv", "latex",
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
-- Toggle in-buffer Markdown rendering (render-markdown.nvim). Files open as
-- raw markup (enabled = false in spec1.lua); this turns rendering on for a
-- formatted look, and off again.
vim.keymap.set('n', '<leader>mr', '<cmd>RenderMarkdown toggle<cr>', { desc = 'Toggle in-buffer Markdown render' })

-- CodeCompanion: ask about code without leaving Neovim, backed by Ollama. The
-- built-in ollama adapter talks to $OLLAMA_HOST (else http://localhost:11434),
-- so make sure Ollama is running/reachable there. <leader>cc toggles a chat
-- window to ask anything; in visual mode <leader>ca sends the highlighted code
-- into a chat so you can ask about it. :CodeCompanionActions lists more prompts.
vim.keymap.set({ 'n', 'v' }, '<leader>cc', '<cmd>CodeCompanionChat Toggle<cr>', { desc = 'CodeCompanion chat (toggle)' })
vim.keymap.set('v', '<leader>ca', '<cmd>CodeCompanionChat Add<cr>', { desc = 'CodeCompanion: add selection to chat' })
-- Inline assistant: write/edit code in place (you accept or reject its diff).
-- Leaves ':CodeCompanion ' on the command line for you to type the instruction,
-- then press <CR>. No trailing <cr> here on purpose. In visual mode the '<,'>
-- range is inserted automatically, so it targets the selection.
vim.keymap.set({ 'n', 'v' }, '<leader>ci', ':CodeCompanion ', { desc = 'CodeCompanion inline prompt' })

-- Python console (iron.nvim, in spec1.lua) on the same local-leader keys
-- R.nvim uses for R, so one set of habits works in both languages: \rf starts
-- the console on the right, then send code to it a line, paragraph,
-- selection or `# %%` cell at a time. Sending also starts the console if it
-- isn't running. Buffer-local, so R.nvim's keys in R files are untouched.
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'python',
  callback = function(args)
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = desc })
    end
    local function iron() return require('iron.core') end
    -- send `fn(<expression under the cursor>)`, e.g. help(np.mean)
    local function call_on_cursor(fn)
      return function() iron().send('python', fn .. '(' .. vim.fn.expand('<cexpr>') .. ')') end
    end
    map('n', '<LocalLeader>rf', function() iron().repl_for('python') end, 'Start the Python console')
    map('n', '<LocalLeader>rq', function() iron().close_repl('python') end, 'Quit the Python console')
    map('n', '<LocalLeader>l', function() iron().send_line() end, 'Send the line')
    map('n', '<LocalLeader>d', function()
      iron().send_line()
      vim.fn.search([[^\s*\S]], 'W')  -- next non-blank line
    end, 'Send the line and move down')
    map('x', '<LocalLeader>ss', function() iron().visual_send() end, 'Send the selection')
    map('n', '<LocalLeader>pp', function() iron().send_paragraph() end, 'Send the paragraph')
    map('n', '<LocalLeader>aa', function() iron().send_file('python') end, 'Send the whole file')
    map('n', '<LocalLeader>cc', function() iron().send_code_block(false) end, 'Send the # %% cell')
    map('n', '<LocalLeader>cd', function() iron().send_code_block(true) end, 'Send the # %% cell and move to the next')
    map('n', '<LocalLeader>rh', call_on_cursor('help'), 'help() on the object under the cursor')
    map('n', '<LocalLeader>rp', call_on_cursor('print'), 'print() the object under the cursor')
  end,
})

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

-- custom :Python command
vim.api.nvim_create_user_command(
  'Python',
  function()
    vim.cmd('vsplit ~/.config/nvim/python.md')
  end,
  { desc = 'Python cheatsheet (for R/Perl users)' }
)
