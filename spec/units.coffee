fs = require 'fs'
should = require 'should'
jscov = require('./coverage').require 'jscov'
tools = require('./coverage').require 'tools'
estools = require('./coverage').require 'estools'
ftools = require('./coverage').require 'jscoverage-formatting-tools'
jscovFormat = require('./coverage').require 'jscoverage-formatting'



describe "evalBinaryExpression", ->
  it "should evaluate binary operators using evalBinaryExpression as expected", ->
    ftools.evalBinaryExpression(1, '+', 2).should.eql 3

  it "should throw an exception if given an invalid operator", ->
    f = -> ftools.evalBinaryExpression(1, '%%', 2)
    f.should.throw()



describe "jscov", ->
  it "should cover files using the JSCOV environemnt variable", ->
    oldCov = process.env.JSCOV

    delete process.env.JSCOV
    jscov.cover('a', 'b', 'c').should.eql 'a/b/c'

    process.env.JSCOV = 'foobar'
    jscov.cover('a', 'b', 'c').should.eql 'a/foobar/c'

    process.env.JSOV = oldCov

  it "should return error when given invalid parameters", ->
    jscov.rewriteFolder 'folder-does-not-exists', 'neither-does-this', {}, (err) ->
      should.exist err

  it "should expand the file when the option 'expand' is given", ->
    jscov.rewriteFile(__dirname, 'scaffolding/scaffold/concattenation.js', "#{__dirname}/.output/unit-expand", { expand: true })
    fs.readFileSync("#{__dirname}/.output/unit-expand/scaffolding/scaffold/concattenation.js", 'utf8').indexOf('&&').should.eql -1

    jscov.rewriteFile(__dirname, 'scaffolding/scaffold/concattenation.js', "#{__dirname}/.output/unit-no-expand", { expand: false })
    fs.readFileSync("#{__dirname}/.output/unit-no-expand/scaffolding/scaffold/concattenation.js", 'utf8').indexOf('&&').should.not.eql -1



describe "estools", ->
  it "should throw an exception if 'evalLiteral' is called for a non-literal", ->
    f = -> ftools.evalLiteral({ foo: 'bar' })
    f.should.throw()

  it "should throw an exception if 'evalLiteral' is called for a non-literal", ->
    ftools.evalLiteral({ type: 'Literal', value: 5 }).should.eql 5
