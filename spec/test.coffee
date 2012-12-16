fs = require 'fs'
should = require 'should'
esprima = require 'esprima'
_ = require 'underscore'
cov = require '../lib/coverage'

fs.readdirSync('spec/scaffold').forEach (filename) ->

  code = fs.readFileSync('spec/scaffold/' + filename, 'utf8')
  newCode = cov.rewrite(code, filename)
  actualParse = esprima.parse(newCode)

  expect = fs.readFileSync('spec/out/' + filename, 'utf8')
  expectedParse = esprima.parse(expect)

  it "should parse #{filename} the same way as jscoverage", ->
    _.isEqual(actualParse, expectedParse).should.be.true

# testa så att command-line programmet funkar rekursivt
# testa så att dollar-tecken i regexpar funkar
# kanske dra in lite kod som andra skrivit, för att få lite andra stilar att testa
