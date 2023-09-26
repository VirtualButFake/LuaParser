local node = {
	type = "base"
}

-- global functions that each node has

export type Node = typeof(setmetatable(
	{} :: {
		leadingWhitespace: string,
		trailingWhitespace: string,
		type: string,
		[string]: any,
	},
	node
))

return node
