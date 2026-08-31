if vim.g.loaded_trading_nvim then
  return
end
vim.g.loaded_trading_nvim = true

local function set_hl()
  vim.api.nvim_set_hl(0, "TradingUp", { fg = "#26a69a", default = true })
  vim.api.nvim_set_hl(0, "TradingDown", { fg = "#ef5350", default = true })
end
set_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })

vim.api.nvim_create_user_command("TradingWatchlist", function()
  require("trading").watchlist()
end, { desc = "Toggle the watchlist sidebar" })
