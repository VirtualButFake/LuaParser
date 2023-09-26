local parent = require("init")
local node = setmetatable({
	type = "equalsvalues",
}, { __index = parent })

local token = require("../../lexer/token")
local tokenTypes = require("../../lexer/tokenData").types

local parserUtils = require("../../utils/parser")

function node.new(
	equalsToken: token.TokenObject,
	values,
	trailingWhitespace: string?,
	leadingWhitespace: string?
): node -- values = table with expressions, couldn't think of a nice way to do the type
	if not trailingWhitespace then
		trailingWhitespace = equalsToken.trailingWhitespace
		equalsToken.trailingWhitespace = ""
	end

	if not leadingWhitespace then
		leadingWhitespace = values[#values].leadingWhitespace
		values[#values].leadingWhitespace = ""
	end

	return setmetatable({
		equalsToken = equalsToken,
		values = values,
		trailingWhitespace = trailingWhitespace,
		leadingWhitespace = leadingWhitespace,
	} :: nodeClass, { __index = node })
end

function node.toString(self: node)
	return `{self.trailingWhitespace}{self.equalsToken}{parserUtils.concat(self.values, ",")}{self.leadingWhitespace}`
end

type nodeClass = {
	equalsToken: token.TokenObject,
	values: { any },
	trailingWhitespace: string,
	leadingWhitespace: string,
}

export type node = typeof(setmetatable({} :: nodeClass, { __index = parent }))

return node
