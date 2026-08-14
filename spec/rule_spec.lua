local helper = require "spec_helper"
local rule = require "argrule.rule"
local argrule = require "argrule"

local alias = argrule.alias
local Union = argrule.Union
local Optional = argrule.Optional
local List = argrule.List
local Literal = argrule.Literal
local number = argrule.number
local str = argrule.string

local VectorClass = { __name = "Vector" }
local Vector = alias { VectorClass }
local Int = alias {
  function(o)
    return type(o) == "number" and math.floor(o) == o
  end,
}
local IntList = List { Int }
local MaybeString = Optional { str }
local Mode = Literal { "train", "eval" }

local function vector(...)
  return setmetatable({ ... }, { __index = VectorClass })
end

describe("argrule.rule", function()
  it("supports positional, named-table, table-position, mixed-table, and default calls", function()
    local add = rule {
      { name = "a", type = number, doc = "left" },
      { name = "b", type = number, default = 10, doc = "right" },
      doc = "Add two numbers.",
    }(function(a, b)
      return a + b
    end)

    assert.are.equal(3, add(1, 2))
    assert.are.equal(3, add { a = 1, b = 2 })
    assert.are.equal(3, add { 1, 2 })
    assert.are.equal(3, add { 1, b = 2 })
    assert.are.equal(15, add(5))
    helper.has_error_containing(function()
      add "x"
    end, "bad argument #1")
    assert.is_truthy(argrule.usage(add):find("Add two numbers", 1, true))
  end)

  it("supports local alias contracts and rejects trailing options tables", function()
    local pick = rule {
      { name = "x", type = Vector },
      { name = "index", type = number, default = 1 },
    }(function(x, index)
      return x[index]
    end)

    assert.are.equal("b", pick { vector("a", "b"), index = 2 })
    helper.has_error_containing(function()
      pick(vector("a", "b"), { index = 2 })
    end, "bad argument #2")
  end)

  it("treats a table as the first argument when the first rule accepts the whole table", function()
    local zeros = rule {
      { name = "shape", type = IntList },
      { name = "dtype", type = str, default = "float32" },
    }(function(shape, dtype)
      return #shape, dtype
    end)

    local rank, dtype = zeros { 2, 3 }
    assert.are.equal(2, rank)
    assert.are.equal("float32", dtype)
    helper.has_error_containing(function()
      zeros(2, 3)
    end, "bad argument #1")
  end)

  it("supports defaulta, defaultf, opt, help, and check fields", function()
    local next_default = 0
    local normalize = rule {
      help = "Normalize a value.",
      {
        name = "x",
        type = number,
        check = function(x)
          return x >= 0
        end,
      },
      { name = "scale", type = number, defaulta = "x" },
      {
        name = "offset",
        type = number,
        defaultf = function()
          next_default = next_default + 1
          return next_default
        end,
      },
      { name = "label", type = MaybeString, opt = true },
      { name = "mode", type = Mode, default = "train" },
    }(function(x, scale, offset, label, mode)
      return x, scale, offset, label, mode
    end)

    local x, scale, offset, label, mode = normalize(3)
    assert.are.equal(3, x)
    assert.are.equal(3, scale)
    assert.are.equal(1, offset)
    assert.is_nil(label)
    assert.are.equal("train", mode)

    x, scale, offset, label, mode = normalize { x = 4, label = "ok", mode = "eval" }
    assert.are.equal(4, x)
    assert.are.equal(4, scale)
    assert.are.equal(2, offset)
    assert.are.equal("ok", label)
    assert.are.equal("eval", mode)

    helper.has_error_containing(function()
      normalize(-1)
    end, "bad argument #1")
    helper.has_error_containing(function()
      normalize { x = 1, mode = "bad" }
    end, "bad argument #5")
    assert.is_truthy(argrule.usage(normalize):find("Normalize a value", 1, true))
  end)

  it("supports direct call syntax through spec.call", function()
    local inc = rule {
      { name = "x", type = number },
      call = function(x)
        return x + 1
      end,
    }

    assert.are.equal(4, inc(3))
    helper.has_error_containing(function()
      inc "x"
    end, "bad argument #1")
  end)

  it("supports noordered and nonamed", function()
    local named_only = rule {
      noordered = true,
      { name = "x", type = number },
    }(function(x)
      return x
    end)

    assert.are.equal(7, named_only { x = 7 })
    helper.has_error_containing(function()
      named_only(7)
    end, "positional calls are disabled")

    local ordered_only = rule {
      nonamed = true,
      { name = "x", type = number },
    }(function(x)
      return x
    end)

    assert.are.equal(8, ordered_only(8))
    helper.has_error_containing(function()
      ordered_only { x = 8 }
    end, "named-table calls are disabled")
  end)

  it("treats first self rule as method syntax", function()
    local AccountClass = { __name = "Account" }
    local Account = alias { AccountClass }

    local account = setmetatable({ balance = 10 }, { __index = AccountClass })
    AccountClass.deposit = rule {
      { name = "self", type = Account },
      { name = "amount", type = number },
      { name = "fee", type = number, default = 0 },
    }(function(self, amount, fee)
      self.balance = self.balance + amount - fee
      return self.balance
    end)

    assert.are.equal(14, account:deposit { 5, fee = 1 })
    assert.are.equal(20, account:deposit(6))
    assert.are.equal(23, account.deposit { self = account, amount = 3 })
    helper.has_error_containing(function()
      account:deposit { self = account, 1 }
    end, "argument 'self' was given twice")
  end)
end)
