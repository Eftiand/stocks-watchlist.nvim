local M = {}

---GET a URL and decode the JSON body.
---@param url string
---@param label string provider name used in error messages
---@param cb fun(err: string|nil, json: table|nil)
function M.get_json(url, label, cb)
  vim.system(
    { "curl", "-fsSL", "--max-time", "10", "-H", "User-Agent: Mozilla/5.0", url },
    { text = true },
    function(out)
      if out.code ~= 0 then
        return cb(("%s fetch failed (curl exit %d)"):format(label, out.code))
      end
      local ok, json = pcall(vim.json.decode, out.stdout)
      if not ok or type(json) ~= "table" then
        return cb(label .. " returned invalid JSON")
      end
      cb(nil, json)
    end
  )
end

return M
