
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local lexer = require("../../src/lexer")

local sample = fs.readFile("tests/samples/luraph.lua")
local tokens = lexer.scan(sample)

local s = ""

if tokens then
	for i, v in pairs(tokens) do
		s = s .. v.trailingWhitespace .. v.content .. v.leadingWhitespace
	end

	fs.writeFile("output.json", serde.encode("json", tokens, true))
	print(tokens)
end

print("success")
