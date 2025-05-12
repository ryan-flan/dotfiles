require('lazy').setup({
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically

  -- NOTE: Plugins can also be added by using a table,
  -- with the first argument being the link and the following
  -- keys can be used to configure plugin behavior/loading/etc.
  --
  -- Use `opts = {}` to force a plugin to be loaded.
  --
  --  This is equivalent to:
  --    require('Comment').setup({})

  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim', opts = {} },

  -- modular approach: using `require 'path/name'` will
  -- include a plugin definition from file lua/path/name.lua

  require 'core/plugins/gitsigns',
  require 'core/plugins/which-key',
  require 'core/plugins/telescope',
  require 'core/plugins/lspconfig',
  require 'core/plugins/conform',
  require 'core/plugins/blink-cmp',
  require 'core/plugins/colorschemes',
  require 'core/plugins/todo-comments',
  require 'core/plugins/mini',
  require 'core/plugins/treesitter',

  { import = 'custom.plugins' },
}, {
  lockfile = vim.fn.stdpath 'data' .. '/lazy-lock.json',
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- vim: ts=2 sts=2 sw=2 et
