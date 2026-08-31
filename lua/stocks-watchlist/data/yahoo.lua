local M = {}

---GET a URL and decode the JSON body.
local function get_json(url, cb)
  vim.system(
    { "curl", "-fsSL", "--max-time", "10", "-H", "User-Agent: Mozilla/5.0", url },
    { text = true },
    function(out)
      if out.code ~= 0 then
        return cb(("yahoo fetch failed (curl exit %d)"):format(out.code))
      end
      local ok, json = pcall(vim.json.decode, out.stdout)
      if not ok or type(json) ~= "table" then
        return cb("yahoo returned invalid JSON")
      end
      cb(nil, json)
    end
  )
end

---Latest quote incl. pre/post-market when the session is extended.
---@param symbol string
---@param cb fun(err: string|nil, quote: table|nil)
function M.quote(symbol, cb)
  local url = ("https://query1.finance.yahoo.com/v8/finance/chart/%s?interval=1m&range=1d&includePrePost=true")
    :format(vim.uri_encode(symbol))
  get_json(url, function(err, json)
    if err then
      return cb(err .. " for " .. symbol)
    end
    local result = vim.tbl_get(json, "chart", "result", 1)
    if not result then
      local desc = vim.tbl_get(json, "chart", "error", "description")
      return cb(("yahoo: %s"):format(desc or ("no data for " .. symbol)))
    end
    local meta = result.meta or {}
    local reg = meta.regularMarketPrice
    local prev = meta.previousClose or meta.chartPreviousClose
    if type(reg) ~= "number" or type(prev) ~= "number" then
      return cb("yahoo: no quote for " .. symbol)
    end
    local q = {
      price = reg,
      change = reg - prev,
      pct = prev ~= 0 and (reg - prev) / prev * 100 or 0,
    }
    -- last traded price (candles include pre/post); flag extended sessions
    local ts = result.timestamp or {}
    local closes = vim.tbl_get(result, "indicators", "quote", 1, "close") or {}
    local last_t, last_c
    for i = #closes, 1, -1 do
      if closes[i] ~= nil and closes[i] ~= vim.NIL then
        last_t, last_c = ts[i], closes[i]
        break
      end
    end
    local regular = vim.tbl_get(meta, "currentTradingPeriod", "regular")
    if last_t and last_c and regular then
      local session
      if last_t < regular.start then
        session = "pre"
      elseif last_t >= regular["end"] then
        session = "post"
      end
      if session then
        q.session = session
        q.ext = {
          price = last_c,
          change = last_c - reg,
          pct = reg ~= 0 and (last_c - reg) / reg * 100 or 0,
        }
      end
    end
    cb(nil, q)
  end)
end

return M
