# jscov [![Build Status](https://secure.travis-ci.org/jakobmattsson/jscov.png)](http://travis-ci.org/jakobmattsson/jscov)

JSCoverage, implemented in JavaScript



## Installing

`npm install -g jscov`



## Using

Start with `jscov --help` on the command line and the rest should be obvious.

You can also use it programmatically. It has two functions and can be used like this:

```javascript
var jscov = require('jscov');

// Transforming source code
//
// Pass in some javascript code as a string and get a new string back,
// containing the same program but with code coverage support added.
//
// A filename has to be passed in as well, since the code coverage bits requires one.

var coveredSource = jscov.rewriteSource("var a = 1 + 2; console.log(a);", "myfilename.js");

// Transforming directories of code (like the command line client)
//
// This is simply the programmatic version of the command line client.
// Pass in a source directory and a target directory and all JavaScript (and CoffeeScript)
// found in source diriectory will be processed using `rewriteSource` and written to the target directory.
jscov.rewriteFolder("src", "src-cov", function(err) {
  // err will indicate if something went wrong.
});
```


## Developing

Pull request are welcome obviously!

Running the tests requires jscoverage to be installed. This is because the main part of the tests compares the output of jscov to jscoverage. Get it here http://siliconforks.com/jscoverage or do what `.travis.yml` does to get it up and running.



## Todo

* Add some more test scaffolding, based on other peoples code in order to analyse coding styles other than my own.
* Support different encodings (compare with JSCoverage on that as well)
* Achieve 100% test-coverage
