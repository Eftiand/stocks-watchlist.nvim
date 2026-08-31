local M = {}

function M.setup(opts)
  require("trading.config").setup(opts)
end

function M.watchlist()
  require("trading.ui.watchlist").toggle()
end

return M
