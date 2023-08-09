local lexer = require("../src/lexer")
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local tokens = lexer.scan(fs.readFile("testSamples/test1.luau"))
local s = ""

if tokens then
	local newTokens = {}
	

	for i, v in pairs(tokens) do
		s = s .. v.trailingWhitespace .. v.content .. v.leadingWhitespace
	end

	fs.writeFile("output1.json", serde.encode("json", tokens, true))
end

--print(s)

local tokens = {}
for i, v in require("../penlightlexer").scan(fs.readFile("testSamples/test1.luau")) do
	--print(i, v)
	table.insert(tokens, {
		type = i,
		value = v,
	})
end
fs.writeFile("output2.json", serde.encode("json", tokens, true))

print("success")
