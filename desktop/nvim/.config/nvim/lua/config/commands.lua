local function show_go_doc(opts)
  local target = vim.trim(opts.args)
  if target == "" then
    vim.notify("用法: :Godoc <package[.symbol]>", vim.log.levels.ERROR)
    return
  end

  local started, process = pcall(vim.system, { "go", "doc", target }, { text = true })
  if not started then
    vim.notify("无法执行 go doc: " .. process, vim.log.levels.ERROR)
    return
  end

  local result = process:wait()
  if result.code ~= 0 then
    local detail = vim.trim(result.stderr or "")
    if detail == "" then
      detail = "未找到或无法解析该 symbol"
    end
    vim.notify(string.format("go doc %s 失败: %s", target, detail), vim.log.levels.ERROR)
    return
  end

  local output = result.stdout or ""
  if output == "" then
    vim.notify("go doc " .. target .. " 没有返回文档", vim.log.levels.WARN)
    return
  end

  local lines = vim.split(output, "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = false
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local width = math.max(1, math.floor(vim.o.columns * 0.6))
  local available_height = math.max(1, vim.o.lines - vim.o.cmdheight - 2)
  local height = math.max(1, math.floor(available_height * 0.6))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((available_height - height) / 2)),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    style = "minimal",
    border = "rounded",
    title = " go doc " .. target .. " ",
    title_pos = "center",
  })

  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].breakindent = true

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  vim.keymap.set("n", "q", close, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, silent = true })
end

vim.api.nvim_create_user_command("Godoc", show_go_doc, {
  nargs = "*",
  desc = "Show Go documentation in a floating window",
})
