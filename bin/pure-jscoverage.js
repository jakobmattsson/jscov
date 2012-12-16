#!/usr/bin/env node

var optimist = require('optimist');
var realjson = require('../lib/coverage');

var argv = optimist
  .usage("JSCoverage is a tool that measures code coverage for JavaScript programs.\n\nUsage: pure-jscoverage sourcedir targetdir")
  .describe('version', 'Print the current version number')
  .describe('help', 'Show this help message')
  .alias('version', 'v')
  .alias('help', 'h')
  .argv;

if (argv.help) {
  console.log(optimist.help());
  return;
}

if (argv.version) {
  console.log(require('../package.json').version);
  return;
}

console.log("go")
