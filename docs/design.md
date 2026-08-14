# argrule design

## Positioning

`argrule` is a function signature layer, not a type system and not a CLI parser. It normalizes arguments, fills defaults, validates contracts, and renders usage text.

## Public modules

```lua
local rule = require "argrule.rule"
local argrule = require "argrule"
```

`rule{...}(fn)` validates ordinary functions and methods. The root module owns contract constructors and introspection.

## Contracts

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

`alias{...}` accepts exactly one array element and returns a callable contract. It is the common bridge from a Penlight class, host class, callable type object, or predicate into argrule.

`Union{...}` accepts one or more array elements and returns a contract that accepts any member contract. Constructor tables must be contiguous array-like tables; keyed option tables are rejected.

`Optional{T}` is `Union{T, Nil}`. `List{T}` checks array-like containers. `Tuple{...}` checks fixed-length positional containers. `Dict{K, V}` checks table keys and values. `Literal{...}` accepts exact literal values. `Callable` and `Callable{}` check functions and `__call` objects.

## Penlight class policy

Class and inheritance checks follow the Penlight class shape first: instances are accepted when their metatable/class chain matches the contract target, including `_class`, `_base`, `_parent`, `_parent_with_init`, and `is_a` when present.

## Rule fields

| Field | Meaning |
|---|---|
| `name` | Argument name and named-table key |
| `type` | Contract: builtin contract, `alias{...}`, `Union{...}`, `Optional{...}`, `List{...}`, `Tuple{...}`, `Dict{...}`, `Literal{...}`, `Callable`, predicate, or callable type object |
| `doc` / `help` | Usage text |
| `default` | Constant default |
| `defaulta` | Default from another argument |
| `defaultf` | Function default evaluated per call |
| `opt` | Optional without default |
| `check` | Additional value check |
| `call` | Optional implementation function placed directly in the spec |

## Call forms

| Form | Status |
|---|---|
| `f(a, b)` | valid positional call |
| `f{a = a, b = b}` | valid named-table call |
| `f{a, b}` | valid table-position call |
| `f{a, b = b}` | valid mixed-table call and preferred named-table documentation style |
| `f(a, {b = b})` | invalid trailing options table |

## Self and method calls

There is no separate method API. If the first rule is named `self`, argrule treats the function as method-capable:

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

is normalized like:

```lua
account.deposit { self = account, amount = 100, fee = 2 }
```

and finally calls:

```lua
fn(account, 100, 2)
```

If the first rule is not named `self`, the function is treated as an ordinary function.

## Deterministic table parsing

When a single un-metatabled table is passed:

1. If any key is a rule name, parse mixed named-table mode.
2. Otherwise try table-position mode.
3. Otherwise, if rule #1 accepts the whole table and every other required argument is satisfied, use the whole table as argument #1.
4. Otherwise report the table-position error.

This keeps `zeros{2, 3}` usable as one `shape` argument without adding a special `sizeargs` branch.

## Repository redlines

- No application-framework hardcoding in `lua/` or docs; framework-specific contracts are local values built by consuming projects.
- Lua-source implementation does not forbid dependencies or indirect dependencies backed by C modules.
- No migration-compatibility surface solely for upstream argcheck compatibility.
- No public `quiet` mode; invalid public API calls should fail loudly.
- No separate `method` API; self-aware methods are expressed with a first rule named `self`.
- No 3^N overload enumeration.
- No generated fast path unless profiling proves the deterministic parser is a bottleneck and the generated path remains debuggable.
- No trailing options-table examples in docs.

## argcheck feature comparison

See `docs/argcheck-comparison.md` for the current upstream argcheck feature comparison and argrule-specific decisions.

## Bootstrap status

The initial implementation is an interpreted O(N) path so the repository can self-test on Lua 5.1 and LuaJIT immediately. Keep this path as the baseline; only add generated dispatch after profiling shows it is necessary and easy to debug.
