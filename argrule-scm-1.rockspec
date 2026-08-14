package = "argrule"
version = "scm-1"
source = {
   url = "git+https://github.com/PlumBlossomMaid/argrule.git"
}
description = {
   summary = "Lua function signature rules with positional and named-table calls",
   detailed = [[
argrule is a Lua-source signature layer for Lua 5.1, Lua 5.2, Lua 5.3, Lua 5.4, and LuaJIT.
It keeps argcheck-style rule tables and usage rendering while allowing Lua rocks backed by C modules, such as Penlight's LuaFileSystem dependency.
]],
   homepage = "https://github.com/PlumBlossomMaid/argrule",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1",
   "penlight >= 1.13"
}
build = {
   type = "builtin",
   modules = {
      ["argrule"] = "lua/argrule/init.lua",
      ["argrule.rule"] = "lua/argrule/rule.lua",
      ["argrule._state"] = "lua/argrule/_state.lua",
      ["argrule._usage"] = "lua/argrule/_usage.lua"
   }
}
