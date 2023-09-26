local parent = require("init")
local node = setmetatable({
	priority = 1,
	type = "expression_localDeclaration"
}, { __index = parent })

local token = require("../../../lexer/token")
local tokenTypes = require("../../../lexer/tokenData").types

local equalsValues = require("../equalsValues")
local expression = require("../expression")

local parserUtils = require("../../../utils/parser")

function node.new(
	localToken: token.TokenObject,
	identifierTokens: { token.TokenObject },
	equalsValues: equalsValues.node?,
	leadingWhitespace: string?,
	trailingWhitespace: string?
): node
	if not leadingWhitespace then 
		if equalsValues then 
			leadingWhitespace = equalsValues.leadingWhitespace
			equalsValues.leadingWhitespace = ""
		else 
			leadingWhitespace = identifierTokens[#identifierTokens].leadingWhitespace
			identifierTokens[#identifierTokens].leadingWhitespace = ""
		end 
	end

	if not trailingWhitespace then 
		trailingWhitespace = localToken.trailingWhitespace
		localToken.trailingWhitespace = ""
	end

	return setmetatable({
		localToken = localToken,
		identifiers = identifierTokens,
		equalsValues = equalsValues,
		leadingWhitespace = leadingWhitespace,
		trailingWhitespace = trailingWhitespace
	} :: nodeClass, { __index = node })
end

function node.condition(tokens: { token.TokenObject }, parser): (number?, node?)
	-- check if we have any tokens that meet our expectations
	if #tokens < 2 then
		return
	end

	if tokens[1].type == tokenTypes.keyword and tokens[1].content == "local" then
		if tokens[2].type ~= tokenTypes.identifier then
			parser:error(`Expected identifier when parsing variable name, got {tokens[2].type}`, tokens[2])
			return 2
		end

		-- find identifiers
		local identifiers = {}
		local idx = 2
		local whitespace

		while idx <= #tokens do 
			if tokens[idx].type == tokenTypes.identifier then 
				if whitespace then 
					tokens[idx].trailingWhitespace ..= whitespace
					whitespace = nil
				end

				table.insert(identifiers, tokens[idx])
				idx += 1
			elseif tokens[idx].type == tokenTypes.punctutation and tokens[idx].content == "," then 
				if #identifiers == 0 then 
					parser:error("Expected identifier, got \",\" on local variable declaration", tokens[idx])
					return idx
				end

				identifiers[#identifiers].leadingWhitespace ..= tokens[idx].trailingWhitespace
				whitespace = tokens[idx].leadingWhitespace

				idx += 1
			else 
				break
			end
		end

		local ev
		if tokens[idx].type == tokenTypes.punctutation and tokens[idx].content == "=" then
			-- parse expressions
			local trimmed = parserUtils.trimTokens(tokens, idx+1)
			local hasErrored = false

			local expressions, pointer = expression.parseList(trimmed, function(msg, tkn)
				hasErrored = true
				parser:error(msg, tkn or tokens[idx])
			end)

			if hasErrored then 
				return idx-1 + pointer
			end

			ev = equalsValues.new(tokens[idx], expressions)
			idx += pointer
		end

		local variableDeclaration = node.new(tokens[1], identifiers, ev)
		return idx, variableDeclaration
	end

	return
end

function node.toString(self: node)
	return `{self.trailingWhitespace}{self.localToken}{parserUtils.concat(self.identifiers, ",")}{self.equalsValues:toString()}{self.leadingWhitespace}`
end

type nodeClass = {
	localToken: token.TokenObject,
	identifiers: { token.TokenObject },
	equalsValues: equalsValues.node,
	trailingWhitespace: string,
    leadingWhitespace: string,
}

type node = typeof(setmetatable({} :: nodeClass, { __index = parent }))

return node
