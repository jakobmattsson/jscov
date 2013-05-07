#!/usr/bin/env node

var optimist = require('optimist');
var jscov = require('../lib/jscov');

var argv = optimist
  .usage("jscov is a tool that measures code coverage for JavaScript programs.\n\njscov is modelled after JSCoverage (http://siliconforks.com/jscoverage),\nbut implemented in pure JavaScript and can be used as a direct replacement.\n\nUsage: jscov sourcedir targetdir")
  .boolean('expand')
  .boolean('conditionals')
  .boolean('hidden')
  .boolean('verbose')
  .describe('version', 'Print the current version number')
  .describe('help', 'Show this help message')
  .describe('expand', 'Expands lazy operators and if-statements to give higher resolution coverage data')
  .describe('hidden', 'Covers hidden files')
  .describe('verbose', 'Prints additional information during coverage')
  .describe('conditionals', 'Expands conditional JSCOV-comments to test additional execution paths')
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

if (argv._.length != 2) {
  optimist.showHelp();
  return;
}

jscov.rewriteFolder(argv._[0], argv._[1], {
  expand: argv.expand,
  hidden: argv.hidden,
  verbose: argv.verbose,
  conditionals: argv.conditionals
}, function(err) {
  if (err) {
    console.log(err);
    process.exit(1);
  }
});
