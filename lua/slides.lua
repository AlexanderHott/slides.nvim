local M = {}
---
---@class slides.Slide
---@field title string
---@field body string[]
---@field codeblocks string[]

---@class slides.Slides
---@field slides slides.Slide[]: the slides

---@class Float
---@field buf integer
---@field win integer

---@type {
---		slides: slides.Slides,
---		current_slide: integer,
---		floats: {
---			background: Float,
---			header: Float,
---			body: Float,
---			footer: Float,
---		},
---		title: string,
---}
local state = {
	slides = { title = "", slides = {} },
	current_slide = 1,
	floats = {},
	title = "",
}

M.setup = function() end

---@param lines string[]
---@return slides.Slides
local function parse_slides(lines)
	local slides = { slides = {} }
	local current_slide = { title = "", body = {}, codeblocks = {} }

	-- parse title and body
	for _, line in ipairs(lines) do
		if line:find("^#") then
			if #current_slide.title > 0 then
				table.insert(slides.slides, current_slide)
			end
			current_slide = { title = line, body = {}, codeblocks = {} }
		else
			table.insert(current_slide.body, line)
		end
	end
	if #current_slide.title > 0 then
		table.insert(slides.slides, current_slide)
	end

	-- parse code blocks
	for _, slide in ipairs(slides.slides) do
		local codeblock = nil
		for _, line in ipairs(slide.body) do
			if vim.startswith(line, "```") then
				if codeblock then
					table.insert(slide.codeblocks, vim.trim(codeblock .. line .. "\n"))
					codeblock = nil
				else
					codeblock = line .. "\n"
				end
			elseif codeblock then
				codeblock = codeblock .. line .. "\n"
			end
		end
	end

	return slides
end
M._parse_slides = parse_slides

---@param config vim.api.keyset.win_config
---@param enter boolean?
local function create_floating_window(config, enter)
	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, enter or false, config)
	return { buf = buf, win = win }
end

---@return {
---		background: vim.api.keyset.win_config,
---		header: vim.api.keyset.win_config,
---		body: vim.api.keyset.win_config,
---		footer: vim.api.keyset.win_config,
---}
local function create_window_configurations()
	local width = vim.o.columns
	local height = vim.o.lines
	local background = {
		relative = "editor",
		width = width,
		height = height,
		col = 0,
		row = 0,
		style = "minimal",
		zindex = 1,
	}
	local header = {
		relative = "editor",
		width = width,
		height = 1,
		col = 0,
		row = 0,
		style = "minimal",
		border = "rounded",
		zindex = 2,
	}
	local footer = {
		relative = "editor",
		width = width,
		height = 1,
		col = 0,
		row = height - 1,
		style = "minimal",
		zindex = 2,
	}
	local body = {
		relative = "editor",
		width = width - 8,
		height = height
			- header.height
			- 2 -- header boarder
			- footer.height
			- 1 -- body padding
			- 2, -- body boarder
		col = 8,
		row = 4,
		style = "minimal",
		border = { " ", " ", " ", " ", " ", " ", " ", " " },
		zindex = 2,
	}
	return {
		background = background,
		header = header,
		body = body,
		footer = footer,
	}
end

---@param cb function(name: string, float: Float): nil
local function foreach_float(cb)
	for name, float in pairs(state.floats) do
		cb(name, float)
	end
end

---@param mode string|string[]
---@param lhs string
---@param rhs string|function
local function slides_keymap(mode, lhs, rhs)
	vim.keymap.set(mode, lhs, rhs, { buffer = state.floats.body.buf })
end

M.start_presentation = function(opts)
	opts = opts or {}
	opts.bufnr = opts.bufnr or 0
	local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
	state.slides = parse_slides(lines)
	state.current_slide = 1
	state.title = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(opts.bufnr), ":t") -- current filename

	local windows = create_window_configurations()
	state.floats.background = create_floating_window(windows.background)
	state.floats.header = create_floating_window(windows.header)
	state.floats.body = create_floating_window(windows.body, true)
	state.floats.footer = create_floating_window(windows.footer)

	foreach_float(function(_, float)
		vim.bo[float.buf].filetype = "markdown"
	end)

	local function set_slide_content(idx)
		local slide = state.slides.slides[idx]
		local width = vim.o.columns
		local padding = string.rep(" ", (width - #slide.title) / 2)
		vim.api.nvim_buf_set_lines(state.floats.header.buf, 0, -1, false, { padding .. slide.title })
		vim.api.nvim_buf_set_lines(state.floats.body.buf, 0, -1, false, slide.body)
		local footer = string.format("  %d / %d | %s", state.current_slide, #state.slides.slides, state.title)
		vim.api.nvim_buf_set_lines(state.floats.footer.buf, 0, -1, false, { footer })
	end

	slides_keymap("n", "n", function()
		state.current_slide = math.min(state.current_slide + 1, #state.slides.slides)
		set_slide_content(state.current_slide)
	end)

	slides_keymap("n", "p", function()
		state.current_slide = math.max(state.current_slide - 1, 1)
		set_slide_content(state.current_slide)
	end)

	slides_keymap("n", "q", function()
		state.current_slide = math.max(state.current_slide - 1, 1)
		vim.api.nvim_win_close(state.floats.body.win, true)
	end)

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
		buffer = state.floats.body.buf,
		callback = function()
			for option, config in pairs(restore) do
				vim.opt[option] = config.old
			end

			foreach_float(function(_, float)
				pcall(vim.api.nvim_win_close, float.win, true)
			end)
		end,
	})

	vim.api.nvim_create_autocmd("VimResized", {
		group = vim.api.nvim_create_augroup("slides-resized", {}),
		callback = function()
			if not vim.api.nvim_win_is_valid(state.floats.body.win) or state.floats.body.win == nil then
				return
			end

			local new_config = create_window_configurations()
			foreach_float(function(name, float)
				vim.api.nvim_win_set_config(float.win, new_config[name])
			end)
			set_slide_content(state.current_slide)
		end,
	})

	set_slide_content(state.current_slide)
end

return M
