# QWEN.md — Agent Guide for argrule

This file is written for coding agents working on this repository. Keep it current when project direction, public API decisions, CI policy, or documentation rules change.

## Project Identity

`argrule` is a Lua function signature layer. It normalizes arguments, fills defaults, validates contracts, and renders usage text for Lua functions.

It is **not**:

- a full static type system
- a command-line parser
- a migration-compatibility clone of any older argument checker
- an application-framework integration layer

The repository must stay framework-neutral. Consuming projects define their own local contracts from their own classes, predicates, or callable type objects.

## Supported Lua Targets

Support these runtimes unless a future project decision explicitly changes the matrix:

- Lua 5.1
- Lua 5.2
- Lua 5.3
- Lua 5.4
- LuaJIT

Prefer Lua 5.1-compatible syntax and APIs. When standard-library names differ across Lua versions, use small compatibility shims, e.g. `table.unpack or unpack`.

## Repository Layout

- `lua/argrule/` contains published Lua modules.
- `spec/` contains busted specs.
- `docs/` contains design notes and feature comparisons.
- `README.md` is the default English README.
- `README.zh-CN.md` and `README.zh-TW.md` are localized READMEs.
- `argrule-scm-1.rockspec` is the current development LuaRocks package spec.

Keep the `lua/` source root. It separates publishable modules from tests, docs, CI, and repository metadata.

## Public Modules

The public module surface is intentionally small:

```lua
local argrule = require "argrule"
local rule = require "argrule.rule"
```

The root module owns contracts and introspection. `argrule.rule` owns rule parsing and function wrapping.

Do not add public modules casually. If a new public module is necessary, update the rockspec, docs, tests, and this file.

## Module Style

Lua source modules should follow this shape:

```lua
local M = {}

function M.public_name(...)
  ...
end

return M
```

Attach public symbols as `M.xxx`. Do not return a bare function from source modules. Keep module exports easy to copy, inspect, and extend.

Internal metatable use is allowed for library mechanics such as contracts and weak metadata tables. User-facing examples and consuming-project style should avoid explicit class construction through hand-written metatables.

## Penlight Class Policy

User-facing class examples should use Penlight `class()` style:

```lua
local class = require "pl.class"

local Vector = class()

function Vector:_init(values)
  self.values = values
end

local vector = Vector { "a", "b" }
```

Avoid examples that ask users to manually write `setmetatable(...)` to build classes or objects. Use explicit metatables only inside low-level library internals or narrowly targeted internal tests.

Contract matching should support Penlight class shapes and inheritance, including `is_a`, `_class`, `_base`, `_parent`, and `_parent_with_init` where relevant.

## Contract Design

Contracts are local values, not global registrations. Prefer short local aliases near the API being defined:

```lua
local alias = argrule.alias
local Union = argrule.Union
local Optional = argrule.Optional
local List = argrule.List
local number = argrule.number
local string = argrule.string

local Tensor = alias { HostTensor }
local Scalar = Union { number, string }
local MaybeTensor = Optional { Tensor }
local Shape = List { number }
```

Supported contract forms include:

- builtins: `any`, `Nil`, `nil`, `boolean`, `number`, `string`, `table`, `userdata`, `thread`, `func`, `function`
- `Callable` and `Callable {}`
- `alias { T }`
- `Union { ... }`
- `Optional { T }`
- `List { T }`
- `Tuple { ... }`
- `Dict { K, V }`
- `Literal { ... }`
- callable predicates
- host class/type objects

Constructor inputs must be contiguous array-like tables. Reject keyed constructor option tables. Keep names readable through `tostring(contract)` and `argrule.type_name(contract)`.

## Rule Semantics

Rule tables should support these fields:

- `name`
- `type`
- `doc` / `help`
- `default`
- `defaulta`
- `defaultf`
- `opt`
- `check`
- top-level `call`

Supported call forms:

```lua
f(a, b)
f { a = a, b = b }
f { a, b }
f { a, b = b }
```

Reject trailing options-table APIs such as:

```lua
f(a, { b = b })
```

The preferred named-table style is the single-table form.

## Method Semantics

There is no separate public method API.

If the first rule is named `self`, the ordinary `rule` wrapper treats the function as method-capable:

```lua
M.deposit = rule {
  { name = "self", type = Account },
  { name = "amount", type = number },
  { name = "fee", type = number, default = 0 },
}(function(self, amount, fee)
  ...
end)
```

Then:

```lua
account:deposit { 100, fee = 2 }
```

is normalized as if it were:

```lua
account.deposit { self = account, amount = 100, fee = 2 }
```

If the first rule is not named `self`, treat the wrapper as an ordinary function.

## Parsing Policy

When a single plain table is passed:

1. If any key is a rule name, parse mixed named-table mode.
2. Otherwise try table-position mode.
3. Otherwise, if rule #1 accepts the whole table and all other required arguments are satisfied, use the table as argument #1.
4. Otherwise report the table-position error.

Keep this deterministic parser as the baseline. Do not add broad generated dispatch unless profiling proves a real bottleneck and the generated path remains debuggable.

## Redlines

Do not add:

- global type registries
- public `register` APIs
- public `quiet` mode
- migration-only compatibility surfaces
- a separate public method wrapper
- trailing options-table examples
- application-framework-specific branches, names, or special cases
- generated 3^N overload enumeration
- generated fast paths without profiling evidence and clear debugging support

Partial overload support may be considered later, but it should be explicit, small, and well-tested rather than a broad compatibility clone.

## Documentation Policy

README defaults to English. Keep Simplified Chinese and Traditional Chinese README files in sync for user-facing setup, feature, and example sections.

Before claiming a package is installable through a package registry, verify it has actually been published there. Until release, document checkout-based installation:

```bash
git clone https://github.com/PlumBlossomMaid/argrule.git
cd argrule
luarocks make argrule-scm-1.rockspec
```

Examples should use Penlight `class()` for classes. Do not show manual user-side metatable construction in README examples.

## Testing Policy

Use busted as the only Lua test runner.

Local verification commands in this environment:

```bash
LUA_PATH="./lua/?.lua;./lua/?/init.lua;./spec/?.lua;;" /workspace/local/luarocks51/bin/busted
LUA_PATH="./lua/?.lua;./lua/?/init.lua;./spec/?.lua;;" /workspace/local/luarocksjit/bin/busted
/workspace/local/luarocks51/bin/luarocks lint argrule-scm-1.rockspec
/workspace/local/bin/luac5.1 -p lua/argrule/*.lua spec/*.lua
pre-commit run --all-files
```

When changing behavior, add or update busted specs. Do not rely only on README examples.

## CI Policy

GitHub Actions should cover Lua 5.1, 5.2, 5.3, 5.4, and LuaJIT.

LuaJIT on GitHub Actions has two known constraints:

- the default LuaRocks manifest can exceed LuaJIT's function constant limit
- the LuaJIT setup may not provide `luac`

Therefore the CI currently installs LuaJIT busted dependencies through pinned direct rock URLs with `--deps-mode=none`, and the syntax-check step falls back to `loadfile(...)` when `luac` is unavailable.

Keep the framework-hardcode guard active across source, specs, READMEs, docs, and rockspec metadata.

## Formatting Policy

Use StyLua through pre-commit. Current style:

- two-space indentation
- `quote_style = "AutoPreferDouble"`
- `call_parentheses = "None"`
- `column_width = 100`

Do not manually reformat unrelated files unless required by the formatter for the current change.

## Release Notes

The current rockspec version is `scm-1`, meaning a source-control development version and rockspec revision 1. For a first real release, switch to a versioned rockspec such as `0.1.0-1` only when the package is actually ready to publish.
