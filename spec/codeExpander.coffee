should = require 'should'
escodegen = require 'escodegen'
esprima = require 'esprima'
expander = require('./coverage').require 'expander'
jscov = require '../lib/jscov'

cases = [{
  name: 'if'
  input: '''
    if (a) {
      f();
    }
  '''
  output: '''
    var __noop__ = function() { return null; };
    if (a) {
      f();
    } else
      __noop__();
  '''
}, {
  name: 'ternary'
  input: '''
    var result = predicate ? v1 : v2;
  '''
  output: '''
    var result = (function() {
      if (predicate)
        return v1;
      else
        return v2;
    }());
  '''
}, {
  name: 'complex-ternary'
  input: '''
    var result = predicate ? x+y : pred2 ? f(g(1, 2, 3)) : v3;
  '''
  output: '''
    var result = (function() {
      if (predicate)
        return x+y;
      else
        return (function() {
          if (pred2)
            return f(g(1, 2, 3));
          else
            return v3;
        }());
    }());
  '''
}, {
  name: 'ifelse'
  input: '''
    if (a) {
      f();
    } else {
      g();
    }
  '''
  output: '''
    if (a) {
      f();
    } else {
      g();
    }
  '''
}, {
  name: 'ifelseif'
  input: '''
    if (a) {
      f();
    } else if (b) {
      g();
    }
  '''
  output: '''
    var __noop__ = function() { return null; };
    if (a) {
      f();
    } else if (b) {
      g();
    } else
      __noop__();
  '''
}, {
  name: 'and-assign'
  input: '''
    var x = a() && b();
  '''
  output: '''
    var x = (function() {
      var __lhs__ = a();
      if (__lhs__)
        return b();
      else
        return __lhs__;
    }());
  '''
}, {
  name: 'and-assign-constant'
  input: '''
    var x = 5 && b();
  '''
  output: '''
    var x = (function() {
      if (5)
        return b();
      else
        return 5;
    }());
  '''
}, {
  name: 'and-assign-literal'
  input: '''
    var x = variable && b();
  '''
  output: '''
    var x = (function() {
      if (variable)
        return b();
      else
        return variable;
    }());
  '''
}, {
  name: 'or-assign'
  input: '''
    var x = a() || b();
  '''
  output: '''
    var x = (function() {
      var __lhs__ = a();
      if (__lhs__)
        return __lhs__;
      else
        return b();
    }());
  '''
}, {
  name: 'andor-complex'
  input: '''
    if ((a() || b()) && !c()) {
      f();
    }
  '''
  output: '''
    var __noop__ = function() { return null; };
    if ((function() {
      var __lhs__ = (function() {
        var __lhs__ = a();
        if (__lhs__)
          return __lhs__;
        else
          return b();
      }());
      if (__lhs__)
        return !c();
      else
        return __lhs__;
    }())) {
      f();
    } else
      __noop__();
  '''
}]



cases.forEach (data) ->
  it "should transform #{data.name} properly", (done) ->
    ast = esprima.parse(data.input)
    expandedAst = expander.expand(ast)
    expandedCode = escodegen.generate(expandedAst, { indent: "  " })
    expectedCode = escodegen.generate(esprima.parse(data.output), { indent: "  " })
    expandedCode.should.eql expectedCode
    done()



it "should tranform strings too", (done) ->
  data = cases[0]
  output = expander.expand(data.input)
  output.should.be.a.string
  expandedCode = escodegen.generate(esprima.parse(output), { indent: "  " })
  expectedCode = escodegen.generate(esprima.parse(data.output), { indent: "  " })
  expandedCode.should.eql expectedCode
  done()

it "should work on all testfiles", (done) ->
  jscov.rewriteFolder 'spec/scaffolding/scaffold', 'spec/.output/expanded', { expand: true }, (err) ->
    should.not.exist err
    done()
