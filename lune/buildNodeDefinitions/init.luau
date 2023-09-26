local fs = require("@lune/fs")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local logger = require("../../src/utils/logger")

local nodeMap = {
	token = "require('../lexer/token')",
}
local basePath = "./src/tree/node"
local filePath = "./src/tree/definitions.luau"

local function iterateDir(path, callback: (path: string, dir: boolean) -> ())
	local files = fs.readDir(path)

	for _, file in files do
		local filePath = `{path}/{file}`

		if fs.isDir(filePath) then
			callback(filePath, true)
			iterateDir(filePath, callback)
		else
			callback(filePath, false)
		end
	end
end

local function traverseMap(path)
	local currentMap = nodeMap
	local dirs = path:split("/")

	for i = 1, #dirs - 1 do
		local index = dirs[i]

		if index:find("init.lua") then
			index = "base"
		end

		if currentMap[index] == nil then
			currentMap[index] = {}
		end

		currentMap = currentMap[index]
	end

	return currentMap, dirs[#dirs]
end

local function iterateTable(entry, callback, depth)
	depth = depth or 0

	for index, value in entry do
		callback(index, value, depth + 1)

		if typeof(value) == "table" then
			iterateTable(value, callback, depth + 1)
		end
	end
end

local start = os.clock()

iterateDir(basePath, function(path, dir)
	local addedPath = path:gsub(basePath .. "/", "")
	local mapEntry, lastEntry = traverseMap(addedPath)
	addedPath = `require('./node/{addedPath:gsub(".luau", "")}\')` -- to make the requires work

	if lastEntry == "init.lua" then
		mapEntry.base = addedPath
	else
		if dir then
			mapEntry[lastEntry] = {}
		else
			local split = lastEntry:split(".")
			table.remove(split, #split)

			mapEntry[table.concat(split, ".")] = addedPath
		end
	end
end)

local returnString = serde.encode("json", nodeMap, true):gsub('"', ""):gsub(":", " =")
local fileContents = fs.readFile("./lune/buildNodeDefinitions/base.txt"):gsub("NODE_MAP", returnString)
fs.writeFile(filePath, fileContents)

logger.success(
	`Wrote new node definition map to file. Took {math.floor((os.clock() - start) * 100000) / 100000} seconds`
)
