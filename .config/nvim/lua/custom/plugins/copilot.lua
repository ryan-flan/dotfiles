return {
  {
    'zbirenbaum/copilot.lua',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup {
        suggestion = {
          enabled = true,
          auto_trigger = false,
          keymap = {
            accept = '<C-l>', -- accept suggestion
            accept_word = false,
            accept_line = false,
            next = '<C-j>', -- next suggestion
            prev = '<C-k>', -- previous suggestion
            dismiss = '<C-]>', -- dismiss suggestion
          },
        },
        panel = { enabled = false },
      }
    end,
  },
  {
    'zbirenbaum/copilot-cmp',
    dependencies = {
      'zbirenbaum/copilot.lua',
      'hrsh7th/nvim-cmp', -- required even if blink wraps it
    },
    config = function()
      require('copilot_cmp').setup()
    end,
  },
}
