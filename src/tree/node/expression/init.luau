local parent = require("../init")
local node = setmetatable({
	type = "expression",
}, { __index = parent })

local token = require("../../../lexer/token")

local expressions = {}

function node.registerExpression(expression: node, priority: number)
	table.insert(expressions, {
		node = expression,
		priority = priority,
	})

	table.sort(expressions, function(a, b)
		return a.priority > b.priority
	end)
end

function node.parse(tokens: { token.TokenObject }, reportError)
    -- checks if it can find an expression at the start of the table, otherwise returns nil
    for _, expression in expressions do
        local node, advanceAmount = expression.node.condition(tokens, reportError)

        if node or advanceAmount then
            for i = 1, advanceAmount do
                table.remove(tokens, 1)
            end

            return node, advanceAmount
        end
    end

    return
end

function node.parseList(tokens: { token.TokenObject }, reportError)
	local pointer = 0
	local tokenSize = #tokens
	local list = {}

	-- the token table is expected to be a cloned one, so we should be able to modify it
	-- this is pretty much just a copy of the actual parser, just with different nodes
    local commaToken

	while pointer <= tokenSize do
		local foundNode = false

		if tokens[1] and tokens[1].type == "punctuation" and tokens[1].content == "," and #list > 0 then
			-- add trailing whitespace of comma to last node & add leading whitespace to the next node
            list[#list].leadingWhitespace = list[#list].leadingWhitespace .. tokens[1].trailingWhitespace
            commaToken = tokens[1]
            
            table.remove(tokens, 1)
			pointer += 1
		end

		for _, expression in expressions do
			local node, advanceAmount = expression.node.condition(tokens, reportError)

			if node or advanceAmount then
                foundNode = true

				for i = 1, advanceAmount do
					table.remove(tokens, 1)
					pointer += 1
				end

                if node then 
                    table.insert(list, node)

                    if commaToken then 
                        node.trailingWhitespace ..= commaToken.leadingWhitespace
                        commaToken = nil
                    end 
                end
			end

            if foundNode then
                break
            end
		end

        if not foundNode then
            if commaToken and tokens[1] ~= nil then 
                pointer += 1
                reportError("Tried to parse expression after \",\", no expression type found", tokens[1])
            elseif commaToken then 
                reportError("Expected expression after \",\", got nothing", commaToken)
                break
            else
                reportError(`Expected expression, got nothing when trying to parse expression list`)
            end
        end

		if #tokens == 0 or tokens[1].type ~= "punctuation" or tokens[1].content ~= "," then
			break
		end
	end

	return list, pointer
end

function node.__tostring(self: node)
	return
end

type nodeClass = {
    leadingWhitespace: string,
    trailingWhitespace: string
}

export type node = typeof(setmetatable({} :: nodeClass, { __index = parent }))

return node
