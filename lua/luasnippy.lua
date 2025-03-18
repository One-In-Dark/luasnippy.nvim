local luasnip = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local conditions = require("luasnip.extras.conditions")
local conditionsExpand = require("luasnip.extras.conditions.expand")

local luasnippy = {}

---@return fun(_, parent): any # a function that extracts the capture with the given index from the parent snippet, for use in function node.
function luasnippy.capture_extract(indice)
   return function (_, parent)
      return parent.snippet.captures[indice]
   end
end

---@param context string The context of the snippet, complying with the short-handed syntax described in `snippy`
---@param baseset table The base set of options to be used for the snippet, which should be mutable
local function parse_context(context, baseset)
   local context_tbl = baseset
   if context:match("r") then
      context_tbl.trigEngine = "pattern"
   end
   if context:match("Rv") then
      context_tbl.trigEngine = "vim"
   end
   if context:match("Re") then
      context_tbl.trigEngine = "ecma"
   end

   if context:match("i") then
      context_tbl.wordTrig = false
   end
   if context:match("b") then
      context_tbl.condition = context_tbl.condition
          and context_tbl.condition * conditionsExpand.line_begin
          or conditionsExpand.line_begin
   end
   if context:match("Ce") then
      context_tbl.condition = context_tbl.condition
          and context_tbl.condition * conditionsExpand.line_end
          or conditionsExpand.line_end
   end

   if context:match("A") then
      context_tbl.snippetType = "autosnippet"
   end
   context_tbl.priority = context:match("P(%d+)")
   if context_tbl.priority then
      context_tbl.priority = tonumber(context_tbl.priority)
   end
   return context_tbl
end

---@class (exact) SnippetTuple
---@field [1] table The context of the snippet
---@field [2] string Contents of the snippet as in `fmt`
---@field [3] any The body elements of the snippet
---@field [4] table Table to be passed to `fmt`
---@field _snip boolean Set for all `SnippetTuple` instance

---Creates a LuaSnippy snippet, supporting the following short-handed option syntax:
---- `r` for Lua pattern, `Rv` for vim regex, `Re` for ECMAscript regex,
---- `i` for in-word, `b` for beginning-of-line, `Ce` for endding-of-line,
---- `A` for autosnippet, `P<num>` for priority `<num>`.
---Any other characters are ignored.
---@param context table|string The context of the snippet (see `context` in `:h luasnip-snippets`), additionally supporting short-handed option syntax described above, either as a single string or as the field `[1]` of the table.
---@param trigger string
---@param body_str string The contents of the snippet, as in `fmt` (see `format` in `:h luasnip-extras-fmt`)
---@param body_elems any|nil The body elements of the snippet, as in `fmt` (see `nodes` in `:h luasnip-extras-fmt`)
---@param opts table|nil Passed to `fmt` as the third argument (see `opts` in `:h luasnip-extras-fmt`)
---@return SnippetTuple # The snippet tuple with the given context, trigger, and body elements
function luasnippy.snippy(context, trigger, body_str, body_elems, opts)
   local context_tbl
   if type(context) == "table" then
      if context[1] then
         assert(type(context[1]) == "string",
            "Invalid context[1] type: " .. type(context[1]))
         context_tbl = parse_context(context[1], context)
      else context_tbl = context end
   elseif type(context) == "string" then
      context_tbl = parse_context(context, {})
   else error("Invalid context type: " .. type(context)) end
   context_tbl.trig = trigger
   body_elems = body_elems or {}
   return { context_tbl, body_str, body_elems, opts, _snip = true }
end

---Works the same way as `snippy`, with delimiters set to angular brackets "<>". It to `snippy` is what `fmta` to `fmt`, see `:h luasnip-extras-fmt`.
function luasnippy.snippy_angular(context, trigger, body_str, body_elems, opts)
   opts = opts or {}; opts.delimiters = "<>"
   return luasnippy.snippy(context, trigger, body_str, body_elems, opts)
end

---@param cond table|function A function, or a condition object (see `CONDITION OBJECTS` in `:h luasnip-extras-conditions`).
---@param snippets (SnippetTuple|SnippetTuple[])[]
---@return SnippetTuple[] # The snippets that respects the condition
function luasnippy.conditional_by(cond, snippets)
   if type(cond) == "function" then
      cond = conditions.make_condition(cond)
   elseif type(cond) ~= "table" then
      error("Invalid condition type: " .. type(cond))
   end
   local snippetsConditional = {}
   for _, snipgrp in ipairs(snippets) do
      if snipgrp._snip then
         snipgrp = { snipgrp } -- singleton list
      end
      for _, snip in ipairs(snipgrp --[[@as SnippetTuple[]--]]) do
         assert(snip._snip, "Non-snippet passed to conditional_by")
         snip[1].condition = snip[1].condition
            and snip[1].condition * cond or cond
         table.insert(snippetsConditional, snip)
      end
   end
   return snippetsConditional
end

---Accepts a list of LuaSnippy snippets and converts them to LuaSnip snippets, for use in snippet file `return` (see `:h luasnip-loaders-lua`) or `luasnip.add_snippets` (see `:h luasnip-api`).
---@param snippetTuples (SnippetTuple|SnippetTuple[])[]
---@return any # list of LuaSnip snippets
function luasnippy.pack_snippets(snippetTuples)
   local snippets = {}
   for _, snipgrp in ipairs(snippetTuples) do
      if snipgrp._snip then
         snipgrp = { snipgrp } -- singleton list
      end
      for _, snip in ipairs(snipgrp --[[@as SnippetTuple[]--]]) do
         assert(snip._snip, "Non-snippet passed to pack_snippets")
         snip = luasnip.snippet(snip[1], fmt(snip[2], snip[3], snip[4]))
         table.insert(snippets, snip)
      end
   end
   return snippets
end

return luasnippy
