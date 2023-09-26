local parent = require("init")
local node = setmetatable({
	type = "expression_interpolatedString",
}, { __index = parent })

parent.registerExpression(node, 2)

local token = require("../../../lexer/token")
local tokenTypes = require("../../../lexer/tokenData").types

local parserUtils = require("../../../utils/parser")

local literal = require("./literal")

function node.new(stringSegments: { parent.node }, leadingWhitespace: string?, trailingWhitespace: string?): node
	if not leadingWhitespace and #stringSegments > 0 then
		local segment = stringSegments[#stringSegments]
		leadingWhitespace = segment.leadingWhitespace
		segment.leadingWhitespace = ""
	end

	if not trailingWhitespace and #stringSegments > 0 then
		local segment = stringSegments[1]
		trailingWhitespace = segment.trailingWhitespace
		segment.trailingWhitespace = ""
	end

	return setmetatable({
		stringSegments = stringSegments,
		leadingWhitespace = leadingWhitespace or "",
		trailingWhitespace = trailingWhitespace or "",
	} :: nodeClass, { __index = node })
end

function node.condition(
	tokens: { token.TokenObject },
	reportError: (string, token.TokenObject?) -> ()
): (node?, number?)
	if tokens[1].type == tokenTypes.string and tokens[1].closingString then
		-- get all tokens until the closing token
		local pointer = 1
		local tokenList = { } :: { stringSegment }

		local didExpression = false

		while tokens[pointer] ~= nil do
			if tokens[pointer].isExpression then
				if didExpression then
					reportError("2 expressions found where only 1 was expected", tokens[pointer])
					return nil, pointer
				end

				local expression, advance = parent.parse(parserUtils.trimTokens(tokens, pointer), reportError)
				table.insert(tokenList, {
					kind = "expression",
					node = expression
				})
				pointer += advance
				didExpression = true

				continue
			else
				didExpression = false
				tokens[pointer].content = tokens[pointer].content:gsub("^[{}]",""):gsub("[{}]$","") -- trim characters for string interpolation; we won't need them anymore
				table.insert(tokenList, {
					kind = "string",
					node = literal.new(tokens[pointer], "string")
				})
			end

			if tokens[pointer] == tokens[1].closingString then
				break
			end

			pointer += 1
		end

		return node.new(tokenList), pointer	
	end

	return
end

function node.setValue(self: node, value: any): boolean
	-- re-evaluates with this value, returns true if success
	return true
end

function node.toString(self: node)
	local result = ""

	if self.stringSegments then
		for _, expression in self.stringSegments do 
			if expression.kind == "string" then
				result ..= expression.node:toString()
			else 
				result ..= `\{{expression.node:toString()}\}`
			end
		end
	else 
		result = '``'
	end 

	return `{self.trailingWhitespace}{result}{self.leadingWhitespace}`
end

type nodeClass = {
	stringSegments: { parent.node | literal.node },
	leadingWhitespace: string?,
	trailingWhitespace: string?,
}

type stringSegment = {
	kind: "expression" | "string",
	node: parent.node
}

type node = typeof(setmetatable({} :: nodeClass, { __index = parent }))

return node
