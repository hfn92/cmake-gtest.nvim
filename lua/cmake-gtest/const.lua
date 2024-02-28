local const = {
	gtest_quickfix_opts = {
		show = "always", -- "always", "only_on_error"
		position = "belowright", -- "bottom", "top"
		size = 10,
	},

	hooks = {
		--- Overwrite the internal quickfix runner with a function
		run = nil,
		---@param cwd string working directory for command execution
		---@param cmd string the command to execute
		---@param args string[] function args
		---@param env { [string] : string } environment variables
		-- run = function(cwd, cmd, args, env)
		-- end,
	},
}

return const
