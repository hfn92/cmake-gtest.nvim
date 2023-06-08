
local gtest = require("cmake-gtest")

vim.api.nvim_create_user_command(
  "GTestSelectAndRunTestsuite",
  gtest.select_and_run_testsuite,
  { -- opts
    bang = true,
    desc = "Select and run testsuite",
  }
)

vim.api.nvim_create_user_command(
  "GTestRunTestsuite",
  gtest.run_testsuite,
  { -- opts
    nargs = 0,
    bang = true,
    desc = "Run testsuite for current file",
  }
)

vim.api.nvim_create_user_command('GTestCodeAction', gtest.code_action, {})
vim.api.nvim_create_user_command('GTestRunTestUnderCursor', gtest.run_test_under_cursor, {bang = true,})
vim.api.nvim_create_user_command('GTestRunTestcaseUnderCursor', gtest.run_testcase_under_cursor, {bang = true,})
vim.api.nvim_create_user_command('GTestSelectAndRunTest', gtest.select_and_run_test, {bang = true,})
vim.api.nvim_create_user_command('GTestSelectAndRunTestcase', gtest.select_and_run_testcase, {bang = true,})
vim.api.nvim_create_user_command('GTestCancel', gtest.cancel, {})
