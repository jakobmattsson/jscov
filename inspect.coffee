fs = require 'fs'
esprima = require 'esprima'
escodegen = require 'escodegen'
path = require 'path'
jscov = require './src/coverage'
util = require 'util'

code = fs.readFileSync(path.join(__dirname, 'expected.js'), 'utf8')
parse1 = esprima.parse(code, { loc: true })


console.log util.inspect(parse1, null, 100)
