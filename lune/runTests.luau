local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local tests = fs.readDir("./tests")

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
		`tests/{path}`,
	}, {
		cwd = process.cwd,
	})

	timer = os.clock() - timer

	if output.stdout:find("success") then
		writeOut({
			{ "[", "black" },
			{ "SUCCESS", "green" },
			{ "]", "black" },
			{ ` Test {path} succeeded in {math.floor(timer * 1000) / 1000}s`, "reset" },
		})
    else 
        writeOut({
			{ "[", "black" },
			{ "FAILED", "red" },
			{ "]", "black" },
			{ ` Test {path} failed:`, "reset" },
		})
        print(output)
	end
end
