local luasnip = require("luasnip")
local extras = require("luasnip.extras")
local fmta = require("luasnip.extras.fmt").fmta
local luasnippy = require("luasnippy")

local api = vim.api

local cnode = luasnip.choice_node
local f = luasnip.function_node
local i = luasnip.insert_node
local sn = luasnip.snippet_node
local tnode = luasnip.text_node

local snpt = luasnippy.snpt
local snpta = luasnippy.snpta
local context = luasnippy.context
local pack_snippets = luasnippy.pack_snippets
local capture_extract = luasnippy.capture_extract
local make_condition = luasnippy.make_condition

local capturee1 = capture_extract(1)
local MAX_SEARCH_LINES = 100

local function is_in_math()
   return vim.call("vimtex#syntax#in_mathzone") == 1
end
local is_in_math_cond = make_condition(is_in_math)

---@param envname string Lua pattern of the acceptable environment
local function is_in_env(envname)
   local env = vim.call("vimtex#env#get_inner")
   return env and env.name and env.name:match(envname)
end

local greek_regex = vim.lpeg.utfR(0x370, 0x3ff)
local identifier_regex_backwards = vim.re.compile([[
   ((%a+ "\") / %a) {}
]])
local function find_trailing_identifier_pos(str)
   if greek_regex:match(str:sub(-2, -1)) then return #str - 1 end
   local match = identifier_regex_backwards:match(str:reverse())
   return match and #str - match + 2 or nil
end

---@param str string
---@TODO improve efficiency by reversing and do one-shot match
local function eliminate_trailing_subscript(str)
   local pos = str:find("_%b{}$")
   if pos then return str:sub(1, pos - 1) end
   pos = str:find("_.$") -- single character
   return pos and str:sub(1, pos - 1) or str
end

---@param lineno 0-based line index
local function get_endchar_of_line(lineno)
   local line_offset = api.nvim_buf_get_offset(0, lineno + 1)
   local offset = line_offset - 2 -- strip EOL
   local args = {0, lineno, offset, lineno, offset + 1, {}}
   local lastline = api.nvim_buf_get_text(unpack(args))[1]
   return lastline
end

return pack_snippets {
   snpta("beg", "b Ce A", [==[
      \begin{<>}<>
        <>
      \end{<>}
      ]==],
      {
         i(1),
         cnode(2, {
            tnode("{}{}"),
            sn(nil, fmta("{<>}{<>}", { i(1), i(2, "label") })),
            sn(nil, fmta("{<>}{}", { i(1, "name") })),
         }),
         i(0),
         extras.rep(1)
      }),
   snpta("incgra", "b Ce A", [[
      \includegraphics[width=<>\textwidth]{<>}
      ]], { i(1), i(2) }),
   context(-is_in_math_cond, {
      snpt("dm", "b Ce A", [=[
         \[
           {}
         {}\]
         ]=],
         {
            i(1),
            f(function()
               local lineno = api.nvim_win_get_cursor(0)[1] - 1
               local lastline = get_endchar_of_line(lineno - 1)
               if lastline == "" then return "" end
               return lastline:match("[,:]$") and "." or ","
            end)
         }),
      snpt("mk", "A", "${}$", { i(1) }),
      snpt("cd", "A", [[\verb"{}"]], { i(1) }),
      snpta("ep", "", "\\emph{<>}", { i(1) }),
      snpta("enum", "b Ce A", [[
         \begin{enumerate}<>
           \item <>
         \end{enumerate}
         ]], { i(1), i(0) }),
      snpta("item", "b Ce A", [[
         \begin{itemize}
           \item <>
         \end{itemize}
         ]], { i(0) }),
      snpta("desc", "b Ce A", [[
         \begin{description}
           \item [<>] <>
         \end{description}
         ]], { i(1), i(0) }),
      snpta("fig", "b Ce A", [[
         \begin{figure}[hbp]
           \centering
           <>
           \caption{<>}\label{fig:<>}
         \end{figure}
         ]], { i(0), i(1), i(2) }),
      context(function()
         return is_in_env("itemize") or is_in_env("enumerate")
      end, {
         snpt("  - ", "b Ce A", "\\item {}", { i(1) })
      }),
      context(function() return is_in_env("description") end, {
         snpt("  - ", "b Ce A", "\\item [{}] {}", { i(1), i(0) })
      }),
   }),
   context(is_in_math_cond, {
      luasnippy.math_snippets(),

      snpta([=[\([a-zA-Z\u0370-\u03ff]\)bar]=], "iARv",
         "\\bar{<>}", { f(capturee1) }),
      snpta("\\bar", "iA",
         "\\bar{<>}", { i(1) }),
      snpta("bar", "iA P500",
         "\\overline{<>}", { i(1) }),
      snpta([=[\([a-gi-zA-Z\u0370-\u03ff]\)hat]=], "iARv",
         "\\hat{<>}", { f(capturee1) }),
      snpta("hat", "iA P500",
         "\\widehat{<>}", { i(1) }),
      snpta([=[\([a-zA-Z\u0370-\u03ff]\)tld]=], "iARv",
         "\\tilde{<>}", { f(capturee1) }),
      snpta("tld", "i P500",
         "\\tilde{<>}", { i(1) }),
      snpta([=[\([0a-zA-Z\u0370-\u03ff]\)vec]=], "iARv",
         "\\vec{<>}", { f(capturee1) }),
      snpta("vec", "iA P500",
         "\\overrightarrow{<>}", { i(1) }),
      snpta([=[\([a-zA-Z\u0370-\u03ff]\)mbi]=], "iARv",
         "\\mat{<>}", { f(capturee1) }),
      snpta("mbi", "iA P500",
         "\\mat{<>}", { i(1) }),

      snpt("sl", "i", "/", {}),
      snpt("inc", "i", "∆", {}),
      snpt("OO", "iA", "\\varnothing", {}),
      snpt("=> ", "A", "\\implies ", {}),
      snpt("=>>", "iA", "\\rightrightarrows ", {}),
      snpt("<=", "iA", "\\leqslant", {}),
      snpt(">=", "iA", "\\geqslant", {}),
      snpt("~>", "iA", "\\rightsquigarrow", {}),
      snpt("div", "i", "\\divslash ", {}),
      snpt("com", "i", "\\buji", {}), -- customized command

      snpta("mrm", "iA",
         "\\mathrm{<>}", { i(1) }),
      snpta([[\C\%(\\sub\|\\over\|\\sup\|\\\)\@10<!set]], "iA Rv",
         [[\{<>\}]], { i(1) }),
      snpta("bin", "i",
         "\\binom{<>}{<>}", { i(1), i(2) }),

      snpta("__", {"iA", desc = "Copy subscript"}, "_{<><>}", {
         f(function()
            local curpos = api.nvim_win_get_cursor(0) -- (1,0)-indexed
            local ranges = api.nvim_buf_get_lines(0, math.max(0, curpos[1] - MAX_SEARCH_LINES), curpos[1], false) -- 0-based, end-exclusive
            local curline = ranges[#ranges]:sub(1, curpos[2])
            local startpos = find_trailing_identifier_pos(curline)
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
         end),
         i(1)
      }),
      snpta("^^", {"iA", desc = "Copy superscript"}, "^{<><>}", {
         f(function()
            local curpos = api.nvim_win_get_cursor(0) -- (1,0)-indexed
            local ranges = api.nvim_buf_get_lines(0, math.max(0, curpos[1] - MAX_SEARCH_LINES), curpos[1], false) -- 0-based, end-exclusive
            local curline = ranges[#ranges]:sub(1, curpos[2])
            curline = eliminate_trailing_subscript(curline)
            local startpos = find_trailing_identifier_pos(curline)
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
                  elseif line:sub(pos - 1, pos - 1) == "_" then
                     if line:sub(pos - 2, pos - 2) == "{" then
                        local linepart = line:sub(1, pos - 2):reverse()
                        local x = linepart:match("^%b{}%^(%b{})")
                        if x then return x:sub(2, -2) end
                     else
                        local linepart = line:sub(1, pos - 3):reverse()
                        local x = linepart:match("^%^(%b{})")
                        if x then return x:sub(2, -2) end
                     end
                  end
               end
            end
            return ""
         end),
         i(1)
      }),

      snpta("array", "b Ce A", [[
         \begin{array}{<>}
           <>
         \end{array}
         ]], { i(1), i(0) }),
   }),
}

-- vim: set expandtab:
