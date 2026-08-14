# argrule

`argrule` is a Lua function signature layer for Lua 5.1, Lua 5.2, Lua 5.3, Lua 5.4, and LuaJIT.
Its implementation is Lua source, while dependencies may include Lua rocks backed by C modules, such as Penlight's LuaFileSystem dependency.
It is framework-neutral: one rule table supports positional calls and Python-like named table calls without embedding any application framework.

## Scope

- Keep the argcheck-style rule table shape: `name`, `type`, `doc`, `default`, `defaulta`, `defaultf`, `opt`, `check`.
- Support `f(a, b)`, `f{a = a, b = b}`, `f{a, b}`, and mixed calls like `f{x, axis = 1}`.
- Treat first argument named `self` as class-method syntax, so `a:m{arg}` is normalized like `a.m{self = a, arg}`.
- Reject trailing options-table APIs such as `f(x, {axis = 1})`; the correct form is `f{x, axis = 1}`.
- Treat `type` as a callable contract: builtins, `alias{...}`, `Union{...}`, `Optional{...}`, `List{...}`, `Tuple{...}`, `Dict{...}`, `Literal{...}`, `Callable`, predicates, or callable type objects.
- Keep framework names out of this repository; applications define local contracts from their own classes or predicates.
- Track upstream argcheck feature differences in `docs/argcheck-comparison.md`.

## Quick Example

```lua
local rule = require "argrule.rule"
local argrule = require "argrule"

local alias = argrule.alias
local List = argrule.List
local number = argrule.number

local VectorClass = { __name = "Vector" }
local Vector = alias { VectorClass }
local IntList = List { number }

local pick = rule {
  { name = "x", type = Vector, doc = "input vector" },
  { name = "index", type = number, default = 1, doc = "1-based index" },
  doc = "Pick a value from a vector-like object.",
}(function(x, index)
  return x[index]
end)

pick { setmetatable({ "a", "b" }, { __index = VectorClass }), index = 2 }
```

## Method Example

```lua
local Account = alias { AccountClass }

AccountClass.deposit = rule {
  { name = "self", type = Account },
  { name = "amount", type = number },
  { name = "fee", type = number, default = 0 },
}(function(self, amount, fee)
  self.balance = self.balance + amount - fee
  return self.balance
end)

account:deposit { 100, fee = 2 }
```

## Development

Use busted as the only Lua test runner. With the local runtimes and rocks installed under `/workspace/local`, run:

```bash
LUA_PATH="./lua/?.lua;./lua/?/init.lua;./spec/?.lua;;" /workspace/local/luarocks51/bin/busted
LUA_PATH="./lua/?.lua;./lua/?/init.lua;./spec/?.lua;;" /workspace/local/luarocksjit/bin/busted
```

Formatting and local checks are available through pre-commit:

```bash
pre-commit run --all-files
```

The current repository is the bootstrap skeleton. The next implementation steps are overload design, Penlight-backed pretty usage rendering, and a large-argument regression fixture.
