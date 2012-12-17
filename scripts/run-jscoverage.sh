if [ `which jscoverage` ];
then
  jscoverage $1 $2
else
  ./node-jscoverage/jscoverage $1 $2
fi
