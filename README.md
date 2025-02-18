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

Last note: as for API reference, I am struggling to find a good documentation generator that supports exporting functions by `return`-ing at the end of the file (which excludes vimCATS). If you have any suggestion, please let me know. Thanks!

