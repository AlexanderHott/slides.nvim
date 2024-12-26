vim.api.nvim_create_user_command("SlidesStart", function()
	require("slides").start_presentation({})
end, {})
