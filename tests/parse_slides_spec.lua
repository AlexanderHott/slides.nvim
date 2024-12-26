---@diagnostic disable: undefined-field

local eq = assert.are.same
local parse_slides = require("slides")._parse_slides
describe("slides.parse_slides", function()
	it("should parse an empty file", function()
		eq({ slides = {} }, parse_slides({}))
	end)
	it("should parse file with one slide", function()
		eq({ slides = {
			{ title = "# title", body = { "body" } },
		} }, parse_slides({ "# title", "body" }))
	end)
end)
