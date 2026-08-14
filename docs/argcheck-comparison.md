# argcheck comparison

Compared against upstream argcheck at `/plum/argcheck` commit `b3b32c0`.

## Supported now

| Feature | argcheck | argrule status |
|---|---|---|
| Rule table with `name` / `type` | Yes | Yes |
| `help` / `doc` text | Yes | Yes; normalized into usage docs |
| Constant `default` | Yes | Yes |
| `defaulta` from another argument | Yes | Yes |
| `defaultf` dynamic default | Yes | Yes |
| `opt=true` nil optional argument | Yes | Yes |
| Per-rule `check=function(...)` | Yes | Yes |
| Positional calls | Yes | Yes |
| Named table calls | Yes | Yes |
| Named method calls | Yes, by first rule named `self` | Yes, through ordinary `rule` when first argument is named `self` |
| `nonamed` / `noordered` | Yes | Yes |
| Custom type checking | Override `argcheck.env.istype` | Local contracts: builtins, `alias{...}`, `Union{...}`, `Optional{...}`, `List{...}`, `Tuple{...}`, `Dict{...}`, `Literal{...}`, `Callable`, predicates, and callable type objects |
| `call = function(...) ... end` inside the rule spec | Yes | Yes |

## Intentionally different

| argcheck behavior | argrule decision |
|---|---|
| Optional legacy framework integration in `argcheck.env` | No application-framework integration in argrule; consumers build local contracts from their own classes/predicates |
| Global type-name registry | No registry; use local contract values like `local Tensor = alias{HostTensor}` |
| Separate method helper | No separate method API; a first rule named `self` enables method-style normalization |
| Tail table method calls like `object:fn{x=...}` | Supported, but argrule also supports mixed table calls like `fn{x, axis = 1}` |
| Ordered and named variants are generated from 3^N paths | argrule uses deterministic parsing; generated fast paths are not planned unless profiling shows a real bottleneck |

## Missing or deferred

| Feature | Why it matters | Current decision |
|---|---|---|
| Partial `overload` | Multi-signature dispatch can be useful for APIs with genuinely different shapes | Consider a small explicit variant API; do not copy deprecated `chain` or broad migration compatibility |
| `force = true` | Allows overriding ambiguity checks in overload graphs | Only relevant if partial overload is added; prefer explicit ambiguity errors over silent priority rules |
| Combined usage output for overloaded signatures | Helps users see all accepted forms | Consider with partial overload |
| `pack = true` return table | Helpful when consuming many normalized args as one table | Not planned as the default style; long public APIs should keep one explicit parameter list for readability |

## Not planned

| Feature | Reason |
|---|---|
| `quiet=true` | It is a non-throwing checker mode for manual dispatch; argrule should fail loudly for invalid public API calls unless a future overload dispatcher needs internal non-throwing probes |
| Deprecated `chain` | Migration compatibility is not a goal |
| Exact argcheck checker mode | Migration compatibility is not a goal; `rule{...}(fn)` and `call` cover new code |
| `debug=true` generated-code dump and dot graph | There is no generated checker path to inspect |
| Generated fast path | argrule's deterministic parser is simpler; defer unless profiling shows this is necessary and the generated path remains debuggable |

## Redline

argrule must remain a framework-neutral Lua-source library. It may depend on Lua rocks whose implementation uses C modules, such as Penlight depending on LuaFileSystem, but it must not hardcode application frameworks or type systems. Framework-specific contracts belong in the consuming project as local values built with `argrule.alias`, `argrule.Union`, `argrule.Optional`, `argrule.List`, `argrule.Tuple`, `argrule.Dict`, `argrule.Literal`, `argrule.Callable`, builtins, predicates, or callable type objects.
