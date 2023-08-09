-- this module is pmuch just an external table constructor - it felt ugly to have metatable related things in the lexer
local token = {
	lexer = nil, -- will have to settle for no autocomplete, but we need access to the lexer for interpolated strings but placing the tokens in the lexer feels ugly
}

local tokenFunctions = {}

local data = require("tokenData")
local types = data.types

local interStringPattern = "`[^\n]-`"

function token.new(
	tokenData: TokenOptions,
	lexer: {
		pointer: number,
		source: string,
		tokens: { TokenObject },
	}
): nil
	-- process tokens
	if tokenData.type == types.identifier then
		if table.find(data.keywords, tokenData.content) then
			tokenData.type = types.keyword
		end
	elseif tokenData.type == types.string then
		-- string
		-- handle string escapes
		-- primarily the \\" variant, where the string will not be finished even though it should be
		local start, finish = tokenData.content:find("\\\\")

		if start and finish ~= (#tokenData.content - 1) and (tokenData.content:sub(finish + 1, finish + 1) == "\"" or tokenData.content:sub(finish + 1, finish + 1) == "\'") then -- we've got a funny escape case o nour hands
			token.new({
				type = types.string,
				content = tokenData.content:sub(0, finish + 1),
				tokenStart = tokenData.tokenStart,
				tokenEnd = tokenData.tokenStart + finish + 1,
				leadingWhitespace = "",
				trailingWhitespace = "",
			}, lexer)

			lexer.pointer = tokenData.tokenStart + finish + 1
			return
		end

		if tokenData.content:find(interStringPattern) and tokenData.content:find("^.-[^\\][{}]") then
			-- interpolated string
			local stringPointer = 0
			local inString = true

			while stringPointer <= #tokenData.content do
				local start, finish = tokenData.content:find("^.-[^\\][{}]", stringPointer)

				if start == nil then
					-- no brackets found; rest is all a normal string
					token.new({
						type = types.string,
						content = tokenData.content:sub(stringPointer),
						tokenStart = tokenData.tokenStart + stringPointer,
						tokenEnd = tokenData.tokenStart + (#tokenData.content - stringPointer),
						leadingWhitespace = "",
						trailingWhitespace = "",
					}, lexer)

					break
				end

				if start and finish and inString then
					token.new({
						type = types.string,
						content = tokenData.content:sub(start, finish),
						tokenStart = tokenData.tokenStart + start,
						tokenEnd = tokenData.tokenStart + finish,
						leadingWhitespace = "",
						trailingWhitespace = "",
					}, lexer)

					inString = false -- we just got rid of all text in front of the brackets, so we're now inside of the brackets
					stringPointer = finish + 1
				elseif not inString then -- we're in code
					local code = tokenData.content:sub(start, finish - 1)
					local tokens = token.lexer.scan(code)

					for _, token in tokens do
						table.insert(lexer.tokens, token)
					end

					inString = true
					stringPointer = finish
				end
			end

			return
		end
	end

	table.insert(lexer.tokens, setmetatable(tokenData, tokenFunctions))
	return
end

function tokenFunctions:__index(key) end

export type TokenOptions = {
	type: string,
	content: string,
	value: any,
	-- position data
	tokenStart: number,
	tokenEnd: number,
	-- whitespace
	leadingWhitespace: string,
	trailingWhitespace: string,
	[string]: any, -- for private variables
}

export type TokenObject = typeof(setmetatable({} :: TokenOptions, tokenFunctions))

return token
