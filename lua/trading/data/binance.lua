local http = require("trading.data.http")

local M = {}

M.name = "binance"

M.intervals = {
  ["1m"] = "1m",
  ["5m"] = "5m",
  ["15m"] = "15m",
  ["1h"] = "1h",
  ["4h"] = "4h",
  ["1d"] = "1d",
  ["1wk"] = "1w",
}

local function get(url, symbol, cb, on_json)
  http.get_json(url, "binance", function(err, json)
    if err then
      return cb(err .. " for " .. symbol)
    end
    if json.msg then
      return cb("binance: " .. json.msg)
    end
    on_json(json)
  end)
end

---Crypto trades 24/7 — no pre/post sessions.
---@param symbol string
---@param cb fun(err: string|nil, quote: table|nil)
function M.quote(symbol, cb)
  local url = ("https://api.binance.com/api/v3/ticker/24hr?symbol=%s"):format(symbol:upper())
  get(url, symbol, cb, function(json)
    cb(nil, {
      price = tonumber(json.lastPrice),
      change = tonumber(json.priceChange),
      pct = tonumber(json.priceChangePercent),
    })
  end)
end

---@param symbol string e.g. BTCUSDT
---@param interval string
---@param cb fun(err: string|nil, candles: table|nil)
function M.fetch(symbol, interval, cb)
  local iv = M.intervals[interval]
  if not iv then
    return cb(("binance does not support interval %s"):format(interval))
  end
  local url = ("https://api.binance.com/api/v3/klines?symbol=%s&interval=%s&limit=200")
    :format(symbol:upper(), iv)
  get(url, symbol, cb, function(json)
    local candles = {}
    for _, k in ipairs(json) do
      candles[#candles + 1] = {
        t = math.floor(k[1] / 1000),
        o = tonumber(k[2]),
        h = tonumber(k[3]),
        l = tonumber(k[4]),
        c = tonumber(k[5]),
        v = tonumber(k[6]),
      }
    end
    if #candles == 0 then
      return cb("binance: no candles for " .. symbol)
    end
    cb(nil, candles)
  end)
end

return M
