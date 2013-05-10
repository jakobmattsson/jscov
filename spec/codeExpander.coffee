should = require 'should'
escodegen = require 'escodegen'
esprima = require 'esprima'
expander = require('./coverage').require 'expander'
jscov = require('./coverage').require 'jscov'

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
    var result = ((function(arguments) {
      if (predicate)
        return v1;
      else
        return v2;
    }).call(this, arguments));
  '''
}, {
  name: 'complex-ternary'
  input: '''
    var result = predicate ? x+y : pred2 ? f(g(1, 2, 3)) : v3;
  '''
  output: '''
    var result = ((function(arguments) {
      if (predicate)
        return x+y;
      else
        return ((function(arguments) {
          if (pred2)
            return f(g(1, 2, 3));
          else
            return v3;
        }).call(this, arguments));
    }).call(this, arguments));
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
    var x = ((function(arguments) {
      var __lhs__ = a();
      if (__lhs__)
        return b();
      else
        return __lhs__;
    }).call(this, arguments));
  '''
}, {
  name: 'and-assign-constant'
  input: '''
    var x = 5 && b();
  '''
  output: '''
    var x = ((function(arguments) {
      if (5)
        return b();
      else
        return 5;
    }).call(this, arguments));
  '''
}, {
  name: 'and-assign-literal'
  input: '''
    var x = variable && b();
  '''
  output: '''
    var x = ((function(arguments) {
      if (variable)
        return b();
      else
        return variable;
    }).call(this, arguments));
  '''
}, {
  name: 'or-assign-constant'
  input: '''
    var x = 5 || b();
  '''
  output: '''
    var x = ((function(arguments) {
      if (5)
        return 5;
      else
        return b();
    }).call(this, arguments));
  '''
}, {
  name: 'or-assign-literal'
  input: '''
    var x = variable || b();
  '''
  output: '''
    var x = ((function(arguments) {
      if (variable)
        return variable;
      else
        return b();
    }).call(this, arguments));
  '''
}, {
  name: 'or-assign'
  input: '''
    var x = a() || b();
  '''
  output: '''
    var x = ((function(arguments) {
      var __lhs__ = a();
      if (__lhs__)
        return __lhs__;
      else
        return b();
    }).call(this, arguments));
  '''
}, {
  name: 'this-and-arguments-variable'
  input: '''
    var x = this || arguments;
  '''
  output: '''
    var x = ((function(arguments) {
      var __lhs__ = this;
      if (__lhs__)
        return __lhs__;
      else
        return arguments;
    }).call(this, arguments));
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
    if (((function(arguments) {
      var __lhs__ = ((function(arguments) {
        var __lhs__ = a();
        if (__lhs__)
          return __lhs__;
        else
          return b();
      }).call(this, arguments));
      if (__lhs__)
        return !c();
      else
        return __lhs__;
    }).call(this, arguments))) {
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
