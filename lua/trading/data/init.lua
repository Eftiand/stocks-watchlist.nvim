local yahoo = require("trading.data.yahoo")

local M = {}

---Display/persistence form of a symbol.
---@param spec string
---@return string
function M.canonical(spec)
  return vim.trim(spec):upper()
end

---Latest quote incl. pre/post-market when the session is extended.
---@param spec string
---@param cb fun(err: string|nil, quote: table|nil)
function M.quote(spec, cb)
  yahoo.quote(M.canonical(spec), cb)
end

return M
