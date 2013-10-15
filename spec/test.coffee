fs = require 'fs'
should = require 'should'
esprima = require 'esprima'
wrench = require 'wrench'
_ = require 'underscore'
jscov = require('./coverage').require 'jscov'

output = "spec/.output"

describe "rewriteSource", ->

  [
    { folder: 'scaffold' }
    { folder: 'oss' }
    { folder: 'js-v1.8', jsversion: '1.8' }
  ].forEach ({ folder }) ->
    return if process.env.NOOSS? && folder == 'oss'

    wrench.readdirSyncRecursive('spec/scaffolding/' + folder).forEach (filename) ->

      return if fs.lstatSync('spec/scaffolding/' + folder + '/' + filename).isDirectory() || !filename.match(/\.js$/)

      it "should parse #{filename} the same way as jscoverage", ->
        code = fs.readFileSync('spec/scaffolding/' + folder + '/' + filename, 'utf8')
        newCode = jscov.rewriteSource(code, filename)
        actualParse = esprima.parse(newCode)

        expect = fs.readFileSync(output + '/' + 'expect/' + folder + '/' + filename, 'utf8')
        expectedParse = esprima.parse(expect)

        # comparing the first three lines of the generated source (to find type of line endings and other file-related stuff)
        code3 = newCode.split('\n').slice(0, 3).map (x) -> x.replace(/generated by jscov /, 'generated by JSCoverage ')
        exp3 = expect.split('\n').slice(0, 3)
        code3.should.eql exp3

        # if !_.isEqual(actualParse, expectedParse)
        #   console.log "WRITING!"
        #   escodegen = require 'escodegen'
        #   fs.writeFileSync('actual.js', escodegen.generate(actualParse, { indent: "  " }), 'utf8')
        #   fs.writeFileSync('expected.js', escodegen.generate(expectedParse, { indent: "  " }), 'utf8')

        # comparing the ASTs of the files
        _.isEqual(actualParse, expectedParse).should.be.true



  it "should throw an exception if the source is not valid", ->
    f = ->
      jscov.rewriteSource("console.log 'test'")
    f.should.throw()



describe "rewriteFolder", ->

  it "should rewrite entire folders recursively", (done) ->

    wrench.rmdirSyncRecursive(output + '/scaffold-out', true)

    jscov.rewriteFolder 'spec/scaffolding/scaffold', (output + '/scaffold-out'), (err) ->
      should.not.exist err
      fileCounter = 0

      wrench.readdirSyncRecursive(output + '/scaffold-out').forEach (filename) ->
        fullpath = output + '/scaffold-out/' + filename
        return if fs.lstatSync(fullpath).isDirectory()
        fileCounter++
        fs.readFileSync(fullpath, 'utf8').split('\n')[0].should.eql '/* automatically generated by jscov - do not edit */'

      fileCounter.should.eql 12
      done()


  it "should rewrite both javascript and coffee-script, but nothing else", (done) ->

    wrench.rmdirSyncRecursive(output + '/coffee-out', true)

    jscov.rewriteFolder 'spec/scaffolding/coffee', (output + '/coffee-out'), (err) ->
      should.not.exist err
      fs.readFileSync(output + '/coffee-out/coffeescript.js', 'utf8').split('\n')[0].should.eql '/* automatically generated by jscov - do not edit */'
      fs.readFileSync(output + '/coffee-out/javascript.js', 'utf8').split('\n')[0].should.eql '/* automatically generated by jscov - do not edit */'
      fs.readFileSync(output + '/coffee-out/text.txt', 'utf8').should.eql 'console.log("foobar")\n'
      done()


  it "should not create a directory if it encounters an error when processing coffee-script", (done) ->

    jscov.rewriteFolder 'spec/scaffolding/invalids/cs', output + '/invalids-out', (err) ->
      should.exist err
      fs.lstat (output + '/invalids-out'), (err) ->
        err.code.should.eql 'ENOENT'
        done()


  it "should not create a directory if it encounters an error when processing javascript", (done) ->

    jscov.rewriteFolder 'spec/scaffolding/invalids/js', (output + '/invalids-out'), (err) ->
      should.exist err
      fs.lstat (output + '/invalids-out'), (err) ->
        err.code.should.eql 'ENOENT'
        done()


  it "should report on invalid files, skip them, and process the remaining", (done) ->
    outdir = output + '/fail-out'
    wrench.mkdirSyncRecursive(outdir)
    jscov.rewriteFolder 'spec/scaffolding/fail', outdir, (err) ->
      fs.exists "#{outdir}/valid.js", (exists) ->
        exists.should.be.true
        err.should.be.a 'object'
        err.message.should.include 'fail.js: Line 2: Unexpected end of input'
        done()


  it "should overwrite the target directory and remove/replace all files in it", (done) ->

    wrench.mkdirSyncRecursive(output + '/existing/subdir')
    fs.writeFileSync(output + '/existing/foo.js', 'content', 'utf8')
    fs.writeFileSync(output + '/existing/for.js', 'content', 'utf8')
    fs.writeFileSync(output + '/existing/subdir/bar.js', 'content', 'utf8')

    jscov.rewriteFolder 'spec/scaffolding/scaffold', (output + '/existing'), (err) ->
      should.not.exist err
      fileCounter = 0

      wrench.readdirSyncRecursive(output + '/existing').forEach (filename) ->
        fullpath = output + '/existing/' + filename
        return if fs.lstatSync(fullpath).isDirectory()
        fileCounter++
        fs.readFileSync(fullpath, 'utf8').split('\n')[0].should.eql '/* automatically generated by jscov - do not edit */'

      fileCounter.should.eql 12
      done()


  it "should not include hidden files", (done) ->
    jscov.rewriteFolder 'spec/scaffolding/hidden', output + '/hidden-default', {}, (err) ->
      should.not.exist err
      wrench.readdirSyncRecursive(output + '/hidden-default').sort().should.eql ['subfolder', 'subfolder/vis.js', 'visible.js', 'visible.txt']
      done()


  it "should accept a flag for including hidden files", (done) ->
    jscov.rewriteFolder 'spec/scaffolding/hidden', output + '/hidden-included', { hidden: true }, (err) ->
      should.not.exist err
      wrench.readdirSyncRecursive(output + '/hidden-included').sort().should.eql ['.hidden.js', '.hidden.txt', '.hiddensub', '.hiddensub/.h.js', '.hiddensub/v.js', 'subfolder', 'subfolder/.hid.js', 'subfolder/vis.js', 'visible.js', 'visible.txt']
      done()


  it "should accept a flag for explicitly excluding hidden files", (done) ->
    jscov.rewriteFolder 'spec/scaffolding/hidden', output + '/hidden-included', { hidden: false }, (err) ->
      should.not.exist err
      wrench.readdirSyncRecursive(output + '/hidden-included').sort().should.eql ['subfolder', 'subfolder/vis.js', 'visible.js', 'visible.txt']
      done()
