
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local lexer = require("../../src/lexer")

local sample = fs.readFile("tests/samples/json.luau")
local tokens = lexer.scan(sample)

local s = ""

if tokens then
	for i, v in pairs(tokens) do
		s = s .. v.trailingWhitespace .. v.content .. v.leadingWhitespace
	end

	fs.writeFile("lexerOutput.json", serde.encode("json", tokens, true))
end

print("success")
