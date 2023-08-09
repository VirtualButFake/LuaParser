-- token types mapped to their patterns - lexer checks if a string meets a pattern in here

return {
	-- all patterns were taken from https://github.com/boatbomber/Highlighter/blob/main/src/lexer/init.lua
	-- no point in reinventing the wheel (and also an excuse for my shameless copying and totally not my lack of knowledge about string patternsa)
	patterns = {
		identifier = {
			"[%a_][%w_]*", -- generic identifier
			"[%z\x01-\x7F\xC2-\xF4][\x80-\xBF]+", -- unicode, don't know specific use for this but highlighter uses it as a pattern so it's probably something important lol
		},
		number = {
			"0[xX][%da-fA-F_]+", -- hex (0x1)
			"0[bB][01_]+", -- binary (0b1)
			"%d+%.?%d*[eE][%+%-]?%d+", -- scientific notation (for ex. 0e5)
			"%d+[%._]?[%d_eE]*", -- normal numbers (for ex. 5 or 0.5)
		},
		string = {
			"(['\"])%1", -- empty string (for ex. "")
			"(['\"])[^\n]-([^\\]%1)", -- normal string (for ex. "hi")
			"`[^\n]-`", -- string interpolation (for ex. `hi`)
			"(['\"]).-\n", -- string crossing lines
			"(['\"])[^\n]*", -- string crossing lines w/o \n
			"%[(=*)%[.-%]%1%]", -- multiline string (for ex. [[hi\nhi]], but with \n as a newline)
			"%[=*%[.-.*", -- incompleted multiline string (for ex. [[ hi )
		},
		punctuation = {
			"[:;<>/~%*%(%)%-={},%.#%^%+%%]",
			"[%[%]]+",
		},
		comment = {
			"%-%-%[(=*)%[.-%]%1%]", -- multiline comment
			"%-%-%[=*%[.-.*", -- incompleted mutiline comment
			"%-%-.-\n", -- completed singleline
			"%-%-.*", -- incompleted singleline
		},
		cleaners = {
			prefix = "^[%c%s]*",
			suffix = "[%c%s]*",
			cleaner = "[%c%s]+",
		},
	},
	order = {
		"identifier",
		"number",
		"string",
		"comment",
		"punctuation",
	},
	keywords = {
		"and",
		"break",
		"do",
		"else",
		"elseif",
		"end",
		"false",
		"for",
		"function",
		"goto",
		"if",
		"in",
		"local",
		"nil",
		"not",
		"or",
		"repeat",
		"return",
		"then",
		"true",
		"until",
		"while",
		"local"
	},
	types = {
		keyword = "keyword",
		identifier = "identifier",
		number = "number",
		string = "string",
		punctutation = "punctuation",
		comment = "comment",
	},
}
