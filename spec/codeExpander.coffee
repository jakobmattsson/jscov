should = require 'should'
escodegen = require 'escodegen'
esprima = require 'esprima'
expander = require('./coverage').require 'expander'

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
    } else {
      __noop__();
    }
  '''
}, {
  name: 'ternary'
  input: '''
    var result = predicate ? v1 : v2;
  '''
  output: '''
    var result = predicate ? (function() { return v1; }()) : (function() { return v2; }());
  '''
}, {
  name: 'complex-ternary'
  input: '''
    var result = predicate ? x+y : pred2 ? f(g(1, 2, 3)) : v3;
  '''
  output: '''
    var result = predicate ? (function() { return x+y; }()) : (function() { return pred2 ? (function() { return f(g(1, 2, 3)); }()) : (function(){ return v3; }()) }());
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
    } else {
      __noop__();
    }
  '''
}, {
  name: 'and-assign'
  input: '''
    var x = a() && b();
  '''
  output: '''
    var x = (function() {
      var __lhs__ = a();
      if (__lhs__) {
        return b();
      } else {
        return __lhs__;
      }
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
      if (__lhs__) {
        return __lhs__;
      } else {
        return b();
      }
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
        if (__lhs__) {
          return __lhs__;
        } else {
          return b();
        }
      }());
      if (__lhs__) {
        return !c();
      } else {
        return __lhs__;
      }
    }())) {
      f();
    } else {
      __noop__();
    }
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
