-- This file should be in ~/.config/nvim/lua/plugins
-- run `:Lazy sync` after making changes to sync to latest changes
return {

  -- https://github.com/nvim-tree/nvim-tree.lua/wiki/Installation#lazy
  -- :NvimTreeToggle Open or close the tree. Takes an optional path argument.
  -- :NvimTreeFocus Open the tree if it is closed, and then focus on the tree.
  -- :NvimTreeFindFile Move the cursor in the tree for the current buffer, opening folders if needed.
  -- :NvimTreeCollapse Collapses the nvim-tree recursively.
  {
     "nvim-tree/nvim-tree.lua",
     version = "*",
     lazy = false,
     dependencies = {
        "nvim-tree/nvim-web-devicons",
     },
     config = function()
        require("nvim-tree").setup {}
     end,
  },

  -- https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#installation
  {
    "nvim-treesitter/nvim-treesitter",
    branch = 'main',
    lazy = false,
    build = ":TSUpdate"
  },

  -- https://github.com/folke/which-key.nvim?tab=readme-ov-file#-installation
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },

  -- Track master, not the 0.1.8 tag: 0.1.8's preview highlighter calls
  -- vim.treesitter.language.ft_to_lang, removed in Neovim 0.12 (crashes
  -- <leader>ff). master uses the current builtin get_lang. The 0.1.x branch
  -- instead routes through nvim-treesitter's parsers module, which our
  -- treesitter-on-`main` setup doesn't expose the old way - so master it is.
  {
    'nvim-telescope/telescope.nvim', branch = 'master',
    dependencies = { 'nvim-lua/plenary.nvim' }
  },

  {
    "tpope/vim-sensible"
  },

  {
    "neovim/nvim-lspconfig"
  },

  {
    "junegunn/vim-easy-align"
  },

  -- Vim script for text filtering and alignment
  {
    "godlygeek/tabular"
  },

  -- You can clean trailing whitespace with :FixWhitespace.
  {
    "bronson/vim-trailing-whitespace"
  },

  {
    "airblade/vim-gitgutter"
  },

  -- use the plugin in the on-the-fly mode use
  -- :TableModeToggle
  -- mapped to <Leader>tm by default (which means `\tm`)
  { "dhruvasagar/vim-table-mode" },

  -- https://github.com/maxmx03/solarized.nvim
  -- Modern Lua Solarized: true 24-bit colour, treesitter- and LSP-aware.
  -- Requires termguicolors (init.lua sets it) and a require('solarized').setup()
  -- call (also in init.lua). Loaded eagerly with a high priority so its
  -- highlights load before other UI plugins. nvim-treesitter (declared above) is
  -- its one dependency and is already installed.
  {
    "maxmx03/solarized.nvim",
    lazy = false,
    priority = 1000,
  },

  -- https://github.com/preservim/vim-markdown
  -- Folds by header. Files open with every fold open (foldlevelstart in
  -- init.lua): `zM` closes all folds, `zR` opens them, `za` toggles one.
  { "preservim/vim-markdown" },

  -- https://github.com/iamcco/markdown-preview.nvim
  -- :MarkdownPreview / :MarkdownPreviewStop to toggle a browser preview.
  -- Uses the yarn-based build recommended by the plugin README. `npx --yes
  -- yarn install` avoids needing yarn installed globally (requires node.js).
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && npx --yes yarn install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
  },

  -- https://github.com/MeanderingProgrammer/render-markdown.nvim
  -- Renders Markdown *in the buffer* (headings, fenced code, tables, checkboxes,
  -- callouts) with treesitter - a quick in-place look without the browser-based
  -- markdown-preview. Auto-renders in normal mode; the raw markup reappears on
  -- the line you're editing. The markdown/markdown_inline parsers (already
  -- installed) do the parsing and nvim-web-devicons (already present via
  -- nvim-tree) supplies code-block language icons. Loads on markdown files only.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown" },
    opts = {},
  },

  -- https://github.com/R-nvim/R.nvim
  -- Run R in a terminal split and send code to it (<LocalLeader>rf starts R;
  -- see :Cheatsheet and :RMapsDesc). Works with no setup() call. The first
  -- time you open an R file it compiles its R package nvimcom (needs make and
  -- a C compiler), and it starts its own language server, so completion needs
  -- no extra plugin. Run r_setup.sh (make r) once for the R packages it renders
  -- and formats with. `:checkhealth r` reports what is missing.
  {
    "R-nvim/R.nvim",
  },

  -- https://github.com/Vigemus/iron.nvim
  -- A Python console beside your script, used like R.nvim: init.lua gives
  -- Python buffers the same local-leader keys (\rf starts it, \d sends the
  -- line, \pp the paragraph, \cc the `# %%` cell; see :Cheatsheet). Runs
  -- IPython when the project's environment has it (start nvim with `uv run
  -- nvim`, or from an activated venv), otherwise plain python3. Loads the
  -- first time one of those keys is used.
  {
    "Vigemus/iron.nvim",
    lazy = true,
    cmd = { "IronRepl", "IronRestart", "IronFocus", "IronHide" },
    config = function()
      require("iron.core").setup({
        config = {
          scratch_repl = true,
          repl_definition = {
            python = {
              command = function()
                if vim.fn.executable("ipython") == 1 then
                  -- No "really exit?" prompt, so \rq quits at once.
                  return { "ipython", "--no-autoindent", "--no-confirm-exit" }
                end
                return { "python3" }
              end,
              format = require("iron.fts.common").bracketed_paste_python,
              block_dividers = { "# %%", "#%%" },
              -- Python 3.13+'s new console mangles pasted code; use the old one.
              -- PAGER=cat prints help() into the console instead of opening a
              -- pager you would have to move into the console to quit.
              env = { PYTHON_BASIC_REPL = "1", PAGER = "cat" },
            },
          },
          -- Console on the right, like R.nvim's.
          repl_open_cmd = require("iron.view").split.vertical.botright(0.4),
        },
        -- Don't send the blank lines inside a selection: plain python3 takes a
        -- blank line as the end of a block (e.g. midway through a function).
        ignore_blank_lines = true,
      })
    end,
  },

  -- https://github.com/tpope/vim-fugitive
  {
    "tpope/vim-fugitive"
  },

  -- https://github.com/olimorris/codecompanion.nvim
  -- Ask about code from inside Neovim, backed by a local Ollama server. The
  -- built-in `ollama` adapter reads $OLLAMA_HOST (falling back to
  -- http://localhost:11434) and offers whatever models that server has, so the
  -- only thing to configure is pointing the strategies at it - no URL, key, or
  -- model to hard-code. Loaded on demand via its commands; the keymaps
  -- (<leader>cc / <leader>ca) live in init.lua. See :Cheatsheet.
  {
    "olimorris/codecompanion.nvim",
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      strategies = {
        chat = { adapter = "ollama" },
        inline = { adapter = "ollama" },
      },
      -- Pin the default model. Note $OLLAMA_MODEL is NOT a standard Ollama
      -- variable (Ollama defines OLLAMA_HOST and OLLAMA_MODELS - the latter is
      -- the model *storage directory*, not a selector); it's just a name this
      -- config reads. The model must already be pulled on the server; switch it
      -- live in the chat with `ga`.
      adapters = {
        http = {
          ollama = function()
            return require("codecompanion.adapters").extend("ollama", {
              schema = {
                model = {
                  default = os.getenv("OLLAMA_MODEL") or "qwen2.5-coder:7b",
                },
              },
            })
          end,
        },
      },
    },
  }

}
