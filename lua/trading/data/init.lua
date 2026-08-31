local config = require("trading.config")
local yahoo = require("trading.data.yahoo")

local M = {}

---Display/persistence form of a symbol.
---@param spec string
---@return string
function M.canonical(spec)
  return vim.trim(spec):upper()
end

---@param spec string
---@param interval string
---@param cb fun(err: string|nil, candles: table|nil)
function M.fetch(spec, interval, cb)
  yahoo.fetch(M.canonical(spec), interval, cb)
end

---Latest quote incl. pre/post-market when the session is extended.
---@param spec string
---@param cb fun(err: string|nil, quote: table|nil)
function M.quote(spec, cb)
  yahoo.quote(M.canonical(spec), cb)
end

---@param interval string
---@return boolean
function M.supports(interval)
  return yahoo.intervals[interval] ~= nil
end

---Next/previous supported interval from the configured list.
---@param current string
---@param dir integer 1 or -1
---@return string
function M.cycle_interval(current, dir)
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
    if M.supports(list[idx]) then
      return list[idx]
    end
  end
  return current
end

return M
