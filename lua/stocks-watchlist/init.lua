local M = {}

function M.setup(opts)
  require("stocks-watchlist.config").setup(opts)
end

function M.watchlist()
  require("stocks-watchlist.ui.watchlist").toggle()
end

return M
