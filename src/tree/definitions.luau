-- Automatically generated file (lune/buildNodeDefinitions/init.lua)

return {
  equalsValues = require('./node/equalsValues'),
  token = require('../lexer/token'),
  init = require('./node/init'),
  statement = {
    localDeclaration = require('./node/statement/localDeclaration'),
    init = require('./node/statement/init')
  },
  expression = {
    operator = require('./node/expression/operator'),
    interpolatedString = require('./node/expression/interpolatedString'),
    literal = require('./node/expression/literal'),
    init = require('./node/expression/init')
  }
}