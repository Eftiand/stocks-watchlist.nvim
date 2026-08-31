local M = {}

function M.setup(opts)
  require("trading.config").setup(opts)
end

---@param spec string symbol, optionally "provider:SYMBOL"
---@param interval string|nil
function M.chart(spec, interval)
  require("trading.ui.chart").open(spec, interval)
end

function M.watchlist()
  require("trading.ui.watchlist").toggle()
end

return M
