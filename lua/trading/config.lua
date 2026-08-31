local M = {}

M.defaults = {
  -- provider used when a symbol has no "provider:" prefix
  default_provider = "yahoo",
  default_interval = "1d",
  -- intervals cycled with ]/[ in the chart window
  intervals = { "1m", "5m", "15m", "1h", "4h", "1d", "1wk" },
  -- initial watchlist; edited via the popup, persisted to disk
  watchlist = { "AAPL", "MSFT", "binance:BTCUSDT" },
  -- width of the right-hand watchlist sidebar
  watchlist_width = 42,
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
