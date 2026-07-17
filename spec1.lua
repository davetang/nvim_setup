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

  {
    'nvim-telescope/telescope.nvim', tag = '0.1.8',
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
  -- Folding is enabled for headers by default.
  -- `zR`: opens all folds
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

  {
    "R-nvim/R.nvim",
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
