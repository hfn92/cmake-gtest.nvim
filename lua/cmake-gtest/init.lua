local log = require("cmake-gtest.log")
local const = require("cmake-gtest.const")
local parser = require("cmake-gtest.parser")
local quickfix = require("cmake-gtest.quickfix")
local cmake = require("cmake-tools")
local has_nvim_dap = pcall(require, "dap")

local gtest = {}

local config = {}

function gtest.setup(values)
	config = vim.tbl_deep_extend("force", const, values)
end

function gtest.get_code_actions()
	local test = parser.find_nearest_test()
	if test == nil then
		return nil
	end
	local testFull = test.prefix .. "." .. test.name
	local actions = {
		"Run Test         (" .. testFull .. ")",
		"Run Testcase     (" .. test.prefix .. ".)",
		"Debug Test       (" .. testFull .. ")",
		"Debug Testcase   (" .. test.prefix .. ".)",
	}

	local filter, fn = {}, {}

	if test.type == "parameterized" then
		table.insert(filter, "*/" .. testFull .. "/*")
		table.insert(filter, "*/" .. test.prefix .. ".*")
	elseif test.type == "typed" then
		table.insert(filter, test.prefix .. "*." .. test.name)
		table.insert(filter, test.prefix .. "*.*")
	elseif test.type == "typed_parameterized" then
		table.insert(filter, "*/" .. test.prefix .. "*." .. test.name)
		table.insert(filter, "*/" .. test.prefix .. "*.*")
	else
		table.insert(filter, testFull)
		table.insert(filter, test.prefix .. ".*")
	end

	table.insert(filter, filter[1])
	table.insert(filter, filter[2])

	table.insert(fn, function()
		gtest.run_testsuite({ bang = false }, { "--gtest_filter=" .. filter[1] }, filter[1])
	end)
	table.insert(fn, function()
		gtest.run_testsuite({ bang = false }, { "--gtest_filter=" .. filter[2] }, filter[2])
	end)
	table.insert(fn, function()
		gtest.run_testsuite({ bang = true }, { "--gtest_filter=" .. filter[3] }, filter[3])
	end)
	table.insert(fn, function()
		gtest.run_testsuite({ bang = true }, { "--gtest_filter=" .. filter[4] }, filter[4])
	end)

	return { display = actions, filter = filter, fn = fn }
end

function gtest.code_action(args)
	local actions = gtest.get_code_actions()
	if actions == nil then
		return
	end

	if args and args.preselection then
		actions.fn[args.preselection]()
	else
		vim.ui.select(actions.display, { prompt = "Select Action" }, function(_, idx)
			if not idx then
				return
			end
			actions.fn[idx]()
		end)
	end
end

function gtest.run_test_under_cursor(args)
	local preselection = 1
	if args and args.bang then
		preselection = 3
	end
	gtest.code_action({ preselection = preselection })
end

function gtest.run_testcase_under_cursor(args)
	local preselection = 2
	if args and args.bang then
		preselection = 4
	end
	gtest.code_action({ preselection = preselection })
end

function gtest.find_main_files()
	local files = vim.fn.systemlist("rg -l --color never -e '(gtest.h)|(gmock.h)|(InitGoogleTest)'")

	for i, name in ipairs(files) do
		files[i] = vim.trim(name):gsub("\\", "/")
	end
	return files
end

function gtest.run(target, args, debug, filter)
	if debug and has_nvim_dap then
		local fargs = { target, unpack(args) }
		cmake.quick_debug({ fargs = fargs })
	else
		vim.cmd("wall")

		local cconfig = cmake.get_config()
		local model = cconfig:get_code_model_info()[target]
		local result = cconfig:get_launch_target_from_info(model)
		local cwd = cmake.get_launch_path(target)
		local cmd = result.data
		local env = cmake.get_run_environment(target)

		cmake.quick_build({ fargs = { target } }, function()
			if config.hooks and config.hooks.run and type(config.hooks.run) == "function" then
				config.hooks.run(target, filter, cwd, cmd, args, env)
			else
				return quickfix.run(cwd, cmd, env, args, config)
			end
		end)
	end
end

function gtest.cancel()
	return quickfix.job:shutdown(1, 9)
end

function gtest.find_tests(path)
	if vim.fn.has("win32") and not vim.fn.has("wsl") then
		path = path:gsub("/", "\\")
	end
	local handle = io.popen(path .. " --gtest_list_tests")
	if handle == nil then
		return
	end
	local result = handle:read("*a")
	handle:close()

	local tests, testcases = {}, {}

	local output = vim.split(result, "\n")

	local testcase = ""
	local type_info = nil
	for _, v in ipairs(output) do
		v = vim.trim(v)
		if v:len() == 0 then
			goto skip
		end

		-- TEST and TEST_F looks like this
		-- TestA.
		--   Good
		--   NotSoGood
		--
		-- TEST_P:
		-- MeenyMinyMoe/FooTest.
		--   HasBlahBlah/0  # GetParam() = 0
		--   HasBlahBlah/1  # GetParam() = 1
		--
		-- TYPED_TEST:
		-- MyFixture/0.  # TypeParam = char
		--   Example
		--
		--TYPED_TEST_P:
		-- My/FooTestTP/0.  # TypeParam = char
		--   DoesBlah
		--   HasPropertyA

		-- handle user output ?

		-- local pattern = "^(.-)(%..*)$"

		local pattern = "^(.-%.)(.*)$"
		local tc, ti = string.match(v, pattern) -- type info (after #)

		if tc ~= nil then
			testcase = vim.trim(tc)
			type_info = ti
			table.insert(testcases, testcase)
		elseif testcase ~= "" then
			table.insert(tests, testcase .. v .. (type_info or "")) -- append typeinfo at each test to make TYPED_TEST have the same format as TEST_P
		end

		::skip::
	end
	return tests, testcases
end

function gtest.find_all_tests(callback)
	gtest.find_testsuites(function(testsuites)
		if testsuites == nil then
			return
		end

		local paths = testsuites.paths
		local tests = {}
		local testcases = {}

		for _, v in ipairs(paths) do
			local t, tc = gtest.find_tests(v)
			table.insert(tests, t)
			table.insert(testcases, tc)
		end

		testsuites.tests = tests
		testsuites.testcases = testcases
		callback(testsuites)
	end)
end

function gtest.select_and_run_test(args)
	local debug = args.bang
	gtest.find_all_tests(function(testsuites)
		local names = testsuites.names
		local tests = testsuites.tests

		local target, test, display = {}, {}, {}, {}

		for idx, n in ipairs(names) do
			for _, t in ipairs(tests[idx]) do
				table.insert(target, n)
				table.insert(test, t)
				table.insert(display, n .. " " .. t)
			end
		end

		vim.ui.select(display, { prompt = "select test to run" }, function(_, idx)
			if not idx then
				return
			end
			local filter = test[idx]
			if filter:find(" ") then -- strip the param info from parameterized tests
				filter = string.gsub(filter, "%s.*", "")
			end

			return gtest.run(target[idx], { "--gtest_filter=" .. filter }, debug, filter)
		end)
	end)
end

function gtest.select_and_run_testcase(args)
	local debug = args.bang
	gtest.find_all_tests(function(testsuites)
		local names = testsuites.names
		local tests = testsuites.testcases

		local suite, display, path = {}, {}, {}

		for idx, n in ipairs(names) do
			for _, t in ipairs(tests[idx]) do
				table.insert(suite, n)
				table.insert(display, t)
			end
		end

		vim.ui.select(display, { prompt = "Select Test to run" }, function(_, idx)
			if not idx then
				return
			end
			return gtest.run(suite[idx], { "--gtest_filter=" .. display[idx] .. "*" }, debug, display[idx])
		end)
	end)
end

function gtest.select_and_run_testsuite()
	gtest.find_testsuites(function(testsuites)
		if testsuites == nil then
			return
		end

		local names = testsuites.names

		vim.ui.select(names, { prompt = "Select Testsuite to run" }, function(_, idx)
			if not idx then
				return
			end
			gtest.run(names[idx], {})
		end)
	end)
end

local table_contains = function(table, str)
	for _, v in pairs(table) do
		if v == str then
			return true
		end
	end
	return false
end

local table_size = function(table)
	local cnt = 0
	for _ in pairs(table) do
		cnt = cnt + 1
	end
	return cnt
end

-- Run the testsuite executable according to the current file
function gtest.run_testsuite(args, cmd_args, filter)
	local debug = args.bang
	gtest.find_testsuites(function(testsuites)
		if testsuites == nil then
			return
		end

		local names = testsuites.names
		local paths = testsuites.paths
		local files = testsuites.files

		local currentfile = vim.fn.expand("%:."):gsub("\\", "/")

		local possibleSuites = {}
		for idx, v in ipairs(names) do
			if table_contains(files[idx], currentfile) then
				table.insert(possibleSuites, v)
			end
		end

		local num = table_size(possibleSuites)
		if num == 0 then
			log.warn("No testsuites found for '" .. currentfile .. "'")
		elseif num == 1 then
			gtest.run(possibleSuites[1], cmd_args or {}, debug, filter)
		else
			vim.ui.select(
				possibleSuites,
				{ prompt = "Select Testsuite to run" },
				vim.schedule_wrap(function(_, idx)
					if not idx then
						return
					end
					return gtest.run(possibleSuites[idx], cmd_args or {}, debug, filter)
				end)
			)
		end
	end)
end

function gtest.find_testsuites(callback)
	cmake.get_cmake_launch_targets(function(targets_res)
		if targets_res == nil then
			vim.cmd("CMakeGenerate")
			if targets_res == nil then
				log.error("Could not determine cmake targets")
				return nil
			end
		end
		local targets, targetPaths = targets_res.data.targets, targets_res.data.abs_paths
		local models = cmake.get_model_info()
		local mainFiles = gtest.find_main_files()

		if mainFiles == nil then
			return
		end

		local names, paths, files = {}, {}, {}

		for idx, target in ipairs(targets) do
			local model = models[target]
			for _, file in ipairs(model["sources"]) do
				if file["isGenerated"] == nil or file["isGenerated"] == false then
					local path = file["path"]
					-- check if project contains gtest main file
					for _, gtestFile in ipairs(mainFiles) do
						if gtestFile == path then
							-- add to test projects
							table.insert(names, target)
							table.insert(paths, targetPaths[idx])
							goto done
						end
					end
				end
			end
			::done::
		end

		-- sceond pass just to collect all files for all relevant testsuites
		for _, target in ipairs(names) do
			local model = models[target]
			local targetFiles = {}
			for _, file in ipairs(model["sources"]) do
				if file["isGenerated"] == nil or file["isGenerated"] == false then
					local path = file["path"]
					table.insert(targetFiles, path)
				end
			end
			table.insert(files, targetFiles)
		end

		callback({ names = names, paths = paths, files = files })
	end)
end

return gtest
