local luasnippy = require("luasnippy")

local snpt = luasnippy.snpt
local context = luasnippy.context
local pack_snippets = luasnippy.pack_snippets

local function is_in_math()
   local node = vim.treesitter.get_node({
      ignore_injections = false
   })
   if not node then return false end
   return vim.list_contains({ "latex_block" }, node:type())
end

local latin_to_greek_snippets = (function(latin_to_greek)
   local snippets = {}
   for lhs, rhs in pairs(latin_to_greek) do
      table.insert(snippets, snpt("\\" .. lhs, "i", rhs, {}))
   end
   return snippets
end)({
   a = 'α', b = 'β', c = 'χ', d = 'δ', e = 'ε', f = 'φ', g = 'γ',
   h = 'η', i = 'ι', k = 'κ', l = 'λ', m = 'μ', n = 'ν', o = 'ο',
   p = 'π', q = 'θ', r = 'ρ', s = 'σ', t = 'τ', u = 'υ', w = 'ω',
   x = 'ξ', y = 'ψ', z = 'ζ',
   A = 'Α', B = 'Β', C = 'Χ', D = 'Δ', E = 'Ε', F = 'Φ', G = 'Γ',
   H = 'Η', I = 'Ι', K = 'Κ', L = 'Λ', M = 'Μ', N = 'Ν', O = 'Ο',
   P = 'Π', Q = 'Θ', R = 'Ρ', S = 'Σ', T = 'Τ', U = 'Υ', W = 'Ω',
   X = 'Ξ', Y = 'Ψ', Z = 'Ζ',
   ve = '𝜀', vf = '𝜑', vk = '𝜘', vp = '𝜛', vq = '𝜗', vr = '𝜚',
})

return pack_snippets {
   context(is_in_math, {
      require("luasnippy.math_snippets"),
      latin_to_greek_snippets,
      snpt("-> ", "i", "→", {}),
   })
}
