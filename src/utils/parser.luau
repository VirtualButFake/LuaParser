local utils = {}

local token = require("../lexer/token")

function utils.getDebug(
	token: token.TokenObject | {
		tokenStart: number,
		tokenEnd: number,
	},
	sourceText: string
): number
	local containingSource = sourceText:sub(1, token.tokenEnd)
	local split = utils.cleanLine(containingSource):split("\n") -- we clean it here to prevent cases where \n is pasted at the end of the line

	local precedingSize = 0
	for i, text in split do
		if i == #split then
			break
		end

		precedingSize += #text + 1 -- +1 for \n (counts as 1 char)
	end

	return #split,
		token.tokenStart - precedingSize,
		math.clamp(token.tokenEnd - precedingSize, 0, #utils.cleanLine(split[#split])) -- clean here to prevent newlines from taking up space
end

function utils.cleanLine(line: string): string
	return line:gsub("[%s%c]+$", "") -- cleans whitespace at end of line
end

function utils.trimTokens(tokens: { token.TokenObject }, idx)
	local newTable = {}

	for i, token in tokens do
		if i < idx then
			continue
		end

		table.insert(newTable, token)
	end

	return newTable
end

function utils.concat(nodes, seperator)
	local results = {}

	for _, node in nodes do 
		table.insert(results, node.toString and node:toString() or `{node.trailingWhitespace}{node.content}{node.leadingWhitespace}`)
	end

	return table.concat(results, seperator)
end

return utils
