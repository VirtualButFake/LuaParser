local parent = require("init")
local node = setmetatable({
	type = "expression_literal",
}, { __index = parent })

parent.registerExpression(node, 1)

local token = require("../../../lexer/token")
local tokenTypes = require("../../../lexer/tokenData").types

function node.new(
	literalToken: token.TokenObject,
	literalType: string,
	leadingWhitespace: string?,
	trailingWhitespace: string?
): node
	if not leadingWhitespace then
		leadingWhitespace = literalToken.leadingWhitespace
		literalToken.leadingWhitespace = ""
	end

	if not trailingWhitespace then
		trailingWhitespace = literalToken.trailingWhitespace
		literalToken.trailingWhitespace = ""
	end

	return setmetatable({
		literalToken = literalToken,
		literalType = literalType,
		leadingWhitespace = leadingWhitespace,
		trailingWhitespace = trailingWhitespace,
	} :: nodeClass, { __index = node })
end

function node.condition(tokens: { token.TokenObject }, reportError: (string) -> ()): (node?, number?)
	if #tokens == 0 then
		return
	elseif tokens[1].type == tokenTypes.string and not tokens[1].closingString then
		return node.new(tokens[1], "string"), 1
	elseif tokens[1].type == tokenTypes.number then
		return node.new(tokens[1], "number"), 1
	elseif tokens[1].type == tokenTypes.keyword then
		if tokens[1].content == "true" or tokens[1].content == "false" then
			return node.new(tokens[1], "bool"), 1
		elseif tokens[1].content == "nil" then
			return node.new(tokens[1], "nil"), 1
		end
	end

	return
end

function node.setValue(self: node, value: any): boolean
	-- re-evaluates with this value, returns true if success
	if typeof(value) == "string" then 
        self.literalToken.content = `"{value}"`
    elseif typeof(value) == "number" then 
        self.literalToken.content = `{value}`
    elseif typeof(value) == "boolean" then 
        self.literalToken.content = `{value}`
    elseif value == nil then 
        self.literalToken.content = "nil"
    else 
        return false
	end

    return true
end

function node.toString(self: node)
    return `{self.trailingWhitespace}{self.literalToken}{self.leadingWhitespace}`
end

type nodeClass = {
	literalToken: token.TokenObject,
	leadingWhitespace: string,
	trailingWhitespace: string,
	literalType: string,
}

export type node = typeof(setmetatable({} :: nodeClass, { __index = parent }))

return node
