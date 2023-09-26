local stdio = require("@lune/stdio")

local defs = require("../src/tree/definitions")
local logger = require("../src/utils/logger")

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
    response = response or {}
    table.insert(response, index)

	if typeof(value) == "table" and value.priority then 
		table.insert(nodeList, {
            index = response,
            priority = value.priority
        })

        return nil
	end 

    return response
end)

table.sort(nodeList, function(a, b)
	return a.priority > b.priority
end)

for i, node in nodeList do 
    logger.info(`[{i}]: Index: {table.concat(node.index, ".")} | Priority: {node.priority}`)
end

