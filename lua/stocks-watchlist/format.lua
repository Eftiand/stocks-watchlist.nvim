local M = {}

---Pick a price format string from the value's magnitude.
---@param v number
---@return string
function M.price_fmt(v)
  if v >= 10000 then
    return "%.0f"
  elseif v >= 1000 then
    return "%.1f"
  elseif v >= 1 then
    return "%.2f"
  else
    return "%.5f"
  end
end

---"319.70 +1.63%" price-with-change fragment.
---@param price number
---@param pct number
---@return string
function M.quote(price, pct)
  return string.format(M.price_fmt(price) .. " %+.2f%%", price, pct)
end

return M
