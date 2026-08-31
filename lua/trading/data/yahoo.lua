local http = require("trading.data.http")

local M = {}

M.name = "yahoo"

-- our interval name -> yahoo interval + range that yields enough candles
M.intervals = {
  ["1m"] = { i = "1m", range = "5d" },
  ["5m"] = { i = "5m", range = "5d" },
  ["15m"] = { i = "15m", range = "1mo" },
  ["1h"] = { i = "60m", range = "3mo" },
  ["1d"] = { i = "1d", range = "1y" },
  ["1wk"] = { i = "1wk", range = "5y" },
}

local function chart_result(json, symbol)
  local result = vim.tbl_get(json, "chart", "result", 1)
  if result then
    return result
  end
  local desc = vim.tbl_get(json, "chart", "error", "description")
  return nil, ("yahoo: %s"):format(desc or ("no data for " .. symbol))
end

---Latest quote incl. pre/post-market when the session is extended.
---@param symbol string
---@param cb fun(err: string|nil, quote: table|nil)
function M.quote(symbol, cb)
  local url = ("https://query1.finance.yahoo.com/v8/finance/chart/%s?interval=1m&range=1d&includePrePost=true")
    :format(vim.uri_encode(symbol))
  http.get_json(url, "yahoo", function(err, json)
    if err then
      return cb(err .. " for " .. symbol)
    end
    local result, rerr = chart_result(json, symbol)
    if not result then
      return cb(rerr)
    end
    local meta = result.meta or {}
    local reg = meta.regularMarketPrice
    local prev = meta.previousClose or meta.chartPreviousClose
    if type(reg) ~= "number" or type(prev) ~= "number" then
      return cb("yahoo: no quote for " .. symbol)
    end
    local q = {
      price = reg,
      change = reg - prev,
      pct = prev ~= 0 and (reg - prev) / prev * 100 or 0,
    }
    -- last traded price (candles include pre/post); flag extended sessions
    local ts = result.timestamp or {}
    local closes = vim.tbl_get(result, "indicators", "quote", 1, "close") or {}
    local last_t, last_c
    for i = #closes, 1, -1 do
      if closes[i] ~= nil and closes[i] ~= vim.NIL then
        last_t, last_c = ts[i], closes[i]
        break
      end
    end
    local regular = vim.tbl_get(meta, "currentTradingPeriod", "regular")
    if last_t and last_c and regular then
      local session
      if last_t < regular.start then
        session = "pre"
      elseif last_t >= regular["end"] then
        session = "post"
      end
      if session then
        q.session = session
        q.ext = {
          price = last_c,
          change = last_c - reg,
          pct = reg ~= 0 and (last_c - reg) / reg * 100 or 0,
        }
      end
    end
    cb(nil, q)
  end)
end

---@param symbol string
---@param interval string
---@param cb fun(err: string|nil, candles: table|nil)
function M.fetch(symbol, interval, cb)
  local spec = M.intervals[interval]
  if not spec then
    return cb(("yahoo does not support interval %s"):format(interval))
  end
  -- intraday charts include pre/post-market candles
  local prepost = (spec.i:match("m$") ~= nil) and "&includePrePost=true" or ""
  local url = ("https://query1.finance.yahoo.com/v8/finance/chart/%s?interval=%s&range=%s%s")
    :format(vim.uri_encode(symbol), spec.i, spec.range, prepost)
  http.get_json(url, "yahoo", function(err, json)
    if err then
      return cb(err .. " for " .. symbol)
    end
    local result, rerr = chart_result(json, symbol)
    if not result then
      return cb(rerr)
    end
    local ts = result.timestamp or {}
    local q = vim.tbl_get(result, "indicators", "quote", 1) or {}
    local candles = {}
    for i, t in ipairs(ts) do
      local o, h, l, c = q.open and q.open[i], q.high and q.high[i], q.low and q.low[i], q.close and q.close[i]
      -- yahoo pads gaps with nulls
      if o ~= nil and o ~= vim.NIL and h ~= vim.NIL and l ~= vim.NIL and c ~= vim.NIL then
        candles[#candles + 1] = {
          t = t,
          o = o,
          h = h,
          l = l,
          c = c,
          v = (q.volume and q.volume[i] ~= vim.NIL) and q.volume[i] or 0,
        }
      end
    end
    if #candles == 0 then
      return cb("yahoo: no candles for " .. symbol)
    end
    cb(nil, candles)
  end)
end

return M
