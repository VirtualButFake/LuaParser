local parent = require("../init")
local node = setmetatable({
    type = "statement"
}, { __index = parent })

return node
