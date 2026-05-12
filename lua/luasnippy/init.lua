local luasnip = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local conditions = require("luasnip.extras.conditions")
local conditions_expand = require("luasnip.extras.conditions.expand")

local log_levels = vim.log.levels

local line_begin_cond = conditions_expand.line_begin
local line_end_cond = conditions_expand.line_end

local luasnippy = {}

---@return fun(_, parent): any # a function that extracts the capture with the given index from the parent snippet, for use in function node.
function luasnippy.capture_extract(indice)
   return function(_, parent)
      return parent.snippet.captures[indice]
   end
end

local context_parser = vim.re.compile([[
   Pattern <- ItemList
   Item <- {:auto: 'A' :}
         / {:luaregex: 'r' :}
         / {:inword: 'i' :}
         / {:linebegin: 'b' :}
         / {:lineend: 'Ce' :}
         / {:vimregex: 'Rv' :}
         / {:ecmaregex: 'Re' :}
         / 'P' {:priority: %d+ :}
         / {:unknown: . :}
   ItemList <- %s* {| (Item %s*)* |} !.
]])

---@param context string The context of the snippet, complying with the short-handed syntax described in `snpt`
---@param baseset table (mutable) The base set of options to be used for the snippet
local function parse_context(context, baseset)
   local context_tbl = baseset
   local parsed = context_parser:match(context)
   if parsed.auto then
      context_tbl.snippetType = "autosnippet"
   end
   if parsed.luaregex then
      context_tbl.trigEngine = "pattern"
   elseif parsed.vimregex then
      context_tbl.trigEngine = "vim"
   elseif parsed.ecmaregex then
      context_tbl.trigEngine = "ecma"
   end
   if parsed.inword then
      context_tbl.wordTrig = false
   end
   if parsed.linebegin then
      context_tbl.condition = context_tbl.condition
         and context_tbl.condition * line_begin_cond
         or line_begin_cond
   end
   if parsed.lineend then
      context_tbl.condition = context_tbl.condition
         and context_tbl.condition * line_end_cond
         or line_end_cond
   end
   if parsed.priority then
      context_tbl.priority = tonumber(parsed.priority)
   end
   if parsed.unknown then
      vim.notify("Unknown context: " .. parsed.unknown, log_levels.WARN)
   end
   return context_tbl
end

---@class (exact) SnippetTuple
---@field [1] table The context of the snippet
---@field [2] string Contents of the snippet as in `fmt`
---@field [3] any The body elements of the snippet
---@field [4] table Table to be passed to `fmt`
---@field _snip boolean Set for all `SnippetTuple` instance

---Creates a LuaSnippy snippet tuple, supporting the following short-handed option syntax:
---- `r` for Lua pattern, `Rv` for vim regex, `Re` for ECMAscript regex,
---- `i` for in-word, `b` for beginning-of-line, `Ce` for endding-of-line,
---- `A` for autosnippet, `P<num>` for priority `<num>`.
---Any other character combination raise a warning.
---@param context table|string The context of the snippet (see `context` in `:h luasnip-snippets`), additionally supporting short-handed option syntax described above, either as a single string or as the field `[1]` of the table.
---@param trigger string
---@param body_str string The contents of the snippet, as in `fmt` (see `format` in `:h luasnip-extras-fmt`)
---@param body_elems any|nil The body elements of the snippet, as in `fmt` (see `nodes` in `:h luasnip-extras-fmt`)
---@param opts table|nil Passed to `fmt` as the third argument (see `opts` in `:h luasnip-extras-fmt`)
---@return SnippetTuple # The snippet tuple with the given context, trigger, and body elements
local function snippet_tuple(context, trigger, body_str, body_elems, opts)
   local context_tbl
   if type(context) == "table" then
      if context[1] then
         vim.validate("context[1]", context[1], "string")
         context_tbl = parse_context(context[1], context)
      else
         context_tbl = context
      end
   elseif type(context) == "string" then
      context_tbl = parse_context(context, {})
   else
      error("context: expected table|string, got " .. type(context))
   end
   context_tbl.trig = trigger
   -- body_elems = body_elems or {}
   return { context_tbl, body_str, body_elems, opts, _snip = true }
end

---Creates a LuaSnippy snippet.
---
---This is the main "snippet constructor" for the public API.
---
---Order of arguments: trigger first, then context.
---@param trigger string
---@param context table|string See `snippet_tuple` for supported forms.
---@param body_str string
---@param body_elems any
---@param opts table|nil
---@return SnippetTuple
function luasnippy.snpt(trigger, context, body_str, body_elems, opts)
   return snippet_tuple(context, trigger, body_str, body_elems, opts)
end

---Works the same way as `snpt`, with delimiters being angular brackets "<>".
---It to `snpt` is what `fmta` to `fmt`, see `:h luasnip-extras-fmt`.
---@param trigger string
---@param context table|string
---@param body_str string
---@param body_elems any|nil
---@param opts table|nil
---@return SnippetTuple
function luasnippy.snpta(trigger, context, body_str, body_elems, opts)
   opts = vim.tbl_deep_extend("force", opts or {}, {
      delimiters = "<>",
   })
   return snippet_tuple(context, trigger, body_str, body_elems, opts)
end

---@param cond table|function A function, or a condition object (see `CONDITION OBJECTS` in `:h luasnip-extras-conditions`).
---@param snippets (SnippetTuple|SnippetTuple[])[]
---@return SnippetTuple[] # The snippets that respects the condition
function luasnippy.context(cond, snippets)
   if type(cond) == "function" then
      cond = conditions.make_condition(cond)
   elseif type(cond) ~= "table" then
      error("condition: expected table|function, got " .. type(cond))
   end
   local conditional_snippets = {}
   for _, snipgrp in ipairs(snippets) do
      if snipgrp._snip then
         snipgrp = { snipgrp } -- singleton list
      end
      ---@cast snipgrp SnippetTuple[]
      for _, snip in ipairs(snipgrp) do
         assert(snip._snip, "Non-snippet passed to context")
         snip[1].condition = snip[1].condition
            and snip[1].condition * cond or cond
         table.insert(conditional_snippets, snip)
      end
   end
   return conditional_snippets
end

---Accepts a list of LuaSnippy snippets and converts them to LuaSnip snippets, for use in snippet file `return` (see `:h luasnip-loaders-lua`) or `luasnip.add_snippets` (see `:h luasnip-api`).
---@param snippet_tuples (SnippetTuple|SnippetTuple[])[]
---@return any # list of LuaSnip snippets
function luasnippy.pack_snippets(snippet_tuples)
   local snippets = {}
   for _, snipgrp in ipairs(snippet_tuples) do
      if snipgrp._snip then
         snipgrp = { snipgrp } -- singleton list
      end
      ---@cast snipgrp SnippetTuple[]
      for _, snip in ipairs(snipgrp) do
         assert(snip._snip, "Non-snippet passed to pack_snippets")
         snip = luasnip.snippet(snip[1], fmt(snip[2], snip[3], snip[4]))
         table.insert(snippets, snip)
      end
   end
   return snippets
end

luasnippy.make_condition = conditions.make_condition

return luasnippy
