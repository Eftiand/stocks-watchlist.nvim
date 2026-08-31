local M = {}

M.defaults = {
  -- initial watchlist; edited in the sidebar, persisted to disk
  watchlist = { "AAPL", "MSFT", "BTC-USD" },
  -- width of the right-hand sidebar
  watchlist_width = 42,
  -- seconds between automatic quote refreshes while the sidebar is open (0 disables)
  watchlist_refresh = 30,
  keymaps = {
    quit = "q",
    refresh = "r",
  },
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
