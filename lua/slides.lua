local M = {}
---
---@class slides.Slide
---@field title string
---@field body string[]

---@class slides.Slides
---@field slides slides.Slide[]: the slides

M.setup = function() end

---@param lines string[]
---@return slides.Slides
local function parse_slides(lines)
	local slides = { slides = {} }
	local current_slide = { title = "", body = {} }

	for _, line in ipairs(lines) do
		if line:find("^#") then
			if #current_slide.title > 0 then
				table.insert(slides.slides, current_slide)
			end
			current_slide = { title = line, body = {} }
		else
			table.insert(current_slide.body, line)
		end
	end
	if #current_slide.title > 0 then
		table.insert(slides.slides, current_slide)
	end
	return slides
end

---@param config vim.api.keyset.win_config
local function create_floating_window(config)
	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, config)
	return { buf = buf, win = win }
end

M.start_presentation = function(opts)
	opts = opts or {}
	opts.bufnr = opts.bufnr or 0
	local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
	local slides = parse_slides(lines)

	local width = vim.o.columns
	local height = vim.o.lines
	---@type vim.api.keyset.win_config[]
	local windows = {
		background = {
			relative = "editor",
			width = width,
			height = height,
			col = 0,
			row = 0,
			style = "minimal",
			zindex = 1,
		},
		header = {
			relative = "editor",
			width = width,
			height = 1,
			col = 0,
			row = 0,
			style = "minimal",
			border = "rounded",
			zindex = 2,
		},
		body = {
			relative = "editor",
			width = width - 8,
			height = height - 5,
			col = 8,
			row = 4,
			style = "minimal",
			border = { " ", " ", " ", " ", " ", " ", " ", " " },
			zindex = 2,
		},
	}
	local background_float = create_floating_window(windows.background)
	local header_float = create_floating_window(windows.header)
	local body_float = create_floating_window(windows.body)

	vim.bo[header_float.buf].filetype = "markdown"
	vim.bo[body_float.buf].filetype = "markdown"

	local function set_slide_content(idx)
		local slide = slides.slides[idx]
		local padding = string.rep(" ", (width - #slide.title) / 2)
		vim.api.nvim_buf_set_lines(header_float.buf, 0, -1, false, { padding .. slide.title })
		vim.api.nvim_buf_set_lines(body_float.buf, 0, -1, false, slide.body)
	end

	local current_slide = 1

	vim.keymap.set("n", "n", function()
		current_slide = math.min(current_slide + 1, #slides.slides)
		set_slide_content(current_slide)
	end, { buffer = body_float.buf })

	vim.keymap.set("n", "p", function()
		current_slide = math.max(current_slide - 1, 1)
		set_slide_content(current_slide)
	end, { buffer = body_float.buf })

	vim.keymap.set("n", "q", function()
		current_slide = math.max(current_slide - 1, 1)
		vim.api.nvim_win_close(body_float.win, true)
	end, { buffer = body_float.buf })

	local restore = {
		cmdheight = {
			old = vim.o.cmdheight,
			new = 0,
		},
	}

	for option, config in pairs(restore) do
		vim.opt[option] = config.new
	end

	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = body_float.buf,
		callback = function()
			for option, config in pairs(restore) do
				vim.opt[option] = config.old
			end

			pcall(vim.api.nvim_win_close, header_float.win, true)
			pcall(vim.api.nvim_win_close, background_float.win, true)
		end,
	})

	set_slide_content(current_slide)
end

M.start_presentation({ bufnr = 12 })

return M
