# luasnippy.nvim

A more ergonomic snippet facility wrapping LuaSnip, with tex and Markdown snippets.

# Rationale

Snippets are powerful, but to utilize them maximally, one should write his own snippets. Otherwise it’s more a LSP thing.

[LuaSnip](https://github.com/L3MON4D3/LuaSnip) has provided a good mechanism for *computers* to implement the snippet functionality, by structuring all information in Lua tables and breaking up the snippet into nodes. However, writing snippets directly in LuaSnip requires a lot of boilerplate. I really miss the neat format of UltiSnips.

luasnippy.nvim aims to bring back the ergonomic way of snippets’ definition. An example should help illustrate this:

```lua
return pack_snippets {
   snpta("beg", "b Ce A", [[
      \begin{<>}
        <>
      \end{<>}
      ]], { i(1), i(0), extras.rep(1) }),
   context(is_in_math, {
      snpta("//", "iA P500", "\\frac{<>}{<>}", { i(1), i(2) }),
      snpta("bar", "iRv P500", "\\overline{<>}", { i(1) }),
   }),
}
```

+ Grouping snippets by conditions (contexts)
+ Short-hand syntax for context options
+ Intuitive format-string syntax

# Installation

You can use any of the plugin manager, or `git clone` this repo and add it to your `'rtp'`. For example, install by *lazy.nvim*:

TODO.

# Usage

## Snippet

The main functionality of this plugin is provided in:

```lua
luasnippy.snpt(trigger, context, body_str, body_elems, opts)
```

Normally the second argument of `snpt` is a string, with a similar syntax to UltiSnips, specifying the context of the snippet.

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

The first argument is the trigger word. The last two arguments form a f-string in Python (for those who are unfamiliar, it’s like string interpolation in shell), as is illustrated by the example above.

The last argument can further regulate the behaviour of the string formatting, see `opts` in `:h luasnip-extras-fmt`.

A variant that uses angular brackets `<>` for string formatting instead of `{}` is provided:

```lua
luasnippy.snpta(trigger, context, body_str, body_elems, opts)
```

## Conditional

```lua
luasnippy.context(cond, snippets)
```

Conditions apply to all snippets in its scope, which makes it very easy to write now. `context` accepts a function or a condition object (see `CONDITION OBJECTS` in `:h luasnip-extras-conditions`), and applies it to the snippets in the second argument.

Nesting is supported. For example:

```lua
   context(-is_in_math_cond, {
      context(function() return is_in_env("description") end, {
         snpt("  - ", "b Ce A", "\\item [{}] {}", { i(1), i(0) })
      }),
   }
```

## Backend

LuaSnip is the “backend” of the plugin. The function `pack_snippets` can “compile” LuaSnippy-style snippets:

```lua
luasnippy.pack_snippets(snippet_tuples)
```

To maximally reduce the need to struggle with LuaSnip docs, some helper functions are provided:

+ `luasnippy.make_condition({fn})`: makes a condition object. Alias of

   ```lua
   require("luasnip.extras.conditions").make_condition(fn)
   ```

+ `luasnippy.capture_extract({indice})`: returns a function that can be used in function-node to extract a indexed capture. Example:

   ```lua
   snpt([=[\([a-zA-Z\u0370-\u03ff]\)\(\d\)]=], "Rv iA",
      "{}_{}", { f(capture_extract(1)), f(capture_extract(2)) }),
   ```

# Examples

See `luasnippets/tex.lua` for some powerful snippets, especially:

+ `__`: copy the multi-letter subscript from the nearest identical entity.

The snippets can be loaded by:

```lua
require("luasnip.loaders.from_lua").lazy_load()
```

Since the plugin folder is added to `'rtp'`, you don't have to specify the path.

