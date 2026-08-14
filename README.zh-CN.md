[![Lua](https://img.shields.io/badge/lua-5.1%20%7C%205.2%20%7C%205.3%20%7C%205.4%20%7C%20LuaJIT-blue.svg)]()
[![CI](https://github.com/PlumBlossomMaid/argrule/actions/workflows/ci.yml/badge.svg)](https://github.com/PlumBlossomMaid/argrule/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

[![EN](https://img.shields.io/badge/lang-EN-red.svg)](README.md)
[![简体中文](https://img.shields.io/badge/lang-简体中文-blue.svg)](README.zh-CN.md)
[![繁體中文](https://img.shields.io/badge/lang-繁體中文-green.svg)](README.zh-TW.md)

# argrule

**Lua 函数参数归一化、默认值填充和契约校验库**

`argrule` 是面向 Lua 5.1、Lua 5.2、Lua 5.3、Lua 5.4 和 LuaJIT 的函数签名层。
主体实现是 Lua 源码，同时允许依赖由 C 模块支撑的 Lua rocks，例如 Penlight 间接依赖的 LuaFileSystem。
它是框架无关的：一个 rule 表同时支持位置参数调用和接近 Python 风格的命名表调用，不在库内嵌入任何应用框架。

---

## 为什么使用 argrule？

Lua API 经常需要同时支持紧凑的位置参数、可读的命名参数、默认值和自定义类型检查。`argrule` 把这些逻辑放在函数定义附近，让库代码可以接受多种调用风格，而不需要在每个函数里手写参数解析。

---

## 功能

| 类别 | 覆盖 |
|------|------|
| **调用形式** | `f(a, b)`、`f{a = a, b = b}`、`f{a, b}`、`f{x, axis = 1}` |
| **Rule 字段** | `name`、`type`、`doc`、`help`、`default`、`defaulta`、`defaultf`、`opt`、`check`、`call` |
| **契约类型** | 内置类型、`alias{...}`、`Union{...}`、`Optional{...}`、`List{...}`、`Tuple{...}`、`Dict{...}`、`Literal{...}`、`Callable` |
| **类方法** | 首个 rule 名为 `self` 时启用 `object:method{...}` 归一化 |
| **类检查** | 支持 Penlight 风格的类和继承形态 |
| **诊断信息** | 校验失败时附带 usage 文本 |
| **CI** | Lua 5.1、5.2、5.3、5.4、LuaJIT、busted、LuaRocks lint、StyLua |

---

## 快速开始

```bash
luarocks install argrule
```

本地开发时，可以直接使用源码树：

```bash
LUA_PATH="./lua/?.lua;./lua/?/init.lua;;" lua your_script.lua
```

---

## 快速示例

```lua
local rule = require "argrule.rule"
local argrule = require "argrule"

local alias = argrule.alias
local number = argrule.number

local VectorClass = { __name = "Vector" }
local Vector = alias { VectorClass }

local pick = rule {
  { name = "x", type = Vector, doc = "input vector" },
  { name = "index", type = number, default = 1, doc = "1-based index" },
  doc = "Pick a value from a vector-like object.",
}(function(x, index)
  return x[index]
end)

local vector = setmetatable({ "a", "b" }, { __index = VectorClass })

pick(vector, 2)
pick { vector, index = 2 }
```

---

## 类方法示例

如果首个 rule 名为 `self`，包装后的函数会接受类方法语法：

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

上面的调用会被归一化为：

```lua
account.deposit { self = account, amount = 100, fee = 2 }
```

---

## 项目结构

```
argrule/
├── lua/argrule/              发布的 Lua 模块
│   ├── init.lua              契约构造器和根模块
│   ├── rule.lua              Rule 解析器和函数包装器
│   ├── _state.lua            内部元数据状态
│   └── _usage.lua            Usage 文本渲染
├── spec/                     busted 测试
├── docs/                     设计说明和功能对比
├── .github/workflows/        GitHub Actions CI
├── .pre-commit-config.yaml   StyLua 和本地验证 hooks
└── argrule-scm-1.rockspec    LuaRocks 包规格文件
```

---

## 开发

统一使用 busted 作为 Lua 测试运行器。本地 Lua 运行时和 rocks 安装在 `/workspace/local` 时，执行：

```bash
LUA_PATH="./lua/?.lua;./lua/?/init.lua;./spec/?.lua;;" /workspace/local/luarocks51/bin/busted
LUA_PATH="./lua/?.lua;./lua/?/init.lua;./spec/?.lua;;" /workspace/local/luarocksjit/bin/busted
```

格式化和本地检查通过 pre-commit 执行：

```bash
pre-commit run --all-files
```

---

## 许可证

MIT
