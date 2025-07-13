local M = {}

local default_opts = {
  use_treesitter = false,
  allow_on_markdown = true,
}

M.setup = function(opts)
  opts = vim.tbl_deep_extend("force", default_opts, opts or {})

  local augroup = vim.api.nvim_create_augroup("custom-luasnip-snippets", {})

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "tex",
    group = augroup,
    once = true,
    callback = function()
      local utils = require("custom-luasnip-snippets.util.utils")
      local is_math = utils.with_opts(utils.is_math, opts.use_treesitter)
      local not_math = utils.with_opts(utils.not_math, opts.use_treesitter)
      M.setup_tex(is_math, not_math)
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "anki",
    group = augroup,
    once = true,
    callback = function()
      M.setup_anki()
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "forester",
    group = augroup,
    once = true,
    callback = function()
      M.setup_forester()
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    group = augroup,
    once = true,
    callback = function()
      M.setup_markdown()
    end,
  })
end

local _autosnippets = function(is_math, not_math)
  local autosnippets = {}

  for _, s in ipairs({
    "math_wRA_no_backslash",
    "math_rA_no_backslash",
    "math_wA_no_backslash",
    "math_iA_no_backslash",
    "math_iA",
    "math_wrA",
  }) do
    vim.list_extend(
      autosnippets,
      require(("custom-luasnip-snippets.%s"):format(s)).retrieve(is_math)
    )
  end

  for _, s in ipairs({
    "wA",
    "bwA",
  }) do
    vim.list_extend(
      autosnippets,
      require(("custom-luasnip-snippets.%s"):format(s)).retrieve(not_math)
    )
  end

  return autosnippets
end

M.setup_tex = function(is_math, not_math)
  local ls = require("luasnip")
  ls.add_snippets("tex", {
    ls.parser.parse_snippet(
      { trig = "pac", name = "Package" },
      "\\usepackage[${1:options}]{${2:package}}$0"
    ),

    -- ls.parser.parse_snippet({ trig = "nn", name = "Tikz node" }, {
    --   "$0",
    --   -- "\\node[$5] (${1/[^0-9a-zA-Z]//g}${2}) ${3:at (${4:0,0}) }{$${1}$};",
    --   "\\node[$5] (${1}${2}) ${3:at (${4:0,0}) }{$${1}$};",
    -- }),
  })

  local math_i = require("custom-luasnip-snippets/math_i").retrieve(is_math)

  ls.add_snippets("tex", math_i, { default_priority = 0 })

  ls.add_snippets("tex", _autosnippets(is_math, not_math), {
    type = "autosnippets",
    default_priority = 0,
  })
end

M.setup_forester = function()
  local ls = require("luasnip")
  local s = ls.snippet
  local t = ls.text_node
  local i = ls.insert_node
  local f = ls.function_node

  local latex_utils = require("custom-luasnip-snippets.util.utils")
  local pipe = latex_utils.pipe
  local utils = require("custom-luasnip-snippets.util.forester_utils")

  local latex_math = {}

  for _, s in ipairs({
    "math_wRA_no_backslash",
    "math_rA_no_backslash",
    "math_wA_no_backslash",
    "math_iA_no_backslash",
    "math_iA",
    "math_i",
    "math_wrA",
  }) do
    vim.list_extend(
      latex_math,
      require(("custom-luasnip-snippets.%s"):format(s)).retrieve(utils.in_mathzone)
    )
  end

  ls.add_snippets("forester", latex_math, {
    type = "autosnippets",
    default_priority = 0,
  })

  local conds = require("luasnip.extras.expand_conditions")

  ls.add_snippets("forester", {
    s({
      trig = "\\verb",
      snippetType = "autosnippet",
      condition = conds.line_begin,
    }, {
      t({ "\\pre\\verb<<<|", "" }),
      i(1),
      t({ "", "<<<" }),
    }),
    s({
      trig = "img",
      snippetType = "autosnippet",
      condition = conds.line_begin,
    }, {
      t({ "\\figure{", "" }),
      t("\\<html:img>[width]{"),
      i(1),
      t("}"),
      t("[src]{\\route-asset{assets/img/"),
      i(2),
      t({ "}}{}", "" }),
      t("\\figcaption{"),
      i(3),
      t({ "}", "" }),
      t("}"),
    }),
    s("\\ul", { t({ "\\ul{", "  " }), i(1), t({ "", "}" }) }),
    s("\\ol", { t({ "\\ol{", "  " }), i(1), t({ "", "}" }) }),
    s({
      trig = "--",
      snippetType = "autosnippet",
      show_condition = pipe({ utils.not_in_mathzone, utils.in_list }),
      condition = pipe({ utils.not_in_mathzone, utils.in_list }),
    }, { t("\\li{"), i(1), t("}") }),
    s({ trig = "\\p", condition = utils.not_in_mathzone }, { t("\\p{"), i(1), t("}") }),
    s("\\str", { t("\\strong{"), i(1), t("}") }),
    s("\\em", { t("\\em{"), i(1), t("}") }),
    s("\\sec", { t("\\section{"), i(1), t("}"), t({ "{", "" }), i(2), t({ "", "}" }) }),
    s("\\rem", { t({ "\\remark{", "" }), i(1), t({ "", "}" }) }),
    s("\\pf", { t({ "\\proof{", "" }), i(1), t({ "", "}" }) }),
    s("\\ex", { t({ "\\example{", "" }), i(1), t({ "", "}" }) }),
    s("\\au", { t("\\author{kellenkanarios}") }),
    s("\\ba", { t("\\import{base-macros}") }),
    s("\\ti", { t("\\title{"), i(1), t("}") }),
    s("\\lk", { t("["), i(1), t("]"), t("("), i(2), t(")") }),
    s({
      trig = "[)",
      name = "clopen",
      priority = 100,
    }, {
      t("\\closed-open{"),
      i(1),
      t("}"),
    }),
    s({
      trig = "[)",
      name = "opencl",
      priority = 100,
    }, {
      t("\\open-closed{"),
      i(1),
      t("}"),
    }),
    s({
      trig = "ali",
      name = "Align",
      show_condition = utils.in_mathzone,
      condition = utils.in_mathzone,
    }, { t({ "\\begin{align*}", "\t" }), i(1), t({ "", ".\\end{align*}" }) }),
    s({
      trig = "mk",
      snippetType = "autosnippet",
      show_condition = utils.not_in_mathzone,
      condition = utils.not_in_mathzone,
    }, { t("#{"), i(1), t("}") }),
    s({
      trig = "dm",
      snippetType = "autosnippet",
      show_condition = utils.not_in_mathzone,
      condition = utils.not_in_mathzone,
    }, { t("##{"), i(1), t("}") }),
  }, {
    type = "autosnippets",
    key = "forester_auto",
  })
end

M.setup_markdown = function()
  local ls = require("luasnip")
  local utils = require("custom-luasnip-snippets.util.utils")
  local pipe = utils.pipe

  local is_math = utils.with_opts(utils.is_math, true)
  local not_math = utils.with_opts(utils.not_math, true)

  local math_i = require("custom-luasnip-snippets/math_i").retrieve(is_math)
  ls.add_snippets("markdown", math_i, { default_priority = 0 })

  local autosnippets = _autosnippets(is_math, not_math)
  local trigger_of_snip = function(s)
    return s.trigger
  end

  local to_filter = {}
  for _, str in ipairs({
    "wA",
    "bwA",
  }) do
    local t = require(("custom-luasnip-snippets.%s"):format(str)).retrieve(not_math)
    vim.list_extend(to_filter, vim.tbl_map(trigger_of_snip, t))
  end

  local filtered = vim.tbl_filter(function(s)
    return not vim.tbl_contains(to_filter, s.trigger)
  end, autosnippets)

  local parse_snippet = ls.extend_decorator.apply(ls.parser.parse_snippet, {
    condition = pipe({ not_math }),
  }) --[[@as function]]

  -- tex delimiters
  local normal_wA_tex = {
    parse_snippet({ trig = "mk", name = "Math" }, "$${1:${TM_SELECTED_TEXT}}$"),
    parse_snippet({ trig = "dm", name = "Block Math" }, "$$\n\t${1:${TM_SELECTED_TEXT}}\n.$$"),
  }
  vim.list_extend(filtered, normal_wA_tex)

  ls.add_snippets("markdown", filtered, {
    type = "autosnippets",
    default_priority = 0,
  })
end

M.setup_anki = function()
  local ls = require("luasnip")
  local s = ls.snippet
  local t = ls.text_node
  local i = ls.insert_node

  local utils = require("custom-luasnip-snippets.util.utils")
  local pipe = utils.pipe

  -- local conds = require("luasnip.extras.expand_conditions")

  local is_math = utils.with_opts(utils.is_math, true)
  local not_math = utils.with_opts(utils.not_math, true)
  is_math = pipe({ utils.anki_in_latex_env, is_math })
  not_math = pipe({ utils.anki_in_latex_env, not_math })

  local math_i = require("custom-luasnip-snippets/math_i").retrieve(is_math)
  ls.add_snippets("anki", math_i, { default_priority = 0 })

  local trigger_of_snip = function(s)
    return s.trigger
  end
  -- tex delimiters
  --
  for _, str in ipairs({
    "wA",
    "bwA",
  }) do
    local t = require(("custom-luasnip-snippets.%s"):format(str)).retrieve(not_math)
    ls.add_snippets("anki", t, {
      type = "autosnippets",
      default_priority = 0,
    })
  end

  ls.add_snippets("anki", {
    s("mk", {
      t({ "[latex]", "" }),
      i(1),
      t({ "", "[/latex]" }),
    }),
  }, {
    type = "autosnippets",
    default_priority = 1,
  })
end

return M
