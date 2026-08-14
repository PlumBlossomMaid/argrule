local M = {}

function M.has_error_containing(fn, needle)
  local ok, err = pcall(fn)
  assert(ok == false, "expected failure")
  assert(
    tostring(err):find(needle, 1, true),
    "expected error containing " .. needle .. ", got " .. tostring(err)
  )
end

return M
