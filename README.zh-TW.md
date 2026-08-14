[![Lua](https://img.shields.io/badge/lua-5.1%20%7C%205.2%20%7C%205.3%20%7C%205.4%20%7C%20LuaJIT-blue.svg)]()
[![CI](https://github.com/PlumBlossomMaid/argrule/actions/workflows/ci.yml/badge.svg)](https://github.com/PlumBlossomMaid/argrule/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

[![EN](https://img.shields.io/badge/lang-EN-red.svg)](README.md)
[![简体中文](https://img.shields.io/badge/lang-简体中文-blue.svg)](README.zh-CN.md)
[![繁體中文](https://img.shields.io/badge/lang-繁體中文-green.svg)](README.zh-TW.md)

# argrule

**Lua 函式參數歸一化、預設值填補和契約校驗庫**

`argrule` 是面向 Lua 5.1、Lua 5.2、Lua 5.3、Lua 5.4 和 LuaJIT 的函式簽名層。
主體實作是 Lua 原始碼，同時允許依賴由 C 模組支撐的 Lua rocks，例如 Penlight 間接依賴的 LuaFileSystem。
它是框架無關的：一個 rule 表同時支援位置參數呼叫和接近 Python 風格的命名表呼叫，不在庫內嵌入任何應用框架。

---

## 為什麼使用 argrule？

Lua API 經常需要同時支援緊湊的位置參數、可讀的命名參數、預設值和自訂型別檢查。`argrule` 把這些邏輯放在函式定義附近，讓函式庫程式碼可以接受多種呼叫風格，而不需要在每個函式裡手寫參數解析。

---

## 功能

| 類別 | 覆蓋 |
|------|------|
| **呼叫形式** | `f(a, b)`、`f{a = a, b = b}`、`f{a, b}`、`f{x, axis = 1}` |
| **Rule 欄位** | `name`、`type`、`doc`、`help`、`default`、`defaulta`、`defaultf`、`opt`、`check`、`call` |
| **契約型別** | 內建型別、`alias{...}`、`Union{...}`、`Optional{...}`、`List{...}`、`Tuple{...}`、`Dict{...}`、`Literal{...}`、`Callable` |
| **類別方法** | 首個 rule 名為 `self` 時啟用 `object:method{...}` 歸一化 |
| **類別檢查** | 支援 Penlight 風格的類別和繼承形態 |
| **診斷資訊** | 校驗失敗時附帶 usage 文字 |
| **CI** | Lua 5.1、5.2、5.3、5.4、LuaJIT、busted、LuaRocks lint、StyLua |

---

## 快速開始

`argrule` 還沒有發布到 LuaRocks。現在請從倉庫 checkout 安裝：

```bash
git clone https://github.com/PlumBlossomMaid/argrule.git
cd argrule
luarocks make argrule-scm-1.rockspec
```

本地開發時，可以直接使用原始碼樹：

```bash
LUA_PATH="./lua/?.lua;./lua/?/init.lua;;" lua your_script.lua
```

---

## 快速範例

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

## 類別方法範例

如果首個 rule 名為 `self`，包裝後的函式會接受類別方法語法：

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

上面的呼叫會被歸一化為：

```lua
account.deposit { self = account, amount = 100, fee = 2 }
```

---

## 專案結構

```
argrule/
├── lua/argrule/              發布的 Lua 模組
│   ├── init.lua              契約建構器和根模組
│   ├── rule.lua              Rule 解析器和函式包裝器
│   ├── _state.lua            內部元資料狀態
│   └── _usage.lua            Usage 文字渲染
├── spec/                     busted 測試
├── docs/                     設計說明和功能對比
├── .github/workflows/        GitHub Actions CI
├── .pre-commit-config.yaml   StyLua 和本地驗證 hooks
└── argrule-scm-1.rockspec    LuaRocks 套件規格檔
```

---

## 開發

統一使用 busted 作為 Lua 測試執行器。本地 Lua 執行時和 rocks 安裝在 `/workspace/local` 時，執行：

```bash
LUA_PATH="./lua/?.lua;./lua/?/init.lua;./spec/?.lua;;" /workspace/local/luarocks51/bin/busted
LUA_PATH="./lua/?.lua;./lua/?/init.lua;./spec/?.lua;;" /workspace/local/luarocksjit/bin/busted
```

格式化和本地檢查透過 pre-commit 執行：

```bash
pre-commit run --all-files
```

---

## 授權

MIT
