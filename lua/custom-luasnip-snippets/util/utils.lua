local M = {}

-- local s = ls.snippet
-- local sn = ls.snippet_node
-- local isn = ls.indent_snippet_node
-- local t = ls.text_node
-- local i = ls.insert_node
-- local f = ls.function_node
-- local c = ls.choice_node
-- local d = ls.dynamic_node
-- local events = require("luasnip.util.events")
-- local r = require("luasnip.extras").rep
-- local fmt = require("luasnip.extras.fmt").fmt
-- local fmta = require("luasnip.extras.fmt").fmta

M.pipe = function(fns)
  return function(...)
    for _, fn in ipairs(fns) do
      if not fn(...) then
        return false
      end
    end

    return true
  end
end

M.no_backslash = function(line_to_cursor, matched_trigger)
  return not line_to_cursor:find("\\%a+$", -#line_to_cursor)
end

local ts_utils = require("custom-luasnip-snippets.util.ts_utils")
M.is_math = function(treesitter)
  if treesitter then
    return ts_utils.in_mathzone()
  end

  return vim.fn["vimtex#syntax#in_mathzone"]() == 1
end

M.not_math = function(treesitter)
  if treesitter then
    return ts_utils.in_text(true)
  end

  return not M.is_math()
end

M.comment = function()
  return vim.fn["vimtex#syntax#in_comment"]() == 1
end

M.env = function(name)
  local is_inside = vim.fn["vimtex#env#is_inside"](name)
  return (is_inside[1] > 0 and is_inside[2] > 0)
end

function M.in_bullets()
  return M.env("itemize") or M.env("enumerate") or M.env("description")
end

function M.not_in_bullets()
  return not M.in_bullets()
end

M.with_priority = function(snip, priority)
  snip.priority = priority
  return snip
end

M.with_opts = function(fn, opts)
  return function()
    return fn(opts)
  end
end

M.anki_in_latex_env = function()
  -- Get current cursor position: row (1-indexed) and column (0-indexed)
  local pos = vim.api.nvim_win_get_cursor(0)
  local current_row = pos[1]
  local current_col = pos[2] + 1 -- adjust because Lua strings are 1-indexed

  local count = 0

  -- Get all lines before the current line.
  local lines = vim.api.nvim_buf_get_lines(0, 0, current_row - 1, false)
  for _, line in ipairs(lines) do
    for _ in line:gmatch("%[latex%]") do
      count = count + 1
    end
    for _ in line:gmatch("%[/latex%]") do
      count = count - 1
    end
  end

  -- For the current line, only count markers up to the cursor column.
  local current_line = vim.api.nvim_get_current_line()
  local sub_line = current_line:sub(1, current_col)
  for _ in sub_line:gmatch("%[latex%]") do
    count = count + 1
  end
  for _ in sub_line:gmatch("%[/latex%]") do
    count = count - 1
  end

  return count > 0
end

return M
