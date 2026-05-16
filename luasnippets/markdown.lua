local luasnip = require("luasnip")
local luasnippy = require("luasnippy")

local i = luasnip.insert_node

local context = luasnippy.context
local make_condition = luasnippy.make_condition
local pack_snippets = luasnippy.pack_snippets
local snpt = luasnippy.snpt

local function is_in_math()
   local node = vim.treesitter.get_node({
      ignore_injections = false
   })
   if not node then return false end
   return vim.list_contains({
      "latex_block", "latex_span_delimiter",
   }, node:type())
end
local is_in_math_cond = make_condition(is_in_math)

local Unicode_snippets = (function(command_map)
   local snippets = {}
   for lhs, rhs in pairs(command_map) do
      table.insert(snippets, snpt("\\" .. lhs, "i", rhs, {}))
   end
   return snippets
end)({
   -- to greek
   a = 'α', b = 'β', c = 'χ', d = 'δ', e = 'ε', f = 'φ', g = 'γ',
   h = 'η', i = 'ι', k = 'κ', l = 'λ', m = 'μ', n = 'ν', o = 'ο',
   p = 'π', q = 'θ', r = 'ρ', s = 'σ', t = 'τ', u = 'υ', w = 'ω',
   x = 'ξ', y = 'ψ', z = 'ζ',
   B = 'Β', C = 'Χ', D = 'Δ', F = 'Φ', G = 'Γ',
   H = 'Η', I = 'Ι', K = 'Κ', L = 'Λ', M = 'Μ', N = 'Ν', O = 'Ο',
   P = 'Π', Q = 'Θ', R = 'Ρ', S = 'Σ', T = 'Τ', U = 'Υ', W = 'Ω',
   X = 'Ξ', Y = 'Ψ', Z = 'Ζ',
   ve = '𝜀', vf = '𝜑', vk = '𝜘', vp = '𝜛', vq = '𝜗', vr = '𝜚',
   -- math notations
   A = '∀', E = '∃', ['.'] = '⋅', ['8'] = '∞', ['~'] = '≈',
   ['['] = '⊆', [']'] = '⊇',
   -- math commands
   cup = '∪', cap = '∩', ["in"] = '∈',
   land = '∧', lor = '∨', pp = '∥',
   pm = '±', ne = '≠', le = '≤', ge = '≥',
})

return pack_snippets {
   context(-is_in_math_cond, {
      snpt("mk", "A", "${}$", { i(1) }),
      snpt("dm", "A", "$$\n\t{}\n$$", { i(1) }),
   }),
   context(is_in_math_cond, {
      luasnippy.math_snippets(),
      Unicode_snippets,
      snpt("-> ", "iA", "→", {}),
      snpt("<- ", "iA", "←", {}),
   }),
}
