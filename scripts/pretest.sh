mkdir -p spec/.output/expect
sh scripts/run-jscoverage-1.8.sh spec/scaffolding/js-v1.8 spec/.output/expect/js-v1.8
sh scripts/run-jscoverage.sh spec/scaffolding/scaffold spec/.output/expect/scaffold
sh scripts/run-jscoverage.sh spec/scaffolding/oss spec/.output/expect/oss
