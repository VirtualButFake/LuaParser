-- this module is pmuch just an external table constructor - it felt ugly to have metatable related things in the lexer
local token = {
	lexer = nil, -- will have to settle for no autocomplete, but we need access to the lexer for interpolated strings but placing the tokens in the lexer feels ugly
}

local tokenFunctions = {}

local data = require("tokenData")
local types = data.types

local interStringPattern = "`[^\n]-`"
local pendingBrackets = {}

function token.new(
	tokenData: TokenOptions,
	lexer: {
		pointer: number,
		source: string,
		tokens: { TokenObject },
	}
): TokenObject?
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

		if
			start
			and finish ~= (#tokenData.content - 1)
			and (
				tokenData.content:sub(finish + 1, finish + 1) == '"'
				or tokenData.content:sub(finish + 1, finish + 1) == "'"
			)
		then -- we've got a funny escape case o nour hands
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
			local openingString
			local lastString

			while stringPointer <= #tokenData.content do
				local startString, finishString = tokenData.content:find("^.-[^\\][{}]", stringPointer)

				if startString == nil then
					-- no brackets found; rest is all a normal string
					lastString = token.new({
						type = types.string,
						content = tokenData.content:sub(stringPointer),
						tokenStart = tokenData.tokenStart + stringPointer,
						tokenEnd = tokenData.tokenStart + stringPointer + #tokenData.content:sub(stringPointer),
						leadingWhitespace = tokenData.leadingWhitespace,
						trailingWhitespace = "",
					}, lexer)
					
					break
				end

				if startString and finishString and inString then
					lastString = token.new({
						type = types.string,
						content = tokenData.content:sub(startString, finishString),
						tokenStart = tokenData.tokenStart + startString,
						tokenEnd = tokenData.tokenStart + finishString,
						leadingWhitespace = "",
						trailingWhitespace = openingString == nil and tokenData.trailingWhitespace or "",
					}, lexer)

					inString = false -- we just got rid of all text in front of the brackets, so we're now inside of the brackets
					stringPointer = finishString + 1
				elseif not inString then -- we're in code
					local code = tokenData.content:sub(startString, finishString - 1)
					local tokens = token.lexer.scan(code, tokenData.tokenStart + stringPointer - 2)

					for _, token in tokens do
						token.isExpression = true
						table.insert(lexer.tokens, token)
					end

					inString = true
					stringPointer = finishString
				end

				if lastString and not openingString then
					openingString = lastString
				end
			end

			openingString.closingString = lastString

			return
		end
	elseif tokenData.type == types.punctutation then
		if tokenData.content == "(" then
			table.insert(pendingBrackets, tokenData)
		end

		if tokenData.content == ")" then
			-- connect the most recent bracket to this closing
			local bracket = pendingBrackets[#pendingBrackets] :: TokenOptions
			bracket.closingBracket = tokenData
			table.remove(pendingBrackets, #pendingBrackets)
		end
	end

	table.insert(lexer.tokens, setmetatable(tokenData, tokenFunctions))
	return tokenData
end

function tokenFunctions:__tostring()
	return self.trailingWhitespace .. self.content .. self.leadingWhitespace
end

export type TokenOptions = {
	type: string,
	content: string,
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
