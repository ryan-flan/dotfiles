-- Global variable to store last window position
if _G.preview_last_position == nil then
  _G.preview_last_position = {
    row = nil,
    col = nil,
    used_once = false,
  }
end

-- Function to preview definition in a floating window
local function preview_definition()
  -- Get the LSP location of the definition
  local params = vim.lsp.util.make_position_params()

  vim.lsp.buf_request(0, 'textDocument/definition', params, function(err, result, ctx, config)
    if err or not result or vim.tbl_isempty(result) then
      vim.notify('No definition found', vim.log.levels.WARN)
      return
    end

    -- Handle both single result and multiple results
    local target = result
    if vim.tbl_islist(result) then
      target = result[1]
    end

    -- Extract the target location info
    local uri = target.uri or target.targetUri
    local range = target.range or target.targetRange

    if not uri or not range then
      vim.notify('Invalid definition data', vim.log.levels.WARN)
      return
    end

    -- Convert URI to file path
    local filepath = vim.uri_to_fname(uri)

    -- Create a buffer for the preview
    local buf = vim.api.nvim_create_buf(false, true)

    -- Read the file content
    local lines = vim.fn.readfile(filepath)
    if not lines or #lines == 0 then
      vim.notify('Failed to read definition file', vim.log.levels.ERROR)
      return
    end

    -- Set buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Set buffer filetype based on filepath extension
    local filetype = vim.fn.fnamemodify(filepath, ':e')
    vim.api.nvim_buf_set_option(buf, 'filetype', filetype)

    -- Calculate window dimensions - make it narrower
    -- Make sure these are integer values by using math.floor
    local width = math.floor(math.min(vim.o.columns - 4, math.max(60, vim.o.columns * 0.4)))
    local height = math.floor(math.min(vim.o.lines - 4, math.max(15, vim.o.lines * 0.5)))

    -- Position the floating window
    local row, col

    -- Use saved position if it exists
    if _G.preview_last_position.used_once and _G.preview_last_position.row ~= nil then
      row = _G.preview_last_position.row
      col = _G.preview_last_position.col

      -- Verify the saved position is still valid (screen could have been resized)
      if row + height > vim.o.lines then
        row = vim.o.lines - height - 2
      end
      if row < 0 then
        row = 0
      end
      if col + width > vim.o.columns then
        col = vim.o.columns - width - 2
      end
      if col < 0 then
        col = 0
      end
    else
      -- First time or reset position - calculate position based on cursor
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      local cursor_line = cursor_pos[1]
      local cursor_col = cursor_pos[2]

      -- Get current window position
      local win_pos = vim.api.nvim_win_get_position(0)
      local win_row = win_pos[1]
      local win_col = win_pos[2]

      -- Calculate initial position (near cursor)
      row = math.floor(win_row + cursor_line - math.floor(height / 3))
      col = math.floor(win_col + cursor_col + 5)

      -- Adjust if it would go off screen
      if row + height > vim.o.lines then
        row = math.floor(vim.o.lines - height - 2)
      end
      if row < 0 then
        row = 0
      end
      if col + width > vim.o.columns then
        col = math.floor(vim.o.columns - width - 2)
      end
      if col < 0 then
        col = 0
      end

      -- Mark that we've displayed the window at least once
      _G.preview_last_position.used_once = true
    end

    -- Create window config with border
    local win_config = {
      relative = 'editor',
      width = width,
      height = height,
      col = col,
      row = row,
      style = 'minimal',
      border = 'rounded',
      title = ' Definition Preview ',
      title_pos = 'center',
    }

    -- Create the floating window
    local win = vim.api.nvim_open_win(buf, true, win_config)

    -- Set cursor at the definition position
    vim.api.nvim_win_set_cursor(win, { range.start.line + 1, range.start.character })

    -- Center the view on the definition
    vim.cmd 'normal! zz'

    -- Function to move the window
    local function move_window(dx, dy)
      local current_config = vim.api.nvim_win_get_config(win)

      -- Handle row and col correctly based on their type
      local new_row, new_col

      -- Check if row is a table or a direct number
      if type(current_config.row) == 'table' and current_config.row[false] ~= nil then
        -- Older Neovim versions use table format
        new_row = math.floor(current_config.row[false] + dy)
        new_col = math.floor(current_config.col[false] + dx)
      else
        -- Newer Neovim versions use direct number
        new_row = math.floor(current_config.row + dy)
        new_col = math.floor(current_config.col + dx)
      end

      -- Keep window within screen bounds
      if new_row < 0 then
        new_row = 0
      end
      if new_row + height > vim.o.lines then
        new_row = vim.o.lines - height - 1
      end
      if new_col < 0 then
        new_col = 0
      end
      if new_col + width > vim.o.columns then
        new_col = vim.o.columns - width - 1
      end

      -- Save the new position for next time
      _G.preview_last_position.row = new_row
      _G.preview_last_position.col = new_col

      -- Create a new config with updated values
      local updated_config = {
        relative = 'editor',
        width = width,
        height = height,
        row = new_row,
        col = new_col,
        style = 'minimal',
        border = 'rounded',
      }

      vim.api.nvim_win_set_config(win, updated_config)
    end

    -- Save initial position
    if _G.preview_last_position.row == nil then
      _G.preview_last_position.row = row
      _G.preview_last_position.col = col
    end

    -- Add keybindings to close or open the file
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':q<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':q<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', string.format([[:q<CR>:e %s<CR>:%d<CR>]], filepath, range.start.line + 1), { noremap = true, silent = true })

    -- Add keybinding to reset position
    vim.api.nvim_buf_set_keymap(buf, 'n', '<C-r>', '', {
      noremap = true,
      silent = true,
      callback = function()
        _G.preview_last_position.row = nil
        _G.preview_last_position.col = nil
        _G.preview_last_position.used_once = false
        vim.notify('Preview position reset', vim.log.levels.INFO)
      end,
    })

    -- Add keybindings to move the window with arrow keys instead of Ctrl+hjkl
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Left>', '', {
      noremap = true,
      silent = true,
      callback = function()
        move_window(-5, 0)
      end,
    })
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Down>', '', {
      noremap = true,
      silent = true,
      callback = function()
        move_window(0, 5)
      end,
    })
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Up>', '', {
      noremap = true,
      silent = true,
      callback = function()
        move_window(0, -5)
      end,
    })
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Right>', '', {
      noremap = true,
      silent = true,
      callback = function()
        move_window(5, 0)
      end,
    })

    -- Enable syntax highlighting
    vim.api.nvim_buf_set_option(buf, 'syntax', filetype)

    -- Set buffer local options
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

    -- Add an autocommand to ensure the window is closed properly
    vim.api.nvim_create_autocmd({ 'BufLeave' }, {
      buffer = buf,
      once = true,
      callback = function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end,
    })
  end)
end

return preview_definition
