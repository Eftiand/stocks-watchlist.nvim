local config = require("trading.config")
local data = require("trading.data")
local fmt = require("trading.format")

local M = {}

local ns = vim.api.nvim_create_namespace("trading_watchlist")
local LOADING = "loading" -- sentinel in state.quotes while a fetch is in flight

local state = {
  buf = nil,
  win = nil,
  quotes = {}, -- canonical spec -> quote | {err = "..."} | LOADING
  timer = nil, -- debounce for buffer edits
  saved = nil, -- last JSON written, to skip no-op saves
}

local store_path = vim.fn.stdpath("data") .. "/trading-nvim/watchlist.json"

local function load_symbols()
  local list = config.options.watchlist
  local f = io.open(store_path, "r")
  if f then
    local ok, decoded = pcall(vim.json.decode, f:read("*a"))
    f:close()
    if ok and type(decoded) == "table" and #decoded > 0 then
      list = decoded
    end
  end
  -- canonicalize (also migrates old provider-prefixed entries)
  return vim.tbl_map(data.canonical, list)
end

local function save_symbols(symbols)
  local encoded = vim.json.encode(symbols)
  if encoded == state.saved then
    return
  end
  vim.fn.mkdir(vim.fs.dirname(store_path), "p")
  local f = assert(io.open(store_path, "w"))
  f:write(encoded)
  f:close()
  state.saved = encoded
end

local function buf_valid()
  return state.buf and vim.api.nvim_buf_is_valid(state.buf)
end

local function win_valid()
  return state.win and vim.api.nvim_win_is_valid(state.win)
end

---Non-empty buffer lines as {lnum (0-based), spec} pairs, plus the
---deduped spec list — the single place buffer text becomes symbols.
local function parse_buffer()
  local rows, seen, symbols = {}, {}, {}
  for i, line in ipairs(vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)) do
    local s = vim.trim(line)
    if s ~= "" then
      local spec = data.canonical(s)
      rows[#rows + 1] = { lnum = i - 1, spec = spec }
      if not seen[spec] then
        seen[spec] = true
        symbols[#symbols + 1] = spec
      end
    end
  end
  return rows, symbols
end

---Quotes as right-aligned virtual text, one extmark per non-empty line.
local function update_marks(rows)
  if not buf_valid() then
    return
  end
  vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  for _, row in ipairs(rows) do
    local q = state.quotes[row.spec]
    local virt
    if not q or q == LOADING then
      virt = { { "…", "Comment" } }
    elseif q.err then
      virt = { { "✗ no data", "ErrorMsg" } }
    else
      local hl = q.change >= 0 and "TradingUp" or "TradingDown"
      virt = { { fmt.quote(q.price, q.pct), hl } }
      if q.ext then
        local ehl = q.ext.change >= 0 and "TradingUp" or "TradingDown"
        table.insert(virt, { "  " .. q.session .. " ", "Comment" })
        table.insert(virt, { fmt.quote(q.ext.price, q.ext.pct), ehl })
      end
    end
    table.insert(virt, { " ", "Normal" }) -- breathing room at the edge
    vim.api.nvim_buf_set_extmark(state.buf, ns, row.lnum, 0, {
      virt_text = virt,
      virt_text_pos = "right_align",
    })
  end
end

local function fetch_quote(spec)
  if state.quotes[spec] == LOADING then
    return
  end
  state.quotes[spec] = LOADING
  data.quote(spec, function(err, quote)
    vim.schedule(function()
      state.quotes[spec] = err and { err = err } or quote
      if buf_valid() then
        update_marks((parse_buffer()))
      end
    end)
  end)
end

---Persist the buffer contents and fetch quotes for new symbols.
local function sync()
  if not buf_valid() then
    return
  end
  local rows, symbols = parse_buffer()
  save_symbols(symbols)
  for _, spec in ipairs(symbols) do
    if state.quotes[spec] == nil then
      fetch_quote(spec)
    end
  end
  update_marks(rows)
end

local function debounced_sync()
  state.timer:stop()
  state.timer:start(500, 0, vim.schedule_wrap(sync))
end

function M.refresh()
  if not buf_valid() then
    return
  end
  state.quotes = {}
  local rows, symbols = parse_buffer()
  for _, spec in ipairs(symbols) do
    fetch_quote(spec)
  end
  update_marks(rows)
end

function M.close()
  if win_valid() then
    pcall(vim.api.nvim_win_close, state.win, true)
  end
end

function M.open()
  if win_valid() then
    vim.api.nvim_set_current_win(state.win)
    M.refresh()
    return
  end

  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, load_symbols())
  vim.bo[state.buf].bufhidden = "wipe"
  vim.bo[state.buf].filetype = "trading-watchlist"

  state.win = vim.api.nvim_open_win(state.buf, true, {
    split = "right",
    win = -1, -- full-height rightmost split
    width = config.options.watchlist_width,
  })
  vim.wo[state.win].winfixwidth = true
  vim.wo[state.win].cursorline = true
  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].signcolumn = "no"
  vim.wo[state.win].wrap = false
  vim.wo[state.win].statuscolumn = ""
  vim.wo[state.win].winbar = " Watchlist"

  local km = config.options.keymaps
  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = state.buf, nowait = true, silent = true })
  end
  map(km.quit, M.close)
  map(km.refresh, M.refresh)
  map(km.open, function()
    local s = vim.trim(vim.api.nvim_get_current_line())
    if s ~= "" then
      require("trading.ui.chart").open(data.canonical(s))
    end
  end)

  -- the list IS the buffer: dd/o/p and typing edit it, changes autosave
  state.timer = vim.uv.new_timer()
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = state.buf,
    callback = debounced_sync,
  })
  -- single teardown path, whether closed via `q` or :q
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(state.win),
    once = true,
    callback = function()
      state.timer:stop()
      state.timer:close()
      state.timer = nil
      if buf_valid() then
        local _, symbols = parse_buffer()
        save_symbols(symbols)
      end
      state.win, state.buf = nil, nil
    end,
  })

  M.refresh()
end

function M.toggle()
  if win_valid() then
    M.close()
  else
    M.open()
  end
end

return M
