if [ `which jscoverage` ];
then
  jscoverage $1 $2
else
  /home/travis/builds/jakobmattsson/jscov/node-jscoverage/jscoverage $1 $2
fi