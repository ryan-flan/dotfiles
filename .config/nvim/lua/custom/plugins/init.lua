return {
  'roobert/activate.nvim',
  keys = {
    {
      '<leader>P',
      '<CMD>lua require("activate").list_plugins()<CR>',
      desc = 'Plugins',
    },
  },
  dependencies = {
    { 'nvim-telescope/telescope.nvim', branch = '0.1.x', dependencies = { 'nvim-lua/plenary.nvim' } },
  },
  {
    'rolv-apneseth/tfm.nvim',
    config = function()
      -- Set keymap so you can open the default terminal file manager (yazi)
      vim.api.nvim_set_keymap('n', '<leader>e', '', {
        noremap = true,
        callback = require('tfm').open,
      })
    end,
  },
}
