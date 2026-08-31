# trading.nvim

Candlestick charts and a live watchlist inside Neovim. Pure Lua, no dependencies beyond `curl`. Requires Neovim 0.10+.

```
 yahoo:AAPL · 1d    319.70  ▲ +5.12 (+1.63%)
 344.57┤                                    │ │
       │                                  │ ╂ ╂
 332.77┤                      ┃ ╂ ┃     ┃ │     ╂
       │                    │ ┃ │ ┃ │ │ ┃       │
 320.96┤                │   ┃     │ ┃ │ ┃
       │              │ ╂   ┃         │
 309.16┤      │ ┃ │ ┃ ╂ │ ╂             ┃ │
       └┬───────────┬───────────┬───────────┬───
        17 Jun      02 Jul      17 Jul      31 Jul
```

> Note: data comes from Yahoo Finance's public chart endpoint (stocks, ETFs, indices, forex, crypto) — TradingView itself has no public data API. No API keys needed; the endpoint is unofficial and subject to change.

## Install

lazy.nvim:

```lua
{
  "kristianjeremic/trading-nvim",
  cmd = { "TradingView", "TradingWatchlist" },
  opts = {},
}
```

## Usage

| Command | Action |
|---|---|
| `:TradingView AAPL` | Open a chart (default interval) |
| `:TradingView BTC-USD 1h` | Crypto chart, hourly candles |
| `:TradingWatchlist` | Toggle the watchlist sidebar (right split) |

Symbols are Yahoo Finance tickers: `AAPL`, `BTC-USD`, `EURUSD=X`, `^GSPC`.

### Chart keymaps

- `q` close · `r` refresh · `]` / `[` cycle interval

### Watchlist sidebar

The sidebar **is** the list: one symbol per editable line, quotes shown as right-aligned virtual text. `dd` to delete, `o`/paste to add, reorder freely — changes autosave to `stdpath("data")/trading-nvim/watchlist.json` (blank lines and duplicates dropped). During extended hours a `pre`/`post` quote is shown next to the regular one. Quotes auto-refresh every `watchlist_refresh` seconds (default 30) while the sidebar is open.

- `<CR>` open chart for symbol under cursor
- `r` refresh quotes · `q` close

## Configuration

Defaults:

```lua
require("trading").setup({
  default_interval = "1d",
  intervals = { "1m", "5m", "15m", "1h", "1d", "1wk" },
  watchlist = { "AAPL", "MSFT", "BTC-USD" }, -- seed; edited list persists to disk
  watchlist_width = 42, -- sidebar width
  watchlist_refresh = 30, -- seconds between quote refreshes while open (0 disables)
  chart = {
    width = 0.9,   -- fraction of editor width
    height = 0.85, -- fraction of editor height
    border = "rounded",
  },
  keymaps = {
    quit = "q",
    refresh = "r",
    next_interval = "]",
    prev_interval = "[",
    open = "<CR>",  -- watchlist
  },
})
```

Colors: `TradingUp` (`#26a69a`) and `TradingDown` (`#ef5350`) highlight groups, override with `vim.api.nvim_set_hl`.

