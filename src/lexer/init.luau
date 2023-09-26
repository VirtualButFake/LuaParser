--[[

    Luau Lexer
    Written by VirtualButFake

    Heavy inspiration taken from boatbomber's lexer used in Highlighter (https://github.com/boatbomber/Highlighter) & DumbLuaParser by ReFreezed (https://github.com/ReFreezed/DumbLuaParser)

    List of token types:
    - identifier
    - keyword
    - string
    - number
    - comment
    - punctuation

]]

local lexer = {}

local tokenData = require("tokenData")
local token = require("token")
token.lexer = lexer -- cant require from there bc cyclic dependency blabla

local patterns = tokenData.patterns
local cleaners = patterns.cleaners

local parserUtils = require("../utils/parser")

function lexer.scan(code: string, startOffset: number?): { token.TokenObject }
	local self = setmetatable({
		pointer = 1,
		source = code,
		tokens = {},
	}, { __index = lexer }) :: lexerData

	-- scan
	local sourceSize = #self.source
	local nextWhitespace = ""

	while self.pointer <= sourceSize do
		local matched = false

		for _, tokenType in tokenData.order do
			local tokenPatterns = patterns[tokenType]

			for i, pattern in tokenPatterns do
				local start, finish =
					string.find(self.source, cleaners.prefix .. pattern .. cleaners.suffix, self.pointer)

				if start == nil then
					continue
				end

				matched = true

				-- get newline data from the content
				local content = self.source:sub(start, finish)
				
				local preWhitespace = nextWhitespace .. self.source:sub(self.pointer, start - 1)
				nextWhitespace = ""

				local postWhitespace = content:match("[%s%c]+$") -- all whitespace at end of string
				content = content:gsub("[%s%c]+$", "")

				self.pointer = finish + 1

				if tokenType == tokenData.types.comment then 
					-- add as leading whitespace on last node or trailing on next
					local whitespace = `{preWhitespace}{content}{postWhitespace or ""}`
					
					if self.tokens[#self.tokens] then 
						self.tokens[#self.tokens].leadingWhitespace ..= whitespace
					else 
						nextWhitespace = whitespace
					end

					break
				elseif tokenType == tokenData.types.punctutation and content == ";" then
					-- add as leading whitespace on last node or trailing on next
					local whitespace = `{preWhitespace}{content}{postWhitespace or ""}`
					
					if self.tokens[#self.tokens] then 
						self.tokens[#self.tokens].leadingWhitespace ..= whitespace
					else 
						nextWhitespace = whitespace
					end

					break
				end

				token.new({
					type = tokenType,
					content = content,
					tokenStart = start + (startOffset or 0),
					tokenEnd = finish + (startOffset or 0),
					trailingWhitespace = preWhitespace,
					leadingWhitespace = postWhitespace or "",
				}, self)

				break
			end

			if matched then
				break
			end
		end

		if not matched then 
			local line, startIndex = parserUtils.getDebug({
				tokenStart = self.pointer,
				tokenEnd = self.pointer,
			}, self.source)
			error(`Could not resolve token type for token at line {line}, character {startIndex}`)
		end
	end

	return self.tokens
end

type lexerData = typeof(setmetatable(
	{} :: {
		pointer: number,
		source: string,
		tokens: { token.TokenObject },
	},
	{ __index = lexer }
))

return lexer
