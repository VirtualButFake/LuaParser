local parent = require("init")
local node = setmetatable({
	type = "expression_operator",
}, { __index = parent })

parent.registerExpression(node, 3)

local token = require("../../../lexer/token")
local tokenTypes = require("../../../lexer/tokenData").types

function node.new(
	literalToken: token.TokenObject,
	literalType: string,
	leadingWhitespace: string?,
	trailingWhitespace: string?
): node
	if not leadingWhitespace then
		
	end

	if not trailingWhitespace then
		
	end

	return setmetatable({
		
	} :: nodeClass, { __index = node })
end

local operators = "[+%-/%%^]"

function node.condition(tokens: { token.TokenObject }, reportError: (string, token.TokenObject) -> ()): (node?, number?)
	-- check if we've got a number on the left & an operator next to it
	if tokens[1].type == tokenTypes.number and tokens[2].type == tokenTypes.punctutation and tokens[2].content:match(operators) then 
		
	end 

	return
end

function node.toString(self: node)
    return `{self.trailingWhitespace}INSERT HERE{self.leadingWhitespace}`
end

type nodeClass = {
	
}

export type node = typeof(setmetatable({} :: nodeClass, { __index = parent }))

return node
