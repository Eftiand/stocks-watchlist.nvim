if vim.g.loaded_stocks_watchlist_nvim then
  return
end
vim.g.loaded_stocks_watchlist_nvim = true

local function set_hl()
  vim.api.nvim_set_hl(0, "StocksUp", { fg = "#26a69a", default = true })
  vim.api.nvim_set_hl(0, "StocksDown", { fg = "#ef5350", default = true })
end
set_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })

vim.api.nvim_create_user_command("StocksWatchlist", function()
  require("stocks-watchlist").watchlist()
end, { desc = "Toggle the watchlist sidebar" })
