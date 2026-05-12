local luasnip = require("luasnip")
local luasnippy = require("luasnippy")

local f = luasnip.function_node
local i = luasnip.insert_node

local capture_extract = luasnippy.capture_extract
local snpt = luasnippy.snpt
local snpta = luasnippy.snpta

local capturee1 = capture_extract(1)
local capturee2 = capture_extract(2)

---@module "luasnippy"
---@type SnippetTuple[]
return {
   snpt([=[\([a-zA-Z\u0370-\u03ff]\)\(\d\)]=], "Rv iA",
      "{}_{}", { f(capturee1), f(capturee2) }),
   snpta([=[\([a-zA-Z\u0370-\u03ff]\)_\(\d\d\)]=], "Rv iA",
      "<>_{<>}", { f(capturee1), f(capturee2) }),
   snpt("(%S)sr", "irA",
      "{}^2", { f(capturee1) }),
   snpt("(%S)%^2(%d)", "irA",
      "{}^{}", { f(capturee1), f(capturee2) }),
   snpta("//", "iA P500",
      "\\frac{<>}{<>}", { i(1), i(2) }),
   snpta([=[\(\d\+\|\d*\%(\%(\\\)\?\a\+\|[\u0370-\u03ff]\)\)/]=], "Rv A",
      "\\frac{<>}{<>}", { f(capturee1), i(1) }),
}
