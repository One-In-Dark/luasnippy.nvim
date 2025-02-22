# luasnippy.nvim
A more ergonomic snippet facility wrapping LuaSnip

# Rationale

Snippets are powerful, but to utilize them maximally, one should write his own snippets. Otherwise it’s more a LSP thing.

[LuaSnip](https://github.com/L3MON4D3/LuaSnip) has provided a good mechanism for *computers* to implement the snippet functionality, by structuring all information in Lua tables and breaking up the snippet into nodes. However, writing snippets directly in LuaSnip requires a lot of boilerplate. I really miss the neat format of UltiSnips.

LuaSnippy aims to bring back the ergonomic way of snippets’ definition. An example should help illustrate this:

```lua
return packsnip {
   snipa("b Ce A", "beg", [==[
      \begin{<>}
        <>
      \end{<>}
      ]==], { i(1), i(0), extras.rep(1) }),
   cnd(IsInMath, {
      snipa("iA P500", "//", "\\frac{<>}{<>}", { i(1), i(2) }),
      snipa("iRv P500", "bar", "\\overline{<>}", { i(1) }),
   }),
}
```

+ Grouping snippets by conditions (contexts)
+ Short-hand syntax for context options
+ Intuitive format-string syntax

# Installation

You can use any of the plugin manager, or `git clone` this repo and add it to your `'rtp'`. Using *lazy.nvim* we may also specify this plugin as a dependency of *LuaSnip* by something like this:

```lua
   {
      "L3MON4D3/LuaSnip",
      dependencies = {
         { "One-In-Dark/luasnippy.nvim" },
      },
   }
```

# Usage

## Snippet

The main functionality of this plugin is provided in:

```lua
local snip = require("luasnippy").snippy
```

Normally the first argument of `snippy` is a string, with a similar syntax to UltiSnips, specifying the context of the snippet.

+ The common expansion conditions are provided:
  + `i` stands for in-word, i.e. not matching the entire word (`[%w_]+`) before the cursor;
  + `b` stands for beginning-of-line, i.e. only expand if the trigger word is at the beginning of the line;
  + `Ce` stands for endding-of-line, i.e. only expand at the end of the line.
+ Commonly used is the regex matching. All three variants are supported (see `trigEngine` in `:h luasnip-snippets`):
  + `r` stands for Lua pattern, which suffices most of the time, nevertheless the support of Unicode is poor;
  + `Rv` stands for Vim-regex;
  + `Re` stands for ECMAscript-regex.
+ Another two handy options:
  + `A` stands for auto-expansion;
  + `P<num>` sets the priority to `<num>` (see `priority` in `:h luasnip-snippets`).

The second argument is the trigger word. The next two arguments form a f-string in Python (for those who are unfamiliar, it’s like string interpolation in shell), as is illustrated by the example above.

The last argument can further regulate the behaviour of the string formatting, see `opts` in `:h luasnip-extras-fmt`.

A variant that uses angular brackets `<>` for string formatting instead of `{}` is provided:

```lua
local snipa = require("luasnippy").snippy_angular
```

## Conditional

```lua
local cnd = require("luasnippy").conditional_by
```

Conditions apply to all snippets in its scope, which makes it very easy to write now. `conditional_by` accepts a function or a condition object (see `CONDITION OBJECTS` in `:h luasnip-extras-conditions`), and applies it to the snippets in the second argument.

Nesting is supported.

## Backend

LuaSnip is the “backend” of the plugin. The function `pack_snippets` can “compile” LuaSnippy-style snippets:

```lua
local packsnip = require("luasnippy").pack_snippets
```

Now enjoy the power of snippets!

# Examples

Personally I need snippets when writing LaTeX, and below are the snippets I use:

```lua
local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta
local extras = require("luasnip.extras")
local luasnippy = require("luasnippy")

local snip = luasnippy.snippy
local snipa = luasnippy.snippy_angular
local cnd = luasnippy.conditional_by
local packsnip = luasnippy.pack_snippets
local capture_extract = luasnippy.capture_extract
local tnode = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local cnode = ls.choice_node
local sn = ls.snippet_node
-- local d = ls.dynamic_node

local capturee1 = capture_extract(1)
local capturee2 = capture_extract(2)
local MAX_SEARCH_LINES = 20

local function IsInMath()
   return vim.call("vimtex#syntax#in_mathzone") == 1
end

---@param envname string Lua pattern of the acceptable environment
local function IsInEnv(envname)
   local env = vim.call("vimtex#env#get_inner")
   return env and env.name:match(envname)
end

local _greekRegex = vim.lpeg.utfR(0x370, 0x3ff)
local _identifierRegexBackwards = vim.re.compile([[(%a+ "\") / %a]]) * vim.lpeg.Cp() ---@type vim.lpeg.Pattern
local function FindTrailingIdentifierPosition(str)
   if _greekRegex:match(str:sub(-2, -1)) then return #str - 1 end
   local match = _identifierRegexBackwards:match(str:reverse())
   return match and #str - match + 2 or nil
end

---@param str string
---@TODO improve efficiency by reversing and do one-shot match
local function EliminateTrailingSubscript(str)
   local pos = str:find("_%b{}$")
   return pos and str:sub(1, pos - 1) or str
end

return packsnip {
   snipa("b Ce A", "beg", [==[
      \begin{<>}<>
        <>
      \end{<>}
      ]==], { i(1),
         cnode(2, { tnode("{}{}"),
            sn(nil, fmta("{<>}{<>}", { i(1, ""), i(2, "label") })),
         }), i(0), extras.rep(1) }),
   snipa("b Ce A", "incgra", [[
      \includegraphics[width=<>\textwidth]{<>}
      ]], { i(1), i(2) }),
   cnd(function () return not IsInMath() end, {
      snip("A", "dm", [=[
         \[
           {}
         {}\]
         ]=], { i(1), f(function()
            local lineno = vim.api.nvim_win_get_cursor(0)[1] -- 1-indexed
            local lastline = vim.api.nvim_buf_get_lines( -- lineno - 1
               0, lineno - 2, lineno - 1, false)[1] -- 0-indexed 
            if lastline == "" then return "" end
            return lastline:match("[,:]$") and "." or ","
         end) }),
      snip("A", "mk", "${}$", { i(1) }),
      snip("A", "cd", [[\verb"{}"]], { i(1) }),
      snipa("", "ep", "\\emph{<>}", { i(1) }),
   }),
   cnd(IsInMath, {
      snip("Rv iA", [=[\([a-zA-Z\u0370-\u03ff]\)\(\d\)]=], "{}_{}", { f(capturee1), f(capturee2) }),
      snipa("Rv iA", [=[\([a-zA-Z\u0370-\u03ff]\)_\(\d\d\)]=], "<>_{<>}", { f(capturee1), f(capturee2) }),
      snip("irA", "(%S)sr", "{}^2", { f(capturee1) }),
      snip("irA", "(%S)%^2(%d)", "{}^{}", { f(capturee1), f(capturee2) }),
      snipa("iA P500", "//", "\\frac{<>}{<>}", { i(1), i(2) }),
      snipa("Rv A", [=[\(\d\+\|\d*\%(\%(\\\)\?\a\+\|[\u0370-\u03ff]\)\)/]=], "\\frac{<>}{<>}", { f(capturee1), i(1) }),

      snipa("iARv", [=[\([a-zA-Z\u0370-\u03ff]\)bar]=], "\\bar{<>}", { f(capturee1) }),
      snipa("iA P500", "bar", "\\overline{<>}", { i(1) }),
      snipa("iARv", [=[\([a-gi-zA-Z\u0370-\u03ff]\)hat]=], "\\hat{<>}", { f(capturee1) }),
      snipa("iA P500", "bar", "\\widehat{<>}", { i(1) }),
      snipa("iARv", [=[\([a-zA-Z\u0370-\u03ff]\)tld]=], "\\tilde{<>}", { f(capturee1) }),
      snipa("i P500", "tld", "\\tilde{<>}", { i(1) }),
      snipa("iARv", [=[\([a-zA-Z\u0370-\u03ff]\)vec]=], "\\vec{<>}", { f(capturee1) }),
      snipa("iA P500", "vec", "\\overrightarrow{<>}", { i(1) }),

      snip("i", "sl", "/", {}),
      snip("i", "inc", "∆", {}),
      snip("iA", "OO", "\\varnothing", {}),
      snip("A", "=> ", "\\implies ", {}),
      snip("iA", "=>>", "\\rightrightarrows ", {}),
      snip("iA", "<=", "\\leqslant", {}),
      snip("iA", ">=", "\\geqslant", {}),
      snip("iA", "~>", "\\rightsquigarrow", {}),
      snip("i", "div", "\\divslash", {}),
      snip("i", "com", "\\buji", {}), -- customized command

      snipa("iA", "mrm", "\\mathrm{<>}", { i(1) }),
      snipa("i", "bi", "\\mat{<>}", { i(1) }),
      snipa("iARv", [[\C\%(\\sub\|\\\)\@10<!set]], [[\{<>\}]], { i(1) }),
      snipa("i", "bin", "\\binom{<>}{<>}", { i(1), i(2) }),

      snipa({"iA", desc = "Copy subscript"}, "__", "_{<><>}", {
         f(function ()
            local curpos = vim.api.nvim_win_get_cursor(0) -- (1,0)-indexed
            local ranges = vim.api.nvim_buf_get_lines(0, math.max(0, curpos[1] - MAX_SEARCH_LINES), curpos[1], false) -- 0-based, end-exclusive
            local curline = ranges[#ranges]:sub(1, curpos[2])
            local startpos = FindTrailingIdentifierPosition(curline)
            if not startpos then return "" end
            local name = curline:sub(startpos, -1):reverse()
            ranges[#ranges] = curline:sub(1, startpos - 1)
            for j = #ranges, 1, -1 do
               local line = ranges[j]:reverse()
               local pos = 0 ---@type integer|nil
               while true do
                  pos = line:find(name, pos + 1, true)
                  if pos == nil then break end
                  if line:sub(pos - 2, pos - 1) == "{_" then
                     local linepart = line:sub(1, pos - 2):reverse()
                     return linepart:match("^%b{}"):sub(2, -2)
                  end
               end
            end
            return ""
         end), i(1) }),
      snipa({"iA", desc = "Copy superscript"}, "^^", "^{<><>}", {
         f(function ()
            local curpos = vim.api.nvim_win_get_cursor(0) -- (1,0)-indexed
            local ranges = vim.api.nvim_buf_get_lines(0, math.max(0, curpos[1] - MAX_SEARCH_LINES), curpos[1], false) -- 0-based, end-exclusive
            local curline = ranges[#ranges]:sub(1, curpos[2])
            curline = EliminateTrailingSubscript(curline)
            local startpos = FindTrailingIdentifierPosition(curline)
            if not startpos then return "" end
            local name = curline:sub(startpos, curpos[2]):reverse()
            ranges[#ranges] = curline:sub(1, startpos - 1)
            for j = #ranges, 1, -1 do
               local line = ranges[j]:reverse()
               local pos = 0 ---@type integer|nil
               while true do
                  pos = line:find(name, pos + 1, true)
                  if pos == nil then break end
                  if line:sub(pos - 2, pos - 1) == "{^" then
                     local linepart = line:sub(1, pos - 2):reverse()
                     return linepart:match("^%b{}"):sub(2, -2)
                  elseif line:sub(pos - 2, pos - 1) == "{_" then
                     local linepart = line:sub(1, pos - 2):reverse()
                     local x = linepart:match("^%b{}%^(%b{})")
                     if x then return x:sub(2, -2) end
                  end
               end
            end
            return ""
         end), i(1) }),
   }),
   cnd(function () return IsInEnv("itemize") or IsInEnv("enumerate") end, {
      snip("b Ce A", "  - ", "\\item {}", { i(1) })
   }),
   cnd(function () return IsInEnv("description") end, {
      snip("b Ce A", "  - ", "\\item [{}] {}", { i(1), i(2) })
   }),
}
```

Last note: as for API reference, I am struggling to find a good documentation generator that supports exporting functions by `return`-ing at the end of the file (which excludes vimCATS). If you have any suggestion, please let me know. Thanks!

