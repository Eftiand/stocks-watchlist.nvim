local M = {}

M.defaults = {
  default_interval = "1d",
  -- intervals cycled with ]/[ in the chart window
  intervals = { "1m", "5m", "15m", "1h", "1d", "1wk" },
  -- initial watchlist; edited in the sidebar, persisted to disk
  watchlist = { "AAPL", "MSFT", "BTC-USD" },
  -- width of the right-hand watchlist sidebar
  watchlist_width = 42,
  -- seconds between automatic quote refreshes while the sidebar is open (0 disables)
  watchlist_refresh = 30,
  chart = {
    width = 0.9, -- fraction of editor size
    height = 0.85,
    border = "rounded",
  },
  keymaps = {
    quit = "q",
    refresh = "r",
    next_interval = "]",
    prev_interval = "[",
    -- watchlist only
    open = "<CR>",
  },
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
