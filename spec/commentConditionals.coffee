fs = require 'fs'
should = require 'should'
escodegen = require 'escodegen'
esprima = require 'esprima'
wrench = require 'wrench'
coffee = require 'coffee-script'
jscov = require('./coverage').require 'jscov'
conditionals = require('./coverage').require 'conditionals'

cases = [{
  name: 'One comment'
  input: '''
    var a = 1 + 2;
    // JSCOV: a > 5
  '''
  output: '''
    var __noop__cc__ = function() {};
    var a = 1 + 2;
    if (a > 5) { __noop__cc__() } else { __noop__cc__() };
  '''
}, {
  name: 'No content'
  input: '''
    var a = 1 + 2;
    // JSCOV:     
  '''
  output: '''
    var a = 1 + 2;
    // JSCOV:     
  '''
}, {
  name: 'No comments'
  input: '''
    var a = 1 + 2;
  '''
  output: '''
    var a = 1 + 2;
  '''
}, {
  name: 'Two comments'
  input: '''
    var a = 1 + 2;
    // JSCOV: a > 5
    // JSCOV: a < 5
  '''
  output: '''
    var __noop__cc__ = function() {};
    var a = 1 + 2;
    if (a > 5) { __noop__cc__() } else { __noop__cc__() };
    if (a < 5) { __noop__cc__() } else { __noop__cc__() };
  '''
}, {
  name: 'Coffee script'
  coffee: true
  input: '''
    a = 1 + 2
    # JSCOV: a > 5
  '''
  output: '''
    __noop__cc__ = (->)
    a = 1 + 2
    if (a > 5) then __noop__cc__() else __noop__cc__()
  '''
}, {
  name: 'Coffee script param with JS code'
  coffee: true
  input: '''
    var a = 1 + 2;
    // JSCOV: a > 5
  '''
  output: '''
    var a = 1 + 2;
    // JSCOV: a > 5
  '''
}, {
  name: 'Comment not on its own line'
  input: '''
    var a = 1 + 2;
    // JSCOV: a > 5
    var b = 2; // JSCOV: a < 5
  '''
  output: '''
    var __noop__cc__ = function() {};
    var a = 1 + 2;
    if (a > 5) { __noop__cc__() } else { __noop__cc__() };
    var b = 2; // JSCOV: a < 5
  '''
}, {
  name: 'Minimal space'
  input: '//JSCOV:a>5'
  output: '''
    var __noop__cc__ = function() {};
    if (a>5) { __noop__cc__() } else { __noop__cc__() };
  '''
}, {
  name: 'More space'
  input: '''
    //    JSCOV:    a  >  5    
  '''
  output: '''
    var __noop__cc__ = function() {};
    if (a  >  5) { __noop__cc__() } else { __noop__cc__() };
  '''
}, {
  name: 'Separating colon and identifier'
  input: '''
    //    JSCOV : a > 5
  '''
  output: '''
    //    JSCOV : a > 5
  '''
}]



cases.forEach (data) ->
  it "should transform #{data.name} properly", (done) ->
    if data.coffee
      output = conditionals.expand(data.input, { lang: 'coffee' })
    else
      output = conditionals.expand(data.input)
    output.should.eql data.output
    done()



it "should work on all testfiles", (done) ->
  jscov.rewriteFolder 'spec/scaffolding/scaffold', 'spec/.output/cc', { conditionals: true }, (err) ->
    should.not.exist err
    done()



it "should be possible to enable conditional comments", (done) ->
  jscov.rewriteFolder 'spec/scaffolding/conditionals', 'spec/.output/cc1', { conditionals: true }, (err) ->
    should.not.exist err

    expecting = {
      'cond-coffee.coffee': false
      'cond.js': false
      'nocond.js': true
      'nocond-coffee.coffee': true
    }

    Object.keys(expecting).forEach (file) ->
      input = fs.readFileSync("spec/scaffolding/conditionals/#{file}", 'utf8')
      input = coffee.compile(input) if file.match(/\.coffee$/)
      input = jscov.rewriteSource(input, file)
      output = fs.readFileSync("spec/.output/cc1/#{file.replace(/\.coffee$/, '.js')}", 'utf8')
      (input == output).should.eql expecting[file]

    done()



it "should be possible to disable conditional comments", (done) ->
  jscov.rewriteFolder 'spec/scaffolding/conditionals', 'spec/.output/cc2', { conditionals: false }, (err) ->
    should.not.exist err

    expecting = {
      'cond-coffee.coffee': true
      'cond.js': true
      'nocond.js': true
      'nocond-coffee.coffee': true
    }

    Object.keys(expecting).forEach (file) ->
      input = fs.readFileSync("spec/scaffolding/conditionals/#{file}", 'utf8')
      input = coffee.compile(input) if file.match(/\.coffee$/)
      input = jscov.rewriteSource(input, file)
      output = fs.readFileSync("spec/.output/cc2/#{file.replace(/\.coffee$/, '.js')}", 'utf8')
      (input == output).should.eql expecting[file]

    done()