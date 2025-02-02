local M = {}

function M.open_code_peek()
  local params = vim.lsp.util.make_position_params()

  local results = vim.lsp.buf_request_sync(0, 'textDocument/definition', params, 1000)
  if not results or vim.tbl_isempty(results) then
    print("Definition not found")
    return
  end

  local client_results = nil
  for _, res in pairs(results) do
    if res.result then
      client_results = res.result
      break
    end
  end

  if not client_results or vim.tbl_isempty(client_results) then
    print("Definition not found")
    return
  end

  local location = vim.tbl_islist(client_results) and client_results[1] or client_results

  local uri = location.uri or location.targetUri
  local range = location.range or location.targetRange

  local filename = vim.uri_to_fname(uri)
  local start_line = range.start.line
  local end_line = range["end"].line

  local lines = vim.fn.readfile(filename)
  if not lines or #lines == 0 then
    print("Unable to load file: " .. filename)
    return
  end

  local context_radius = 20
  local begin_line = math.max(1, start_line + 1 - context_radius)
  local finish_line = math.min(#lines, end_line + 1 + context_radius)

  local buf_lines = {}
  for i = begin_line, finish_line do
    table.insert(buf_lines, lines[i])
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, buf_lines)

  -- Try to detect filetype based on the filename.
  local ft = vim.filetype.match({ filename = filename })
  -- Infer filetype from the extension
  if not ft then
    local ext = filename:match("^.+(%..+)$")
    if ext then
      ft = ext:sub(2)
    end
  end
  if ft then
    vim.api.nvim_buf_set_option(buf, 'filetype', ft)
  end

  -- Calculate the dimensions of the floating window.
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local opts = {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
  }

  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Jump to the definition line relative to the buffer’s contents.
  local cursor_line = start_line + 1 - begin_line + 1
  vim.api.nvim_win_set_cursor(win, { cursor_line, 0 })

  -- Close on leave
  vim.cmd(string.format(
    "autocmd BufLeave <buffer=%d> ++once lua vim.api.nvim_win_close(%d, true)",
    buf, win
  ))

  -- Close with q
  vim.api.nvim_buf_set_keymap(buf, "n", "q",
    "<cmd>close<CR>",
    { noremap = true, silent = true }
  )
end

function M.setup()
  vim.api.nvim_create_user_command("CodePeek", function()
    M.open_code_peek()
  end, { desc = "Peek at code definition under cursor" })
end

return M
