local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local logger = require("../src/utils/logger")

local tests = fs.readDir("./tests/scripts")

local function writeOut(textTable: { { string } })
	for _, textEntry in textTable do
		local text = textEntry[1]
		local color = textEntry[2]

		stdio.write(`{stdio.color(color)}{text}`)
	end

	stdio.write("\n")
end

for testIndex, path in tests do
	local timer = os.clock()

	local output = process.spawn(`lune`, {
		`tests/scripts/{path}`,
	}, {
		cwd = process.cwd,
	})

	timer = os.clock() - timer

	if output.stdout:find("success") then
		logger.success(`Test {path} succeeded in {math.floor(timer * 1000) / 1000}s`)
    else 
       	logger.error(`Test {path} failed:`)
        print(output)
	end
end
