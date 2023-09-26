-- tree builder from tokens
local syntaxParser = {}
local token = require("../lexer/token")
local defs = require("definitions")
local utils = require("../utils/parser")
local logger = require("../utils/logger")

-- require all nodes and find the order
local function iterateTable(entry, callback, resp)
	for index, value in entry do
		local newResp = callback(index, value, resp)

		if typeof(value) == "table" then
			iterateTable(value, callback, newResp)
		end
	end
end

local nodeList = {}

iterateTable(defs, function(index, value, response)
	if typeof(value) == "table" and value.priority then
		table.insert(nodeList, value)
	end
end)

table.sort(nodeList, function(a, b)
	return a.priority > b.priority
end)

function syntaxParser.toString(self)
	local totalString = ""

	for _, token in self.nodes do
		totalString = totalString .. token:toString()
	end

	return totalString
end

function syntaxParser.parse(tokens: { token.TokenObject })
	local self = setmetatable({
		tokens = tokens,
		nodes = {},
		sourceText = utils.concat(tokens),
		errors = {} :: { syntaxError },
	}, { __index = syntaxParser })

	local tokenSize = #tokens
	local progress = 1

	while progress <= tokenSize do
		local foundNode = false

		--self.sourceText = self.sourceText .. tostring(tokens[1])

		for _, node in nodeList do
			local advance, response = node.condition(self.tokens, self)

			if not response and not advance then
				continue
			end

			foundNode = true

			if response then
				table.insert(self.nodes, response)
			end

			if advance then
				-- delete all skipped over nodes
				-- do this because making token[1] be the first token instead of token[pointer+1] is cleaner
				for i = 1, advance do
					if self.tokens[1] and i ~= 1 then
						--self.sourceText = self.sourceText .. tostring(tokens[1])
					end

					table.remove(self.tokens, 1) -- remoev 1 bc it'll keep going down
				end

				progress += advance
			end
		end

		if not foundNode then
			self:error(
				"[DEBUG] Failed to find node for string of tokens\n(this error exists so i can see what nodes i need to add)",
				self.tokens[1]
			)
			self:abort()
			return
		end
	end

	if #self.errors ~= 0 then
		self:abort()
		return
	end
end

function syntaxParser:error(msg: string, tokenStart: token.TokenObject)
	table.insert(self.errors, {
		token = tokenStart,
		message = msg,
	})
end

function syntaxParser:abort()
	local errorMessages = {}
	local splitSource = self.sourceText:split("\n")

	for _, syntaxError: syntaxError in self.errors do
		local line, startIndex, endIndex = utils.getDebug(syntaxError.token, self.sourceText)
		local cleanLine = utils.cleanLine(splitSource[line])

		local prefix = (" "):rep(startIndex - 1)

		local arrowLength = math.clamp(endIndex, 0, #cleanLine) - (startIndex - 1) -- -1 because when the startindex = endindex we still want an arrow
		local arrow = ("^"):rep(arrowLength)

		table.insert(
			errorMessages,
			`{cleanLine}\n{prefix}{arrow}\n{syntaxError.message} (line {line}, character {startIndex}:{endIndex})`
		)
	end

	logger.info("Tokens:")
	require("@lune/fs").writeFile("output.json", require("@lune/serde").encode("json", self.nodes, true))

	logger.info("Output: " .. self:toString())

	logger.error(`Error(s) occured while parsing tokens:\n{table.concat(errorMessages, "\n")}`)
end

type syntaxError = {
	token: token.TokenObject,
	message: string,
}

return syntaxParser
