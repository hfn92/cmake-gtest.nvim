
# cmake-gtest.nvim

A very WIP gtest plugin. This plugin uses <https://github.com/Civitasv/cmake-tools.nvim> to detect and run gtest executables and tests in the quickfix window.

## Features

* Detects what executables contain gtest tests
* Run test executables
* Run test exectuable according to the current file
* Run specific test or testcase
* Run test/testcase under cursor
* Support parameterized and typed test

## How it works

* Detects test executables by using `ripgrep` to check which executable contains a file with `InitGoogleTest`
* Uses `--gtest_list_tests` to detect all tests
* Run under cursor uses string matching

## requirements

* ripgrep
* cmake-tools.nvim

## Commands

`GTestSelectAndRunTestsuite` Opens dialog to select and run a test executable

`GTestRunTestsuite` Runs the test executable that builds the current file (selection if file is used by multiple executables)

`GTestCodeAction` Run under cursor dialog

`GTestRunTestUnderCursor` Run test under cursor

`GTestRunTestcaseUnderCursor` Run testcase under cursor

`GTestSelectAndRunTest` Select and run a single test

`GTestSelectAndRunTestcase` Select and run a single testcase

`[!]` Adding `!` after commands runs the test(s) in debug mode as configured in `cmake-tools.nvim`

### Integrate Codeactions

You can also integrate code actions by using

```lua
require'null-ls'.register({
  name = 'GTestActions',
  method = {require'null-ls'.methods.CODE_ACTION},
  filetypes = { 'cpp' },
  generator = {
    fn = function()
      local actions = require("cmake-gtest").get_code_actions()
      if actions == nil then return end
      local result = {}
      for idx, v in ipairs(actions.display) do
        table.insert(result, { title = v, action = actions.fn[idx] })
      end
      return result
    end
  }
})
```
