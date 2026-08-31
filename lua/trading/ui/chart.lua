local config = require("trading.config")
local data = require("trading.data")
local fmt = require("trading.format")
local candles_render = require("trading.render.candles")

local M = {}

local ns = vim.api.nvim_create_namespace("trading_chart")

local state = {
  buf = nil,
  win = nil,
  spec = nil,
  interval = nil,
  candles = nil, -- last fetched data, redrawn on resize without refetching
}

local function win_valid()
  return state.win and vim.api.nvim_win_is_valid(state.win)
end

local function set_lines(lines, highlights)
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    return
  end
  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  for _, h in ipairs(highlights or {}) do
    vim.api.nvim_buf_set_extmark(state.buf, ns, h.line, h.s, {
      end_col = h.e,
      hl_group = h.hl,
    })
  end
end

local function show_loading()
  set_lines({ " loading " .. data.canonical(state.spec) .. " · " .. state.interval .. " ..." }, {})
end

local function draw()
  if not (win_valid() and state.candles) then
    return
  end
  local candles = state.candles
  local w = vim.api.nvim_win_get_width(state.win)
  local h = vim.api.nvim_win_get_height(state.win)
  local chart_h = math.max(8, h - 6) -- header, blank, axis, labels, blank, help

  local last = candles[#candles]
  local prev = candles[#candles - 1] or last
  local change = last.c - prev.c
  local pct = prev.c ~= 0 and (change / prev.c * 100) or 0
  local arrow = change >= 0 and "▲" or "▼"
  local header = string.format(
    " %s · %s    " .. fmt.price_fmt(last.c) .. "  %s %+.2f (%+.2f%%)",
    data.canonical(state.spec),
    state.interval,
    last.c,
    arrow,
    change,
    pct
  )

  local lines, highlights = candles_render.render(candles, w, chart_h, state.interval)
  local km = config.options.keymaps
  local help = string.format(
    " %s quit · %s refresh · %s/%s interval",
    km.quit,
    km.refresh,
    km.prev_interval,
    km.next_interval
  )

  local all = { header, "" }
  local offset = #all
  for _, l in ipairs(lines) do
    all[#all + 1] = l
  end
  all[#all + 1] = ""
  all[#all + 1] = help

  for _, hl in ipairs(highlights) do
    hl.line = hl.line + offset
  end
  local change_hl = change >= 0 and "TradingUp" or "TradingDown"
  local arrow_at = header:find(arrow, 1, true)
  table.insert(highlights, { line = 0, s = arrow_at - 1, e = #header, hl = change_hl })
  table.insert(highlights, { line = 0, s = 0, e = arrow_at - 1, hl = "Title" })
  table.insert(highlights, { line = #all - 1, s = 0, e = #help, hl = "Comment" })

  set_lines(all, highlights)
end

function M.refresh()
  if not state.spec then
    return
  end
  local spec, interval = state.spec, state.interval
  data.fetch(spec, interval, function(err, candles)
    vim.schedule(function()
      -- ignore stale responses after the user switched symbol/interval
      if state.spec ~= spec or state.interval ~= interval then
        return
      end
      if err then
        vim.notify("[trading.nvim] " .. err, vim.log.levels.ERROR)
        return
      end
      state.candles = candles
      draw()
    end)
  end)
end

function M.close()
  if win_valid() then
    pcall(vim.api.nvim_win_close, state.win, true)
  end
end

local function cycle(dir)
  state.interval = data.cycle_interval(state.interval, dir)
  state.candles = nil
  show_loading()
  M.refresh()
end

local function create_window()
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].bufhidden = "wipe"
  vim.bo[state.buf].filetype = "trading-chart"

  local opts = config.options.chart
  local width = math.floor(vim.o.columns * opts.width)
  local height = math.floor(vim.o.lines * opts.height)
  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = opts.border,
    title = " trading.nvim ",
    title_pos = "center",
  })
  vim.wo[state.win].wrap = false
  vim.wo[state.win].cursorline = false

  local km = config.options.keymaps
  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = state.buf, nowait = true, silent = true })
  end
  map(km.quit, M.close)
  map(km.refresh, M.refresh)
  map(km.next_interval, function()
    cycle(1)
  end)
  map(km.prev_interval, function()
    cycle(-1)
  end)

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(state.win),
    once = true,
    callback = function()
      state.win, state.buf, state.candles = nil, nil, nil
    end,
  })
  vim.api.nvim_create_autocmd("VimResized", {
    buffer = state.buf,
    callback = draw, -- layout only; the data hasn't changed
  })
end

---@param spec string symbol, optionally "provider:SYMBOL"
---@param interval string|nil
function M.open(spec, interval)
  state.spec = spec
  state.interval = interval or config.options.default_interval
  -- snap to a supported interval
  if not data.supports(state.interval) then
    state.interval = data.cycle_interval(state.interval, 1)
  end
  state.candles = nil
  if not win_valid() then
    create_window()
  end
  show_loading()
  M.refresh()
end

return M
