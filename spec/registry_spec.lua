local helper = require "spec_helper"
local argrule = require "argrule"

local alias = argrule.alias
local Union = argrule.Union
local Optional = argrule.Optional
local List = argrule.List
local Tuple = argrule.Tuple
local Dict = argrule.Dict
local Literal = argrule.Literal

describe("argrule contracts", function()
  it("builds local alias and Union contracts from array-like tables", function()
    local Positive = alias {
      function(o)
        return type(o) == "number" and o > 0
      end,
    }
    local Name = alias { argrule.string }
    local PositiveOrName = Union { Positive, Name }

    assert.is_truthy(Positive(1))
    assert.is_falsy(Positive(-1))
    assert.is_truthy(PositiveOrName(1))
    assert.is_truthy(PositiveOrName "x")
    assert.is_falsy(PositiveOrName(false))
  end)

  it("validates alias and Union constructor tables", function()
    helper.has_error_containing(function()
      alias {}
    end, "at least 1")
    helper.has_error_containing(function()
      alias { argrule.number, argrule.string }
    end, "at most 1")
    helper.has_error_containing(function()
      alias { type = argrule.number }
    end, "array-like")
    helper.has_error_containing(function()
      Union {}
    end, "at least 1")
  end)

  it("supports Optional, List, Tuple, Dict, Literal, and Callable", function()
    local MaybeNumber = Optional { argrule.number }
    local NumberList = List { argrule.number }
    local Pair = Tuple { argrule.string, argrule.number }
    local StringMap = Dict { argrule.string, argrule.number }
    local Mode = Literal { "train", "eval" }

    assert.is_truthy(MaybeNumber(nil))
    assert.is_truthy(MaybeNumber(1))
    assert.is_falsy(MaybeNumber "x")
    assert.is_truthy(NumberList { 1, 2, 3 })
    assert.is_falsy(NumberList { 1, "x" })
    assert.is_truthy(Pair { "x", 1 })
    assert.is_falsy(Pair { "x", "y" })
    assert.is_truthy(StringMap { a = 1, b = 2 })
    assert.is_falsy(StringMap { a = "x" })
    assert.is_truthy(Mode "train")
    assert.is_falsy(Mode "test")
    assert.is_truthy(argrule.Callable(function() end))
    assert.are.equal(argrule.Callable, argrule.Callable {})
  end)

  it("supports Penlight-style class inheritance", function()
    local Base = { __name = "Base" }
    Base.__index = Base
    Base._class = Base

    local Child = { __name = "Child", _base = Base }
    Child.__index = Child
    Child._class = Child

    local BaseType = alias { Base }
    local child = setmetatable({ _class = Child }, Child)

    assert.is_truthy(BaseType(child))
  end)

  it("reports readable contract names", function()
    assert.are.equal("number", tostring(argrule.number))
    assert.are.equal("number", argrule.type_name(argrule.number))
    assert.are.equal("List[number]", tostring(List { argrule.number }))
  end)
end)
