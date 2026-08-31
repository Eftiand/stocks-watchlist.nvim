# trading.nvim

A live stock/crypto watchlist sidebar for Neovim. Pure Lua, no dependencies beyond `curl`. Requires Neovim 0.10+.

```
│ Watchlist
│ AAPL      319.70 +1.63%  pre 318.60 -0.34%
│ MSFT      513.53 +1.68%  pre 509.00 -0.88%
│ BTC-USD                       78311 +0.79%
│ NVDA      217.55 -4.57%  pre 219.02 +0.68%
```

> Note: data comes from Yahoo Finance's public chart endpoint (stocks, ETFs, indices, forex, crypto) — no API keys needed; the endpoint is unofficial and subject to change.

## Install

lazy.nvim:

```lua
{
  "Eftiand/trading-nvim",
  cmd = "TradingWatchlist",
  keys = {
    { "<leader>wl", "<cmd>TradingWatchlist<cr>", desc = "Toggle watchlist" },
  },
  opts = {},
}
```

## Usage

`:TradingWatchlist` toggles the sidebar (right split).

The sidebar **is** the list: one symbol per editable line, quotes shown as right-aligned virtual text. `dd` to delete, `o`/paste to add, reorder freely — changes autosave to `stdpath("data")/trading-nvim/watchlist.json` (blank lines and duplicates dropped). Symbols are Yahoo Finance tickers: `AAPL`, `BTC-USD`, `EURUSD=X`, `^GSPC`.

Quotes auto-refresh every `watchlist_refresh` seconds while the sidebar is open. During extended hours a `pre`/`post` quote is shown next to the regular one.

Keymaps: `r` refresh now · `q` close.

## Configuration

Defaults:

```lua
require("trading").setup({
  watchlist = { "AAPL", "MSFT", "BTC-USD" }, -- seed; edited list persists to disk
  watchlist_width = 42, -- sidebar width
  watchlist_refresh = 30, -- seconds between quote refreshes while open (0 disables)
  keymaps = {
    quit = "q",
    refresh = "r",
  },
})
```

Colors: `TradingUp` (`#26a69a`) and `TradingDown` (`#ef5350`) highlight groups, override with `vim.api.nvim_set_hl`.
