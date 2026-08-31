local config = require("trading.config")

local M = {}

M.providers = {
  yahoo = require("trading.data.yahoo"),
  binance = require("trading.data.binance"),
}

---Parse "binance:BTCUSDT" / "AAPL" into provider + bare symbol.
---@param spec string
---@return table provider, string symbol
function M.resolve(spec)
  local prefix, rest = spec:match("^(%a+):(.+)$")
  local provider = prefix and M.providers[prefix:lower()]
  if provider then
    return provider, rest
  end
  return M.providers[config.options.default_provider], spec
end

---Does the spec's provider support the interval?
---@param spec string
---@param interval string
---@return boolean
function M.supports(spec, interval)
  local provider = M.resolve(spec)
  return provider.intervals[interval] ~= nil
end

---Display/persistence name: bare symbol for the default provider,
---"provider:SYMBOL" otherwise.
---@param spec string
---@return string
function M.canonical(spec)
  local provider, symbol = M.resolve(spec)
  symbol = symbol:upper()
  if provider.name == config.options.default_provider then
    return symbol
  end
  return provider.name .. ":" .. symbol
end

---@param spec string symbol, optionally provider-prefixed
---@param interval string
---@param cb fun(err: string|nil, candles: table|nil)
function M.fetch(spec, interval, cb)
  local provider, symbol = M.resolve(spec)
  provider.fetch(symbol, interval, cb)
end

---Latest quote (incl. pre/post-market where the provider has sessions).
---@param spec string
---@param cb fun(err: string|nil, quote: table|nil)
function M.quote(spec, cb)
  local provider, symbol = M.resolve(spec)
  provider.quote(symbol, cb)
end

---Next/previous interval supported by the spec's provider.
---@param spec string
---@param current string
---@param dir integer 1 or -1
---@return string
function M.cycle_interval(spec, current, dir)
  local provider = M.resolve(spec)
  local list = config.options.intervals
  local idx = 1
  for i, iv in ipairs(list) do
    if iv == current then
      idx = i
      break
    end
  end
  for _ = 1, #list do
    idx = ((idx - 1 + dir) % #list) + 1
    if provider.intervals[list[idx]] then
      return list[idx]
    end
  end
  return current
end

return M
