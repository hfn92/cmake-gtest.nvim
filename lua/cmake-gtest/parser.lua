local log = require("cmake-gtest.log")

local parser = {}

local function is_test(line)
  if (string.match(line, "^TEST") or string.match(line, "^TYPED_TEST") ) and string.find(line, "DISABLED_") == nil then
    return true
  end
  return false
end

local function parse_test(line)
  local res = {}
  if string.match(line, "^TEST%(") then
    res.type = "regular"
  elseif string.match(line, "^TEST%_F%(") then
    res.type = "fixture"
  elseif string.match(line, "^TEST%_P%(") then
    res.type = "parameterized"
  elseif string.match(line, "^TYPED%_TEST%(") then
    res.type = "typed"
  elseif string.match(line, "^TYPED%_TEST%_P%(") then
    res.type = "typed_parameterized"
  else
    return nil
  end

  local pattern = "%((.-),%s*(.-)%)"
  local prefix, name = string.match(line, pattern)
  prefix = vim.trim(prefix)
  name = vim.trim(name)

  res.prefix = prefix
  res.name = name

  return res
end

function parser.find_nearest_test()
    local current = vim.api.nvim_win_get_cursor(0)[1]

  while current > 0 do
    local line = vim.api.nvim_buf_get_lines(0, current - 1, current, false)[1]
    if is_test(line) then
      local test = parse_test(line)
      if test ~= nil then
        return test
      end
    end
    current = current - 1
  end

   log.warn("No tests found")
end

-- Parser using the clang? ast. Maybe implement later if simple parser does not work
-- local function handler2(err, node, d)
--     if err or not node then
--         return
--     else
--     print(string.rep(" ", d) .. node.role .. " -  " .. node.kind .. " - " .. (node.detail or ""))
--      
--     if node.role == "declaration" and node.kind == "CXXRecord" then
--       print(node.detail)
--     end
--
--     if node.children then
--         for _, child in pairs(node.children) do
--             -- if not visited[child] then
--                 -- walk_tree(child, visited, result, padding .. "  ", hl_bufs)
--     -- print(child.role .. " -  " .. child.kind .. " - " .. (child.detail or ""))
--          handler2(err, child, d + 2)
--             -- end
--         end
--     end
--     end
-- end
--
-- local function handler(err, node)
--     if err or not node then
--         return
--     else
--     print( node.role .. " -  " .. node.kind .. " - " .. (node.detail or ""))
--      
--     if node.role == "declaration" and node.kind == "CXXRecord" then
--       print(node.detail)
--     end
--
--     if node.children then
--         for _, child in pairs(node.children) do
--             -- if not visited[child] then
--                 -- walk_tree(child, visited, result, padding .. "  ", hl_bufs)
--     -- print(child.role .. " -  " .. child.kind .. " - " .. (child.detail or ""))
--          handler2(err, child, 2)
--             -- end
--         end
--     end
--     end
-- end
--
-- function gtest.ast()
--     vim.lsp.buf_request(0, "textDocument/ast", {
--         textDocument = { uri = vim.uri_from_bufnr(0) },
--         {},
--         -- range = {
--         --     start = {
--         --         line = line1 - 1,
--         --         character = 0,
--         --     },
--         --     ["end"] = {
--         --         line = line2,
--         --         character = 0,
--         --     },
--         -- },
--     }, handler)
-- end


return parser
