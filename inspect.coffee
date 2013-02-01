fs = require 'fs'
esprima = require 'esprima'
escodegen = require 'escodegen'
path = require 'path'
jscov = require './src/jscov'
util = require 'util'

code = fs.readFileSync(path.join(__dirname, 'expected.js'), 'utf8')
parse1 = esprima.parse(code, { loc: false })


console.log util.inspect(parse1, null, 100)
