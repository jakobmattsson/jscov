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
    var noop = function() { return null; };
    if (a) {
      f();
    } else {
      noop();
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
    var result = predicate ? (function() { return x+y; }()) : pred2 ? (function() { return f(g(1, 2, 3)); }()) : (function(){ return v3; }());
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
    var noop = function() { return null; };
    if (a) {
      f();
    } else if (b) {
      g();
    } else {
      noop();
    }
  '''
}, {
  name: 'and'
  input: '''
    if (a && b) {
      f();
    }
  '''
  output: '''
    var noop = function() { return null; };
    if (a) {
      if (b) {
        f();
      } else {
        noop();
      }
    } else {
      noop();
    }
  '''
}, {
  name: 'or'
  input: '''
    if (a || b) {
      f();
    }
  '''
  output: '''
    var noop = function() { return null; };
    if (a) {
      f();
    } else if (b) {
      f();
    } else {
      noop();
    }
  '''
}, {
  name: 'andor'
  input: '''
    if (a || b && c) {
      f();
    }
  '''
  output: '''
    var noop = function() { return null; };
    if (a) {
      f();
    } else if (b) {
      if (c) {
        f();
      } else {
        noop();
      }
    } else {
      noop();
    }
  '''
}, {
  name: 'andor-parenthesis'
  input: '''
    if ((a || b) && c) {
      f();
    }
  '''
  output: '''
    var noop = function() { return null; };
    if (a) {
      if (c) {
        f();
      } else {
        noop();
      }
    } else if (b) {
      if (c) {
        f();
      } else {
        noop();
      }
    } else {
      noop();
    }
  '''
}, {
  name: 'andor-complex'
  input: '''
    if ((a() || b()) && !c()) {
      f();
    }
  '''
  output: '''
    var noop = function() { return null; };
    if (a()) {
      if (!c()) {
        f();
      } else {
        noop();
      }
    } else if (b()) {
      if (!c()) {
        f();
      } else {
        noop();
      }
    } else {
      noop();
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
