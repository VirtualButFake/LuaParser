local fs = require("@lune/fs")

local lexer = require("../../src/lexer")
local parser = require("../../src/tree")

local tokens = lexer.scan(fs.readFile("tests/samples/test.luau"))
local nodes = parser.parse(tokens)