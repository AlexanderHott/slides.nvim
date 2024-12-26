---@diagnostic disable: undefined-field

local eq = assert.are.same
local parse_slides = require("slides")._parse_slides
describe("slides.parse_slides", function()
	it("should parse an empty file", function()
		eq({ slides = {} }, parse_slides({}))
	end)
	it("should parse file with one slide", function()
		eq(
			{ slides = {
				{ title = "# title", body = { "body" }, codeblocks = {} },
			} },
			parse_slides({ "# title", "body" })
		)
	end)

	it("should parse file with one slide", function()
		eq(
			{ slides = {
				{ title = "# title", body = { "body" }, codeblocks = {} },
			} },
			parse_slides({ "# title", "body" })
		)
	end)

	it("should parse code blocks", function()
		local actual = parse_slides({ "# title", "body", "```lua", "print('hi')", "```" })
		eq(1, #actual.slides)

		local slide = actual.slides[1]
		eq("# title", slide.title)
		eq({ "body", "```lua", "print('hi')", "```" }, slide.body)
		eq(
			vim.trim([[
```lua
print('hi')
```
]]),
			slide.codeblocks[1]
		)
	end)
end)
