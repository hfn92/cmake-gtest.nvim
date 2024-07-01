local log = require("cmake-gtest.log")
local Job = require("plenary.job")

local quickfix = {
	job = nil,
}

local function is_quickfix_open()
	local qf_exists = false
	for _, win in pairs(vim.fn.getwininfo()) do
		if win["quickfix"] == 1 then
			qf_exists = true
		end
	end

	return qf_exists
end

function quickfix.scroll_to_bottom()
	vim.api.nvim_command("cbottom")
end

local function append_to_quickfix(error, data)
	local line = error and error or data
	vim.fn.setqflist({}, "a", { lines = { line } })
	-- scroll the quickfix buffer to bottom
	quickfix.scroll_to_bottom()
end

function quickfix.show(quickfix_opts)
	if not is_quickfix_open() then
		vim.api.nvim_command(quickfix_opts.position .. " copen " .. quickfix_opts.size)
		vim.api.nvim_command("wincmd p")
	end
end

function quickfix.close()
	vim.api.nvim_command("cclose")
end

function quickfix.run(cwd, cmd, env, args, opts)
	vim.fn.setqflist({}, " ", { title = cmd .. " " .. table.concat(args, " ") })
	if opts.gtest_quickfix_opts.show == "always" then
		quickfix.show(opts.gtest_quickfix_opts)
	end

	quickfix.job = Job:new({
		command = cmd,
		args = args,
		cwd = cwd,
		env = env,
		on_stdout = vim.schedule_wrap(append_to_quickfix),
		on_stderr = vim.schedule_wrap(append_to_quickfix),
		on_exit = vim.schedule_wrap(function(_, code, signal)
			-- append_to_quickfix("Exited with code " .. (signal == 0 and code or 128 + signal))
			-- if code == 0 and signal == 0 then
			-- 	if opts.on_success then
			-- 		opts.on_success()
			-- 	end
			-- elseif opts.gtest_quickfix_opts.show == "only_on_error" then
			-- 	quickfix.show(opts.gtest_quickfix_opts)
			-- 	quickfix.scroll_to_bottom()
			-- end
		end),
	})

	quickfix.job:start()
	return quickfix.job
end

function quickfix.has_active_job()
	if not quickfix.job or quickfix.job.is_shutdown then
		return false
	end
	log.error(
		"A GTest task is already running: " .. quickfix.job.command .. " Stop it before trying to run a new GTest task."
	)
	return true
end

return quickfix
