local M = {}

---@class slides.Slides
---@field slides string[][]: the slides

M.setup = function() end

---@param lines string[]
---@return slides.Slides
local function parse_slides(lines)
	local slides = { slides = {} }
	local current_slide = {}
	for _, line in ipairs(lines) do
		if line:find("^#") then
			if #current_slide > 0 then
				table.insert(slides.slides, current_slide)
			end
			current_slide = {}
		end
		table.insert(current_slide, line)
	end
	if #current_slide > 0 then
		table.insert(slides.slides, current_slide)
	end
	return slides
end

local function create_floating_window(opts)
	opts = opts or {}
	local width = opts.width or math.floor(vim.o.columns * 0.8)
	local height = opts.height or math.floor(vim.o.lines * 0.8)

	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	local buf = vim.api.nvim_create_buf(false, true)

	---@type vim.api.keyset.win_config
	local win_config = {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
	}

	local win = vim.api.nvim_open_win(buf, true, win_config)

	return { buf = buf, win = win }
end

M.start_presentation = function(opts)
	opts = opts or {}
	opts.bufnr = opts.bufnr or 0
	local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
	local slides = parse_slides(lines)
	local float = create_floating_window()

	local current_slide = 1
	vim.keymap.set("n", "n", function()
		current_slide = math.min(current_slide + 1, #slides.slides)
		vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, slides.slides[current_slide])
	end, { buffer = float.buf })

	vim.keymap.set("n", "p", function()
		current_slide = math.max(current_slide - 1, 1)
		vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, slides.slides[current_slide])
	end, { buffer = float.buf })

	vim.keymap.set("n", "q", function()
		current_slide = math.max(current_slide - 1, 1)
		vim.api.nvim_win_close(float.win, true)
	end, { buffer = float.buf })

	vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, slides.slides[current_slide])
end

M.start_presentation({ bufnr = 11 })

return M
