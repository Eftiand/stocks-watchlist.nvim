local price_fmt = require("trading.format").price_fmt

local M = {}

local WICK = "│"
local BODY = "┃"
local DOJI = "╂"

---Render candles into text lines + highlight spans.
---@param candles table[] list of {t,o,h,l,c,v}, oldest first
---@param width integer total columns available
---@param height integer rows available for the chart body
---@param interval string used for time-axis label format
---@return string[] lines
---@return table[] highlights {line=0-based, s=byte start, e=byte end, hl=group}
function M.render(candles, width, height, interval)
  -- one column per candle, one gap column between candles
  local fmt = price_fmt(candles[#candles].h)
  local gutter = #string.format(fmt, candles[#candles].h) + 2
  local chart_cols = math.max(10, width - gutter - 1)
  local n = math.min(#candles, math.floor((chart_cols + 1) / 2))
  local shown = vim.list_slice(candles, #candles - n + 1, #candles)

  local hi, lo = -math.huge, math.huge
  for _, c in ipairs(shown) do
    hi = math.max(hi, c.h)
    lo = math.min(lo, c.l)
  end
  if hi == lo then
    hi, lo = hi + 1, lo - 1
  end
  fmt = price_fmt(hi)

  local function row_of(price)
    return math.floor((hi - price) / (hi - lo) * (height - 1) + 0.5) + 1
  end

  -- grid[row][col] = {char, hl} ; col is the candle index (drawn 2 cols apart)
  local grid = {}
  for r = 1, height do
    grid[r] = {}
  end
  for i, c in ipairs(shown) do
    local up = c.c >= c.o
    local hl = up and "TradingUp" or "TradingDown"
    local wick_top, wick_bot = row_of(c.h), row_of(c.l)
    local body_top = row_of(math.max(c.o, c.c))
    local body_bot = row_of(math.min(c.o, c.c))
    for r = wick_top, wick_bot do
      grid[r][i] = { WICK, hl }
    end
    if body_top == body_bot then
      grid[body_top][i] = { DOJI, hl }
    else
      for r = body_top, body_bot do
        grid[r][i] = { BODY, hl }
      end
    end
  end

  -- y-axis label rows, ~6 spread over the height
  local label_every = math.max(1, math.floor(height / 6))
  local lines, highlights = {}, {}

  for r = 1, height do
    local price = hi - (r - 1) / (height - 1) * (hi - lo)
    local gutter_str
    if (r - 1) % label_every == 0 then
      gutter_str = string.format("%" .. (gutter - 1) .. "s", string.format(fmt, price)) .. "┤"
    else
      gutter_str = string.rep(" ", gutter - 1) .. "│"
    end
    local parts, byte = { gutter_str }, #gutter_str
    for i = 1, n do
      local cell = grid[r][i]
      local ch = cell and cell[1] or " "
      parts[#parts + 1] = ch
      if cell then
        highlights[#highlights + 1] = { line = r - 1, s = byte, e = byte + #ch, hl = cell[2] }
      end
      byte = byte + #ch
      if i < n then
        parts[#parts + 1] = " "
        byte = byte + 1
      end
    end
    lines[r] = table.concat(parts)
  end

  -- x axis + time labels
  local tick_every = 10 -- candles between ticks
  local time_fmt = (interval == "1d" or interval == "1wk") and "%d %b" or "%H:%M"
  local axis = { string.rep(" ", gutter - 1) .. "└" }
  local label_cells = {}
  for _ = 1, gutter + n * 2 do
    label_cells[#label_cells + 1] = " "
  end
  for i = 1, n do
    local col = gutter + (i - 1) * 2 -- screen column of candle i (0-based)
    if (i - 1) % tick_every == 0 then
      axis[#axis + 1] = "┬"
      local label = os.date(time_fmt, shown[i].t) --[[@as string]]
      for j = 1, #label do
        if col + j <= #label_cells then
          label_cells[col + j] = label:sub(j, j)
        end
      end
    else
      axis[#axis + 1] = "─"
    end
    if i < n then
      axis[#axis + 1] = "─"
    end
  end
  lines[height + 1] = table.concat(axis)
  lines[height + 2] = table.concat(label_cells):gsub("%s+$", "")

  return lines, highlights
end

return M
