[![Lua](https://img.shields.io/badge/lua-5.1%20%7C%205.2%20%7C%205.3%20%7C%205.4%20%7C%20LuaJIT-blue.svg)]()
[![CI](https://github.com/PlumBlossomMaid/argrule/actions/workflows/ci.yml/badge.svg)](https://github.com/PlumBlossomMaid/argrule/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

[![EN](https://img.shields.io/badge/lang-EN-red.svg)](README.md)
[![简体中文](https://img.shields.io/badge/lang-简体中文-blue.svg)](README.zh-CN.md)
[![繁體中文](https://img.shields.io/badge/lang-繁體中文-green.svg)](README.zh-TW.md)

# argrule

**Lua function argument normalization, defaults, and contract validation**

`argrule` is a Lua function signature layer for Lua 5.1, Lua 5.2, Lua 5.3, Lua 5.4, and LuaJIT.
Its implementation is Lua source, while dependencies may include Lua rocks backed by C modules, such as Penlight's LuaFileSystem dependency.
It is framework-neutral: one rule table supports positional calls and Python-like named table calls without embedding any application framework.

---

## Why argrule?

Lua APIs often need to support compact positional calls, readable named calls, defaults, and custom type checks at the same time. `argrule` keeps that logic close to the function definition, so library code can accept multiple call styles without hand-written argument parsing in every function.

---

## Features

| Category | Coverage |
|----------|----------|
| **Call forms** | `f(a, b)`, `f{a = a, b = b}`, `f{a, b}`, `f{x, axis = 1}` |
| **Rule fields** | `name`, `type`, `doc`, `help`, `default`, `defaulta`, `defaultf`, `opt`, `check`, `call` |
| **Contracts** | Builtins, `alias{...}`, `Union{...}`, `Optional{...}`, `List{...}`, `Tuple{...}`, `Dict{...}`, `Literal{...}`, `Callable` |
| **Methods** | First rule named `self` enables `object:method{...}` normalization |
| **Class checks** | Penlight-style class and inheritance shape support |
| **Diagnostics** | Usage text attached to validation failures |
| **CI** | Lua 5.1, 5.2, 5.3, 5.4, LuaJIT, busted, LuaRocks lint, StyLua |

---

## Quick Start

`argrule` is not published to LuaRocks yet. Install it from a checkout:

```bash
git clone https://github.com/PlumBlossomMaid/argrule.git
cd argrule
luarocks make argrule-scm-1.rockspec
```

During local development, use the source tree directly:

```bash
LUA_PATH="./lua/?.lua;./lua/?/init.lua;;" lua your_script.lua
```

---

## Quick Example

```lua
local rule = require "argrule.rule"
local argrule = require "argrule"
local class = require "pl.class"

local alias = argrule.alias
local number = argrule.number

local Vector = class()

function Vector:_init(values)
  self.values = values
end

function Vector:pick(index)
  return self.values[index]
end

local VectorContract = alias { Vector }

local pick = rule {
  { name = "x", type = VectorContract, doc = "input vector" },
  { name = "index", type = number, default = 1, doc = "1-based index" },
  doc = "Pick a value from a vector-like object.",
}(function(x, index)
  return x:pick(index)
end)

local vector = Vector { "a", "b" }

pick(vector, 2)
pick { vector, index = 2 }
```

---

## Method Example

If the first rule is named `self`, the wrapper accepts method syntax:

```lua
local Account = class()
local AccountContract = alias { Account }

function Account:_init(balance)
  self.balance = balance
end

Account.deposit = rule {
  { name = "self", type = AccountContract },
  { name = "amount", type = number },
  { name = "fee", type = number, default = 0 },
}(function(self, amount, fee)
  self.balance = self.balance + amount - fee
  return self.balance
end)

local account = Account(10)
account:deposit { 100, fee = 2 }
```

The call above is normalized like:

```lua
account.deposit { self = account, amount = 100, fee = 2 }
```

---

## Project Structure

```
argrule/
├── lua/argrule/              # Published Lua modules
│   ├── init.lua              # Contract constructors and root module
│   ├── rule.lua              # Rule parser and function wrapper
│   ├── _state.lua            # Internal metadata state
│   └── _usage.lua            # Usage text rendering
├── spec/                     # busted specs
├── docs/                     # Design notes and feature comparison
├── .github/workflows/        # GitHub Actions CI
├── .pre-commit-config.yaml   # StyLua and local verification hooks
└── argrule-scm-1.rockspec    # LuaRocks package specification
```

---

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

---

## License

MIT
